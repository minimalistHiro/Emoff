import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'custom_dialog.dart';
import 'custom_button.dart';

/// 情報・エラー通知用ダイアログ（SnackBar の代替）
Future<void> showCustomDialog(
  BuildContext context, {
  String? title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => CustomDialog(
      title: title,
      content: Text(
        message,
        style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 14),
        textAlign: TextAlign.center,
      ),
      actions: [
        CustomButton(
          text: '閉じる',
          variant: CustomButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}

/// 確認ダイアログ。`true` で確認、`false` でキャンセル
Future<bool> showCustomConfirmDialog(
  BuildContext context, {
  String? title,
  required String message,
  String confirmText = '確認',
  String cancelText = 'キャンセル',
  CustomButtonVariant confirmVariant = CustomButtonVariant.primary,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => CustomDialog(
      title: title,
      content: Text(
        message,
        style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 14),
        textAlign: TextAlign.center,
      ),
      actions: [
        CustomButton(
          text: confirmText,
          variant: confirmVariant,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: 8),
        CustomButton(
          text: cancelText,
          variant: CustomButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Firebase エラーをユーザーフレンドリーな日本語に変換
String toUserFriendlyError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'このメールアドレスは既に登録されています。';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません。';
      case 'user-not-found':
        return 'このメールアドレスのアカウントが見つかりません。';
      case 'wrong-password':
        return 'パスワードが正しくありません。';
      case 'weak-password':
        return 'パスワードが短すぎます。6文字以上で入力してください。';
      case 'too-many-requests':
        return 'ログイン試行回数が多すぎます。しばらく時間をおいてから再度お試しください。';
      case 'network-request-failed':
        return 'ネットワーク接続を確認してください。';
      case 'user-disabled':
        return 'このアカウントは無効化されています。';
      case 'invalid-credential':
        return 'メールアドレスまたはパスワードが正しくありません。';
      default:
        return 'エラーが発生しました。しばらく時間をおいてから再度お試しください。';
    }
  }
  return 'エラーが発生しました。しばらく時間をおいてから再度お試しください。';
}
