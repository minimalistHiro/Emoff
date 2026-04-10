import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/revenue_cat_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dialog_helper.dart';
import 'main_shell.dart';
import 'password_reset_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // バリデーション
    if (email.isEmpty || password.isEmpty) {
      await showCustomDialog(
        context,
        title: 'エラー',
        message: 'メールアドレスとパスワードを入力してください。',
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
      await _authService.signIn(email: email, password: password);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await RevenueCatService.init(uid);
      }
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } catch (e) {
      if (!mounted) return;
      await showCustomDialog(
        context,
        title: 'ログインエラー',
        message: toUserFriendlyError(e),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToPasswordReset() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PasswordResetScreen()),
    );
  }

  void _navigateToSignUp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. ブランディング領域
                    const Center(
                      child: Text(
                        'EMOFF',
                        style: TextStyle(
                          color: Color(0xFF00D4FF),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // 2. ウェルカムヘッダー
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Access your workspace for clarity.',
                      style: TextStyle(
                        color: Color(0xFFA0A0A0),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 3. メールアドレス入力
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
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 24),

                    // 4. パスワード入力
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PASSWORD',
                          style: TextStyle(
                            color: Color(0xFFA0A0A0),
                            fontSize: 11,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: _navigateToPasswordReset,
                          child: const Text(
                            'FORGOT PASSWORD?',
                            style: TextStyle(
                              color: Color(0xFF00D4FF),
                              fontSize: 11,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _passwordController,
                      hintText: '••••••••',
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 16),

                    // 5. ログインボタン
                    CustomButton(
                      text: 'Login',
                      icon: Icons.arrow_forward,
                      height: 56,
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _login,
                    ),
                    const SizedBox(height: 48),

                    // 6. 区切り線 + 新規登録リンク
                    const Divider(
                      color: Color(0xFF242424),
                      thickness: 1,
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: GestureDetector(
                        onTap: _navigateToSignUp,
                        child: RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'New to the philosophy?  ',
                                style: TextStyle(
                                  color: Color(0xFFA0A0A0),
                                  fontSize: 14,
                                ),
                              ),
                              TextSpan(
                                text: 'Sign Up',
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
          ),
        ],
      ),
    );
  }
}
