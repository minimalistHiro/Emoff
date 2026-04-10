import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/custom_dialog_helper.dart';
import '../widgets/custom_loading_indicator.dart';
import '../widgets/custom_text_field.dart';
import 'login_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  static const _backgroundColor = Color(0xFF0D0D0D);
  static const _elevatedColor = Color(0xFF242424);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFFA0A0A0);
  static const _errorColor = Color(0xFFFF4D4D);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: const CustomAppBar(
        titleText: 'Account Settings',
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ACCOUNT Section
            _buildSectionLabel('ACCOUNT', _textSecondary),
            const SizedBox(height: 4),
            _buildSettingsItem(
              title: 'Email Address',
              subtitle: user?.email ?? '',
              trailing: const Icon(Icons.chevron_right, color: _textSecondary, size: 20),
              onTap: () => _showEmailChangeDialog(context),
            ),
            _buildDivider(),
            _buildSettingsItem(
              title: 'Password',
              subtitle: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
              trailing: const Icon(Icons.chevron_right, color: _textSecondary, size: 20),
              onTap: () => _showPasswordChangeDialog(context),
            ),
            // DANGER ZONE Section
            const SizedBox(height: 48),
            _buildSectionLabel('DANGER ZONE', _errorColor),
            const SizedBox(height: 4),
            _buildSettingsItem(
              title: 'Logout',
              trailing: const Icon(Icons.logout, color: _textSecondary, size: 20),
              onTap: () => _handleLogout(context),
            ),
            _buildDivider(),
            _buildSettingsItem(
              title: 'Delete Account',
              titleColor: _errorColor,
              trailing: const Icon(Icons.delete_forever, color: _errorColor, size: 20),
              onTap: () => _handleDeleteAccount(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required String title,
    String? subtitle,
    Color titleColor = _textPrimary,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          splashColor: _elevatedColor,
          highlightColor: _elevatedColor,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Divider(color: Color(0xFF1A1A1A), height: 1, thickness: 1),
    );
  }

  // ============================================================
  // メールアドレス変更ダイアログ
  // ============================================================

  Future<void> _showEmailChangeDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String? emailError;
    String? passwordError;
    bool isLoading = false;
    bool obscurePassword = true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return CustomDialog(
              title: 'メールアドレスの変更',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '現在: ${user.email ?? ""}',
                    style: const TextStyle(color: _textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: emailController,
                    hintText: '新しいメールアドレス',
                    keyboardType: TextInputType.emailAddress,
                    errorText: emailError,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: passwordController,
                    hintText: '現在のパスワード',
                    obscureText: obscurePassword,
                    errorText: passwordError,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: _textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 16),
                    const CustomLoadingIndicator(size: 24),
                  ],
                ],
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'キャンセル',
                        variant: CustomButtonVariant.secondary,
                        onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: '変更',
                        variant: CustomButtonVariant.primary,
                        onPressed: isLoading
                            ? null
                            : () async {
                                // バリデーション
                                final email = emailController.text.trim();
                                final password = passwordController.text;
                                String? newEmailError;
                                String? newPasswordError;

                                if (email.isEmpty ||
                                    !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
                                  newEmailError = '有効なメールアドレスを入力してください';
                                }
                                if (password.isEmpty) {
                                  newPasswordError = 'パスワードを入力してください';
                                }

                                if (newEmailError != null || newPasswordError != null) {
                                  setDialogState(() {
                                    emailError = newEmailError;
                                    passwordError = newPasswordError;
                                  });
                                  return;
                                }

                                setDialogState(() {
                                  emailError = null;
                                  passwordError = null;
                                  isLoading = true;
                                });

                                try {
                                  // 再認証
                                  final credential = EmailAuthProvider.credential(
                                    email: user.email!,
                                    password: password,
                                  );
                                  await user.reauthenticateWithCredential(credential);

                                  // メールアドレス更新
                                  await user.verifyBeforeUpdateEmail(email);

                                  // Firestore更新
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .update({
                                    'email': email,
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  });

                                  if (!context.mounted) return;
                                  Navigator.of(context).pop();

                                  if (!this.context.mounted) return;
                                  await showCustomDialog(
                                    this.context,
                                    title: '完了',
                                    message:
                                        '確認メールを送信しました。新しいメールアドレスを確認してください。',
                                  );
                                  setState(() {});
                                } catch (e) {
                                  setDialogState(() {
                                    isLoading = false;
                                  });
                                  if (!context.mounted) return;
                                  Navigator.of(context).pop();
                                  if (!this.context.mounted) return;
                                  await showCustomDialog(
                                    this.context,
                                    title: 'エラー',
                                    message: toUserFriendlyError(e),
                                  );
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
    passwordController.dispose();
  }

  // ============================================================
  // パスワード変更ダイアログ
  // ============================================================

  Future<void> _showPasswordChangeDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    String? currentPasswordError;
    String? newPasswordError;
    String? confirmPasswordError;
    bool isLoading = false;
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return CustomDialog(
              title: 'パスワードの変更',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: currentPasswordController,
                    hintText: '現在のパスワード',
                    obscureText: obscureCurrent,
                    errorText: currentPasswordError,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrent ? Icons.visibility_off : Icons.visibility,
                        color: _textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureCurrent = !obscureCurrent;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: newPasswordController,
                    hintText: '新しいパスワード',
                    obscureText: obscureNew,
                    errorText: newPasswordError,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility_off : Icons.visibility,
                        color: _textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureNew = !obscureNew;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: confirmPasswordController,
                    hintText: '新しいパスワード（確認）',
                    obscureText: obscureConfirm,
                    errorText: confirmPasswordError,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm ? Icons.visibility_off : Icons.visibility,
                        color: _textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureConfirm = !obscureConfirm;
                        });
                      },
                    ),
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 16),
                    const CustomLoadingIndicator(size: 24),
                  ],
                ],
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'キャンセル',
                        variant: CustomButtonVariant.secondary,
                        onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: '変更',
                        variant: CustomButtonVariant.primary,
                        onPressed: isLoading
                            ? null
                            : () async {
                                final currentPassword =
                                    currentPasswordController.text;
                                final newPassword = newPasswordController.text;
                                final confirmPassword =
                                    confirmPasswordController.text;
                                String? newCurrentError;
                                String? newNewError;
                                String? newConfirmError;

                                if (currentPassword.isEmpty) {
                                  newCurrentError = 'パスワードを入力してください';
                                }
                                if (newPassword.isEmpty) {
                                  newNewError = 'パスワードを入力してください';
                                } else if (newPassword.length < 6) {
                                  newNewError = '6文字以上で入力してください';
                                }
                                if (confirmPassword.isEmpty) {
                                  newConfirmError = 'パスワードを入力してください';
                                } else if (newPassword != confirmPassword) {
                                  newConfirmError = 'パスワードが一致しません';
                                }

                                if (newCurrentError != null ||
                                    newNewError != null ||
                                    newConfirmError != null) {
                                  setDialogState(() {
                                    currentPasswordError = newCurrentError;
                                    newPasswordError = newNewError;
                                    confirmPasswordError = newConfirmError;
                                  });
                                  return;
                                }

                                setDialogState(() {
                                  currentPasswordError = null;
                                  newPasswordError = null;
                                  confirmPasswordError = null;
                                  isLoading = true;
                                });

                                try {
                                  // 再認証
                                  final credential = EmailAuthProvider.credential(
                                    email: user.email!,
                                    password: currentPassword,
                                  );
                                  await user
                                      .reauthenticateWithCredential(credential);

                                  // パスワード更新
                                  await user.updatePassword(newPassword);

                                  if (!context.mounted) return;
                                  Navigator.of(context).pop();

                                  if (!this.context.mounted) return;
                                  await showCustomDialog(
                                    this.context,
                                    title: '完了',
                                    message: 'パスワードを変更しました。',
                                  );
                                } catch (e) {
                                  setDialogState(() {
                                    isLoading = false;
                                  });
                                  if (!context.mounted) return;
                                  Navigator.of(context).pop();
                                  if (!this.context.mounted) return;
                                  await showCustomDialog(
                                    this.context,
                                    title: 'エラー',
                                    message: toUserFriendlyError(e),
                                  );
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  // ============================================================
  // ログアウト
  // ============================================================

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return CustomDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout, color: _errorColor, size: 48),
              const SizedBox(height: 16),
              const Text(
                'ログアウト',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'ログアウトしますか？',
                style: TextStyle(color: _textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'キャンセル',
                    variant: CustomButtonVariant.secondary,
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'ログアウト',
                    variant: CustomButtonVariant.danger,
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      await showCustomDialog(
        context,
        title: 'エラー',
        message: toUserFriendlyError(e),
      );
    }
  }

  // ============================================================
  // アカウント削除フロー
  // ============================================================

  Future<void> _handleDeleteAccount(BuildContext context) async {
    // ステップ1: 警告ダイアログ
    final proceedToDelete = await _showDeleteWarningDialog(context);
    if (proceedToDelete != true) return;
    if (!context.mounted) return;

    // ステップ2: パスワード再入力ダイアログ
    await _showDeleteConfirmDialog(context);
  }

  Future<bool?> _showDeleteWarningDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return CustomDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber, color: _errorColor, size: 48),
              const SizedBox(height: 16),
              const Text(
                'アカウントを削除',
                style: TextStyle(
                  color: _errorColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BulletText('全てのメッセージ・トーク履歴が削除されます'),
                  SizedBox(height: 8),
                  _BulletText('友達リストが全て解除されます'),
                  SizedBox(height: 8),
                  _BulletText('参加中のグループから退出されます'),
                  SizedBox(height: 8),
                  _BulletText('この操作は取り消せません'),
                ],
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'キャンセル',
                    variant: CustomButtonVariant.secondary,
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: '削除に進む',
                    variant: CustomButtonVariant.danger,
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final passwordController = TextEditingController();
    String? passwordError;
    bool isLoading = false;
    bool obscurePassword = true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return CustomDialog(
              title: '本人確認',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'アカウント削除を続けるには、パスワードを入力してください。',
                    style: TextStyle(color: _textSecondary, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: passwordController,
                    hintText: 'パスワード',
                    obscureText: obscurePassword,
                    errorText: passwordError,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: _textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 16),
                    const CustomLoadingIndicator(size: 24),
                  ],
                ],
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'キャンセル',
                        variant: CustomButtonVariant.secondary,
                        onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'アカウントを削除',
                        variant: CustomButtonVariant.danger,
                        onPressed: isLoading
                            ? null
                            : () async {
                                final password = passwordController.text;

                                if (password.isEmpty) {
                                  setDialogState(() {
                                    passwordError = 'パスワードを入力してください';
                                  });
                                  return;
                                }

                                setDialogState(() {
                                  passwordError = null;
                                  isLoading = true;
                                });

                                try {
                                  // 再認証
                                  final credential = EmailAuthProvider.credential(
                                    email: user.email!,
                                    password: password,
                                  );
                                  await user.reauthenticateWithCredential(credential);

                                  // クライアント側で可能な削除処理
                                  // TODO: Cloud Functions で関連データクリーンアップを実装
                                  // - 全友達の friends/{myUid} サブコレクションからドキュメント削除
                                  // - 参加中チャットの members 配列から自身のUIDを除去
                                  // - 関連する friend_requests を削除
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .delete();

                                  // Firebase Auth ユーザー削除
                                  await user.delete();

                                  if (!context.mounted) return;
                                  Navigator.of(context).pop();

                                  if (!this.context.mounted) return;
                                  Navigator.of(this.context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                        builder: (_) => const LoginScreen()),
                                    (route) => false,
                                  );
                                } catch (e) {
                                  setDialogState(() {
                                    isLoading = false;
                                  });
                                  if (!context.mounted) return;
                                  Navigator.of(context).pop();
                                  if (!this.context.mounted) return;
                                  await showCustomDialog(
                                    this.context,
                                    title: 'エラー',
                                    message: toUserFriendlyError(e),
                                  );
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();
  }
}

/// 箇条書きテキスト（ブレットポイント）
class _BulletText extends StatelessWidget {
  const _BulletText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(Icons.circle, size: 6, color: Color(0xFFA0A0A0)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 14),
          ),
        ),
      ],
    );
  }
}
