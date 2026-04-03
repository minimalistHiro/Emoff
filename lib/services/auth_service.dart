import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 現在のユーザー
  User? get currentUser => _auth.currentUser;

  /// 認証状態の変化を監視するストリーム
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// メール・パスワードで新規登録
  ///
  /// 登録成功時に Firestore の users コレクションにドキュメントを作成する。
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      final now = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'userId': '',
        'email': email,
        'iconUrl': null,
        'backgroundUrl': null,
        'bio': null,
        'createdAt': now,
        'updatedAt': now,
      });
    }

    return user;
  }

  /// メール・パスワードでログイン
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  /// ログアウト
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// パスワードリセットメール送信
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// userId の重複チェック
  ///
  /// 新規登録時に userId が既に使われていないか確認する。
  Future<bool> isUserIdAvailable(String userId) async {
    final query = await _firestore
        .collection('users')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }
}
