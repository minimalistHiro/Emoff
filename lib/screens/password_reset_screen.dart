import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dialog_helper.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();

    // バリデーション
    if (email.isEmpty) {
      await showCustomDialog(
        context,
        title: 'エラー',
        message: 'メールアドレスを入力してください。',
      );
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      await showCustomDialog(
        context,
        title: 'エラー',
        message: 'メールアドレスの形式が正しくありません。',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.sendPasswordResetEmail(email: email);
      if (!mounted) return;

      // 送信完了ダイアログ
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => CustomDialog(
          title: 'メール送信完了',
          content: const Text(
            'パスワードリセット用のリンクを送信しました。メールをご確認ください。',
            style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          actions: [
            CustomButton(
              text: 'ログイン画面に戻る',
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
                Navigator.of(context).pop(); // ログイン画面に戻る
              },
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await showCustomDialog(
        context,
        title: 'エラー',
        message: toUserFriendlyError(e),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: const CustomAppBar(),
      body: Stack(
        children: [
          // アンビエントグロー（右上）
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D4FF).withOpacity(0.05),
                    blurRadius: 120,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          // アンビエントグロー（左下）
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B2FBE).withOpacity(0.05),
                    blurRadius: 120,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          // メインコンテンツ
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. ヘッダー
                  const SizedBox(height: 24),
                  const Text(
                    'Reset Password',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Enter your email address and we'll send you a link to reset your password.",
                    style: TextStyle(
                      color: Color(0xFFA0A0A0),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 2. メールアドレス入力
                  const Text(
                    'EMAIL ADDRESS',
                    style: TextStyle(
                      color: Color(0xFFA0A0A0),
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'name@domain.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _sendResetLink(),
                  ),
                  const SizedBox(height: 32),

                  // 3. 送信ボタン
                  CustomButton(
                    text: 'Send Reset Link',
                    icon: Icons.arrow_forward,
                    height: 56,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _sendResetLink,
                  ),
                  const SizedBox(height: 32),

                  // 4. ログインへ戻るリンク
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Back to ',
                              style: TextStyle(
                                color: Color(0xFFA0A0A0),
                                fontSize: 14,
                              ),
                            ),
                            TextSpan(
                              text: 'Login',
                              style: TextStyle(
                                color: Color(0xFF00D4FF),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
