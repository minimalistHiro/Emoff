import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/revenue_cat_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/custom_dialog_helper.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreedToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // バリデーション
    if (name.isEmpty) {
      await showCustomDialog(
        context,
        title: 'エラー',
        message: '名前を入力してください。',
      );
      return;
    }

    if (name.length > 20) {
      await showCustomDialog(
        context,
        title: 'エラー',
        message: '名前は20文字以内で入力してください。',
      );
      return;
    }

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

    if (password.isEmpty) {
      await showCustomDialog(
        context,
        title: 'エラー',
        message: 'パスワードを入力してください。',
      );
      return;
    }

    if (password.length < 8) {
      await showCustomDialog(
        context,
        title: 'エラー',
        message: 'パスワードは8文字以上で入力してください。',
      );
      return;
    }

    if (password != confirmPassword) {
      await showCustomDialog(
        context,
        title: 'エラー',
        message: 'パスワードが一致しません。',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signUp(
        email: email,
        password: password,
        name: name,
      );
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await RevenueCatService.init(uid);
      }
      if (!mounted) return;

      // AI処理同意ポップアップを表示
      await _showAiConsentDialog();
    } catch (e) {
      if (!mounted) return;
      await showCustomDialog(
        context,
        title: '登録エラー',
        message: toUserFriendlyError(e),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAiConsentDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _AiConsentDialog(
        onAgree: () {
          Navigator.of(dialogContext).pop();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        },
        onDisagree: () async {
          Navigator.of(dialogContext).pop();
          // アカウントを削除して新規登録画面に留まる
          try {
            await _authService.currentUser?.delete();
          } catch (_) {
            // 削除失敗しても画面は留まる
          }
        },
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _navigateToTerms() {
    // TODO: 利用規約画面が実装されたら置き換え
  }

  void _navigateToPrivacy() {
    // TODO: プライバシーポリシー画面が実装されたら置き換え
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

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
                    'Create Account',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Join the philosophy of clarity.',
                    style: TextStyle(
                      color: Color(0xFFA0A0A0),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 3. 名前入力
                  const Text(
                    'NAME',
                    style: TextStyle(
                      color: Color(0xFFA0A0A0),
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _nameController,
                    hintText: 'Your name',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),

                  // 4. メールアドレス入力
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
                  const SizedBox(height: 20),

                  // 5. パスワード入力
                  const Text(
                    'PASSWORD',
                    style: TextStyle(
                      color: Color(0xFFA0A0A0),
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _passwordController,
                    hintText: '••••••••',
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),

                  // 6. パスワード確認入力
                  const Text(
                    'CONFIRM PASSWORD',
                    style: TextStyle(
                      color: Color(0xFFA0A0A0),
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    hintText: '••••••••',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (_agreedToTerms) _signUp();
                    },
                  ),
                  const SizedBox(height: 24),

                  // 7. 利用規約・プライバシーポリシー同意
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _agreedToTerms,
                          onChanged: (value) {
                            setState(() => _agreedToTerms = value ?? false);
                          },
                          activeColor: const Color(0xFF00D4FF),
                          checkColor: const Color(0xFF0D0D0D),
                          side: const BorderSide(
                            color: Color(0xFFA0A0A0),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          children: [
                            GestureDetector(
                              onTap: _navigateToTerms,
                              child: const Text(
                                '利用規約',
                                style: TextStyle(
                                  color: Color(0xFF00D4FF),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const Text(
                              ' と ',
                              style: TextStyle(
                                color: Color(0xFFA0A0A0),
                                fontSize: 13,
                              ),
                            ),
                            GestureDetector(
                              onTap: _navigateToPrivacy,
                              child: const Text(
                                'プライバシーポリシー',
                                style: TextStyle(
                                  color: Color(0xFF00D4FF),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const Text(
                              ' に同意します',
                              style: TextStyle(
                                color: Color(0xFFA0A0A0),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 8. 登録ボタン
                  Opacity(
                    opacity: _agreedToTerms ? 1.0 : 0.4,
                    child: CustomButton(
                      text: 'Sign Up',
                      icon: Icons.arrow_forward,
                      height: 56,
                      isLoading: _isLoading,
                      onPressed: (_agreedToTerms && !_isLoading) ? _signUp : null,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 9. 区切り線 + ログインリンク
                  const Divider(
                    color: Color(0xFF242424),
                    thickness: 1,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: GestureDetector(
                      onTap: _navigateToLogin,
                      child: RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Already a member?  ',
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

/// AI処理同意ポップアップ
class _AiConsentDialog extends StatelessWidget {
  const _AiConsentDialog({
    required this.onAgree,
    required this.onDisagree,
  });

  final VoidCallback onAgree;
  final Future<void> Function() onDisagree;

  static const _consentItems = [
    'あなたが入力したテキストは、AI変換のため外部サービス（Anthropic）に送信されます',
    '変換前のテキストはサーバーに1ヶ月間保存された後、自動的に削除されます',
    'Anthropic側では入出力データが最大7日間保持され、その後削除されます。モデルのトレーニングには使用されません',
    'あなたはいつでもデータの削除を請求できます',
  ];

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: 'AI処理について',
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_consentItems.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < _consentItems.length - 1 ? 16 : 0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 番号アイコン
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00D4FF),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Color(0xFF0D0D0D),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // テキスト
                    Expanded(
                      child: Text(
                        _consentItems[index],
                        style: const TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
      actions: [
        CustomButton(
          text: '同意して始める',
          onPressed: onAgree,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: '同意しない',
          variant: CustomButtonVariant.secondary,
          onPressed: onDisagree,
        ),
      ],
    );
  }
}
