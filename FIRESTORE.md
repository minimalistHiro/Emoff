# FIRESTORE.md

> 最終更新: 2026-04-03

## リージョン

- **asia-northeast1**（東京）

---

## コレクション構成

```
├── users/{uid}
│   ├── friends/{friendUid}              ← サブコレクション
│   └── blocked_users/{blockedUid}       ← サブコレクション
├── friend_requests/{requestId}
├── chats/{chatId}
│   └── messages/{messageId}             ← サブコレクション
├── reports/{reportId}
└── announcements/{announcementId}
```

---

## コレクション詳細

### 1. users（ユーザー）

ユーザーのプロフィール情報を管理する。ドキュメントIDはFirebase AuthのUID。

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `name` | string | ○ | 表示名 |
| `userId` | string | ○ | 友達検索用の一意ID（ユーザーが設定） |
| `email` | string | ○ | メールアドレス |
| `iconUrl` | string | - | プロフィールアイコンのURL |
| `backgroundUrl` | string | - | プロフィール背景画像のURL |
| `bio` | string | - | 自己紹介文（AI変換後のテキストを保存） |
| `createdAt` | timestamp | ○ | アカウント作成日時 |
| `updatedAt` | timestamp | ○ | 最終更新日時 |

**備考:**
- `userId` はアプリ内で一意であること（友達申請のID検索に使用）
- `bio` はチャットと同様にAI変換を通した文章のみ保存

---

### 1-1. users/{uid}/friends（友達リスト）

ユーザーの友達関係を管理するサブコレクション。ドキュメントIDは友達のUID。

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `name` | string | ○ | 友達の表示名（非正規化・表示用キャッシュ） |
| `iconUrl` | string | - | 友達のアイコンURL（非正規化・表示用キャッシュ） |
| `chatId` | string | - | この友達との1対1チャットID（存在する場合） |
| `createdAt` | timestamp | ○ | 友達になった日時 |

**備考:**
- 友達関係は双方向。承認時に両者のサブコレクションにドキュメントを作成する
- `name` / `iconUrl` は表示速度のためのキャッシュ。プロフィール更新時にCloud Functionsで同期する

---

### 1-2. users/{uid}/blocked_users（ブロックリスト）

ブロックしたユーザーを管理するサブコレクション。ドキュメントIDはブロック対象のUID。

| フィールド | 型 | 必��� | 説明 |
|-----------|-----|------|------|
| `createdAt` | timestamp | ○ | ブロックした日時 |

**備考:**
- ブロック時の動作: ブロック相手からのメッセージを非表示、友達リストから削除、新規チャット作成不可
- ブロック操作の導線: 友達プロフィール画面またはトークルーム画面のメニューから
- ブロック時にCloud Functionsで両者の `friends` サブ��レクションからドキュメントを削除する

---

### 2. friend_requests（友達申請）

友達申請の送受信を管理する。

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `fromUid` | string | ○ | 申請者のUID |
| `toUid` | string | ○ | 受信者のUID |
| `fromName` | string | ○ | 申請者の表示名（非正規化） |
| `fromIconUrl` | string | - | 申請者のアイコンURL（非正規化） |
| `status` | string | ○ | `pending` / `accepted` / `rejected` |
| `createdAt` | timestamp | ○ | 申請日時 |
| `updatedAt` | timestamp | ○ | 最終更新日時 |

**備考:**
- 受信した申請一覧: `where('toUid', '==', myUid).where('status', '==', 'pending')` で取得
- 承認時: `status` を `accepted` に更新し、両者の `friends` サブコレクションにドキュメントを作成

---

### 3. chats（チャットルーム）

1対1チャット・グループチャットのルーム情報を管理する。

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `type` | string | ○ | `direct`（1対1） / `group`（グループ） |
| `members` | array\<string\> | ○ | メンバーのUID配列（上限目安: 500人） |
| `groupName` | string | △ | グループ名（`type: group` の場合のみ） |
| `groupIconUrl` | string | - | グループアイコンURL（`type: group` の場合のみ） |
| `createdBy` | string | △ | グループ作成者のUID（`type: group` の場合のみ） |
| `lastMessage` | string | - | 最新メッセージのプレビュー（変換後テキスト） |
| `lastMessageAt` | timestamp | - | 最新メッセージの送信日時 |
| `lastReadAt` | map\<string, timestamp\> | - | 各メンバーの最終既読日時 `{ uid: timestamp }` |
| `createdAt` | timestamp | ○ | チャットルーム作成日時 |
| `updatedAt` | timestamp | ○ | 最終更新日時 |

**備考:**
- 自分が参加しているチャット一覧: `where('members', 'array-contains', myUid)` で取得
- トーク一覧の並び順: `orderBy('lastMessageAt', 'desc')`
- 未読判定: `lastMessageAt > lastReadAt[myUid]` でクライアント側で判定
- 1対1チャットは同じメンバー間で重複作成しないよう制御が必要

---

### 3-1. chats/{chatId}/messages（メッセージ）

チャットルーム内のメッセージを管理するサブコレクション。

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `senderId` | string | ○ | 送信者のUID |
| `senderName` | string | ○ | 送信者の表示名（非正規化） |
| `convertedText` | string | ○ | AI変換後のテキスト（受信者に表示される） |
| `originalText` | string | - | 変換前の原文（1ヶ月後に自動削除） |
| `readBy` | array\<string\> | - | 既読者のUID配列（将来の既読機能用。当面は未使用） |
| `createdAt` | timestamp | ○ | 送信日時 |

**備考:**
- メッセージの取得: `orderBy('createdAt', 'desc').limit(N)` でページネーション
- `originalText` は品質改善・デバッグ目的で1ヶ月間保存し、Cloud Functions（スケジュール実行）で自動削除
- `senderName` は非正規化データ。グループチャットで送信者名を表示するために使用
- `readBy` は将来の既読機能実装に備えてスキーマに含めるが、当面は書き込まない

---

### 4. announcements（お知らせ）

アプリからのアップデート情報・システム通知を管理する。

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `title` | string | ○ | お知らせタイトル |
| `body` | string | ○ | お知らせ本文 |
| `createdAt` | timestamp | ○ | 投稿日時 |

**備考:**
- 全ユーザー共通。管理者がFirebaseコンソールまたは管理ツールから投稿
- お知らせ画面: `orderBy('createdAt', 'desc')` で取得

---

### 6. reports（通報）

ユーザーからの通報を管理する。

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `reporterUid` | string | ○ | 通報者のUID |
| `targetUid` | string | ○ | 通報対象ユーザーのUID |
| `reason` | string | ○ | 通報理由（`spam` / `harassment` / `inappropriate_content` / `other`） |
| `detail` | string | - | 補足説明（`reason: other` の場合等） |
| `messageId` | string | - | 対象メッセージID（特定メッセージの通報時） |
| `chatId` | string | - | 対象チャットID（特定メッセージの通報時） |
| `createdAt` | timestamp | ○ | 通報日時 |

**備考:**
- 通報操作の導線: トークルーム画面のメニューまたはメッセージ長押しから
- 初期はFirebaseコンソールで管理者が確認・対応。管理画面は後日検討
- 通報者自身の通報のみ作成可能（セキュリティルールで制御）
- 通報内容は通報者以外に公開しない

---

## インデックス設計

Firestoreでは単一フィールドのクエリは自動インデックスが作成されるが、複合クエリには手動でのインデックス作成が必要。

| コレクション | フィールド | 用途 |
|-------------|-----------|------|
| `friend_requests` | `toUid` ASC, `status` ASC, `createdAt` DESC | 受信した未処理申請の一覧取得 |
| `chats` | `members` ARRAY_CONTAINS, `lastMessageAt` DESC | 自分のチャット一覧を新着順で取得 |
| `messages` | `createdAt` DESC | メッセージのページネーション（自動インデックスで対応可） |

---

## セキュリティルール

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // === ヘルパー関数 ===
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(uid) {
      return request.auth.uid == uid;
    }

    function isChatMember(chatData) {
      return request.auth.uid in chatData.members;
    }

    // === users ===
    match /users/{uid} {
      // 認証済みユーザーは他ユーザーのプロフィールを閲覧可能
      allow read: if isAuthenticated();
      // 自分のプロフィールのみ作成・更新可能
      allow create, update: if isOwner(uid);
      allow delete: if isOwner(uid);

      // === friends サブコレクション ===
      match /friends/{friendUid} {
        // 自分の友達リストのみ読み書き可能
        allow read, write: if isOwner(uid);
      }

      // === blocked_users サブコレクション ===
      match /blocked_users/{blockedUid} {
        // 自分のブロックリストのみ読み書き可能
        allow read, write: if isOwner(uid);
      }
    }

    // === friend_requests ===
    match /friend_requests/{requestId} {
      // 申請者または受信者のみ閲覧可能
      allow read: if isAuthenticated()
        && (resource.data.fromUid == request.auth.uid
            || resource.data.toUid == request.auth.uid);
      // 認証済みユーザーは申請を作成可能（fromUidが自分であること）
      allow create: if isAuthenticated()
        && request.resource.data.fromUid == request.auth.uid;
      // 受信者のみstatusを更新可能
      allow update: if isAuthenticated()
        && resource.data.toUid == request.auth.uid;
    }

    // === chats ===
    match /chats/{chatId} {
      // チャットメンバーのみ閲覧・更新可能
      allow read: if isAuthenticated() && isChatMember(resource.data);
      allow create: if isAuthenticated()
        && request.auth.uid in request.resource.data.members;
      allow update: if isAuthenticated() && isChatMember(resource.data);

      // === messages サブコレクション ===
      match /messages/{messageId} {
        // 親チャットのメンバーのみ閲覧・作成可能
        allow read: if isAuthenticated()
          && isChatMember(get(/databases/$(database)/documents/chats/$(chatId)).data);
        allow create: if isAuthenticated()
          && isChatMember(get(/databases/$(database)/documents/chats/$(chatId)).data)
          && request.resource.data.senderId == request.auth.uid;
      }
    }

    // === reports ===
    match /reports/{reportId} {
      // 自分の通報のみ閲覧可能
      allow read: if isAuthenticated()
        && resource.data.reporterUid == request.auth.uid;
      // 認証済みユーザーは通報を作成可能（reporterUidが自分であること）
      allow create: if isAuthenticated()
        && request.resource.data.reporterUid == request.auth.uid;
      // 更新・削除はAdmin SDKのみ
      allow update, delete: if false;
    }

    // === announcements ===
    match /announcements/{announcementId} {
      // 認証済みユーザーは閲覧可能。作成・更新はAdmin SDKのみ
      allow read: if isAuthenticated();
      allow write: if false;
    }
  }
}
```

---

## データ運用ルール

### 原文の自動削除
- `messages` の `originalText` フィールドは**1ヶ月後に自動削除**する
- Cloud Functions のスケジュール実行（毎日1回）で `createdAt` が1ヶ月以上前のメッセージの `originalText` を `null` に更新

### 非正規化データの同期
以下のフィールドはパフォーマンスのために非正規化している。ユーザーがプロフィールを更新した際にCloud Functionsで同期する。

| 同期元 | 同期先 | 対象フィールド |
|--------|--------|---------------|
| `users/{uid}` | `users/*/friends/{uid}` | `name`, `iconUrl` |
| `users/{uid}` | `friend_requests` (fromUid一致) | `fromName`, `fromIconUrl` |

### アカウント削除時の処理
- Cloud Functionsで以下を実行:
  1. `users/{uid}` ドキュメントを削除
  2. 全友達の `friends/{uid}` サブコレクションからドキュメントを削除
  3. 参加中のチャットの `members` 配列から自身のUIDを除去
  4. 関連する `friend_requests` を削除
