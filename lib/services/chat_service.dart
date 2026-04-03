import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  /// メッセージのストリームを取得（リアルタイム監視）
  Stream<QuerySnapshot> getMessages(String chatId, {int limit = 50}) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// チャット情報のストリームを取得
  Stream<DocumentSnapshot> getChatStream(String chatId) {
    return _firestore.collection('chats').doc(chatId).snapshots();
  }

  /// メッセージを送信
  ///
  /// [convertedText] は変換後テキスト（受信者に表示される）。
  /// [originalText] は変換前の原文（1ヶ月後に自動削除）。
  /// MVP時点では convertedText = originalText（AI変換未実装）。
  Future<void> sendMessage({
    required String chatId,
    required String convertedText,
    String? originalText,
    String tone = 'neutral',
  }) async {
    final uid = currentUid;
    if (uid == null) return;

    // 送信者の名前を取得
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final senderName = userDoc.data()?['name'] as String? ?? '';

    final batch = _firestore.batch();

    // メッセージドキュメントを作成
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    batch.set(messageRef, {
      'senderId': uid,
      'senderName': senderName,
      'convertedText': convertedText,
      'originalText': originalText,
      'tone': tone,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // チャットの lastMessage / lastMessageAt を更新
    final chatRef = _firestore.collection('chats').doc(chatId);
    batch.update(chatRef, {
      'lastMessage': convertedText,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// 既読を更新
  Future<void> updateLastRead(String chatId) async {
    final uid = currentUid;
    if (uid == null) return;

    await _firestore.collection('chats').doc(chatId).update({
      'lastReadAt.$uid': FieldValue.serverTimestamp(),
    });
  }

  /// 通報を送信
  Future<void> submitReport({
    required String targetUid,
    required String reason,
    String? detail,
    String? messageId,
    String? chatId,
  }) async {
    final uid = currentUid;
    if (uid == null) return;

    await _firestore.collection('reports').add({
      'reporterUid': uid,
      'targetUid': targetUid,
      'reason': reason,
      'detail': detail,
      'messageId': messageId,
      'chatId': chatId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// ユーザーをブロック
  Future<void> blockUser(String targetUid) async {
    final uid = currentUid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('blocked_users')
        .doc(targetUid)
        .set({
      'blockedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 相手ユーザーの情報を取得（1対1チャット用）
  Future<Map<String, dynamic>?> getOtherUser(String chatId) async {
    final uid = currentUid;
    if (uid == null) return null;

    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final members = List<String>.from(chatDoc.data()?['members'] ?? []);
    final otherUid = members.firstWhere(
      (id) => id != uid,
      orElse: () => '',
    );

    if (otherUid.isEmpty) return null;

    final userDoc = await _firestore.collection('users').doc(otherUid).get();
    final data = userDoc.data();
    if (data != null) {
      data['uid'] = otherUid;
    }
    return data;
  }
}
