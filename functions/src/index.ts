import * as functions from "firebase-functions";
import { onSchedule } from "firebase-functions/v2/scheduler";
import {
  onDocumentUpdated,
  onDocumentCreated,
} from "firebase-functions/v2/firestore";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

initializeApp();

const BATCH_SIZE = 500;

/**
 * ユーザープロフィール更新時に非正規化データを同期する。
 *
 * FIRESTORE.md仕様:
 * - users/{uid}.name / iconUrl が変更された場合:
 *   1. 全友達の friends/{uid} サブコレクションの name, iconUrl を更新
 *   2. pending状態の friend_requests (fromUid一致) の fromName, fromIconUrl を更新
 */
export const syncUserProfile = onDocumentUpdated(
  {
    document: "users/{uid}",
    region: "asia-northeast1",
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const uid = event.params.uid;
    const nameChanged = before.name !== after.name;
    const iconChanged = (before.iconUrl ?? null) !== (after.iconUrl ?? null);

    if (!nameChanged && !iconChanged) return;

    const db = getFirestore();

    // 1. 自分の友達一覧を取得し、各友達のfriends/{uid}を更新
    const friendsSnapshot = await db
      .collection(`users/${uid}/friends`)
      .get();

    // 2. pending状態のfriend_requests (fromUid一致) を取得
    const requestsSnapshot = await db
      .collection("friend_requests")
      .where("fromUid", "==", uid)
      .where("status", "==", "pending")
      .get();

    // バッチ更新（500件ずつコミット）
    let batch = db.batch();
    let batchCount = 0;

    const friendUpdate: Record<string, unknown> = {};
    if (nameChanged) friendUpdate.name = after.name;
    if (iconChanged) friendUpdate.iconUrl = after.iconUrl ?? null;

    for (const friendDoc of friendsSnapshot.docs) {
      batch.update(
        db.doc(`users/${friendDoc.id}/friends/${uid}`),
        friendUpdate
      );
      batchCount++;
      if (batchCount >= BATCH_SIZE) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
      }
    }

    const requestUpdate: Record<string, unknown> = {};
    if (nameChanged) requestUpdate.fromName = after.name;
    if (iconChanged) requestUpdate.fromIconUrl = after.iconUrl ?? null;

    for (const requestDoc of requestsSnapshot.docs) {
      batch.update(requestDoc.ref, requestUpdate);
      batchCount++;
      if (batchCount >= BATCH_SIZE) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    console.log(
      `syncUserProfile(${uid}): ` +
        `${friendsSnapshot.size} friends, ` +
        `${requestsSnapshot.size} requests updated ` +
        `(name: ${nameChanged}, icon: ${iconChanged})`
    );
  }
);

/**
 * ブロック時に両者のfriendsサブコレクションからドキュメントを削除する。
 *
 * FIRESTORE.md仕様:
 * - トリガー: users/{uid}/blocked_users/{blockedUid} ドキュメント作成時
 * - 処理: users/{uid}/friends/{blockedUid} と users/{blockedUid}/friends/{uid} を削除
 */
export const onBlockUser = onDocumentCreated(
  {
    document: "users/{uid}/blocked_users/{blockedUid}",
    region: "asia-northeast1",
  },
  async (event) => {
    const uid = event.params.uid;
    const blockedUid = event.params.blockedUid;
    const db = getFirestore();

    const batch = db.batch();
    batch.delete(db.doc(`users/${uid}/friends/${blockedUid}`));
    batch.delete(db.doc(`users/${blockedUid}/friends/${uid}`));
    await batch.commit();

    console.log(`onBlockUser: ${uid} blocked ${blockedUid}, friends removed`);
  }
);

/**
 * Firebase Authユーザー削除時にFirestore上の関連データをクリーンアップする。
 *
 * FIRESTORE.md仕様:
 * 1. users/{uid} ドキュメントとサブコレクション(friends, blocked_users)を削除
 * 2. 全友達の friends/{uid} サブコレクションからドキュメントを削除
 * 3. 参加中のチャットの members 配列から自身のUIDを除去
 * 4. 関連する friend_requests を削除
 */
export const cleanupDeletedUser = functions
  .region("asia-northeast1")
  .auth.user()
  .onDelete(async (user) => {
    const uid = user.uid;
    const db = getFirestore();

    // 事前に必要なデータを並行取得
    const [
      friendsSnapshot,
      blockedSnapshot,
      chatsSnapshot,
      sentRequestsSnapshot,
      receivedRequestsSnapshot,
    ] = await Promise.all([
      db.collection(`users/${uid}/friends`).get(),
      db.collection(`users/${uid}/blocked_users`).get(),
      db.collection("chats").where("members", "array-contains", uid).get(),
      db.collection("friend_requests").where("fromUid", "==", uid).get(),
      db.collection("friend_requests").where("toUid", "==", uid).get(),
    ]);

    let batch = db.batch();
    let batchCount = 0;

    const commitIfFull = async () => {
      if (batchCount >= BATCH_SIZE) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
      }
    };

    // 1. 各友達のfriends/{uid}を削除 + 自分のfriendsサブコレクションを削除
    for (const friendDoc of friendsSnapshot.docs) {
      batch.delete(db.doc(`users/${friendDoc.id}/friends/${uid}`));
      batchCount++;
      await commitIfFull();

      batch.delete(friendDoc.ref);
      batchCount++;
      await commitIfFull();
    }

    // 2. blocked_usersサブコレクションを削除
    for (const doc of blockedSnapshot.docs) {
      batch.delete(doc.ref);
      batchCount++;
      await commitIfFull();
    }

    // 3. 参加中チャットのmembers配列から自身を除去
    for (const chatDoc of chatsSnapshot.docs) {
      batch.update(chatDoc.ref, {
        members: FieldValue.arrayRemove(uid),
      });
      batchCount++;
      await commitIfFull();
    }

    // 4. 関連するfriend_requestsを削除（送信・受信両方）
    for (const doc of sentRequestsSnapshot.docs) {
      batch.delete(doc.ref);
      batchCount++;
      await commitIfFull();
    }
    for (const doc of receivedRequestsSnapshot.docs) {
      batch.delete(doc.ref);
      batchCount++;
      await commitIfFull();
    }

    // 5. usersドキュメント本体を削除
    batch.delete(db.doc(`users/${uid}`));
    batchCount++;

    if (batchCount > 0) {
      await batch.commit();
    }

    console.log(
      `cleanupDeletedUser(${uid}): ` +
        `${friendsSnapshot.size} friends, ` +
        `${blockedSnapshot.size} blocked, ` +
        `${chatsSnapshot.size} chats, ` +
        `${sentRequestsSnapshot.size + receivedRequestsSnapshot.size} requests deleted`
    );
  });

/**
 * 毎日午前3時(JST)に実行し、createdAtが1ヶ月以上前のメッセージの
 * originalTextをnullに更新する。
 *
 * FIRESTORE.md仕様:
 * - 対象: chats/{chatId}/messages/{messageId} の originalText フィールド
 * - 条件: createdAt が1ヶ月以上前 かつ originalText が null でない
 * - 処理: originalText を null に更新
 */
export const deleteExpiredOriginalTexts = onSchedule(
  {
    schedule: "0 3 * * *",
    timeZone: "Asia/Tokyo",
    region: "asia-northeast1",
  },
  async () => {
    const db = getFirestore();
    const oneMonthAgo = new Date();
    oneMonthAgo.setMonth(oneMonthAgo.getMonth() - 1);

    let totalUpdated = 0;
    let lastDoc: FirebaseFirestore.DocumentSnapshot | undefined;

    while (true) {
      let query = db
        .collectionGroup("messages")
        .where("originalText", "!=", null)
        .where("createdAt", "<", oneMonthAgo)
        .limit(BATCH_SIZE);

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snapshot = await query.get();
      if (snapshot.empty) break;

      const batch = db.batch();
      for (const doc of snapshot.docs) {
        batch.update(doc.ref, { originalText: null });
      }
      await batch.commit();
      totalUpdated += snapshot.size;

      if (snapshot.size < BATCH_SIZE) break;
      lastDoc = snapshot.docs[snapshot.docs.length - 1];
    }

    console.log(
      `deleteExpiredOriginalTexts: ${totalUpdated} messages updated`
    );
  }
);
