import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_dialog_helper.dart';
import 'account_settings_screen.dart';
import 'login_screen.dart';
import 'notification_settings_screen.dart';
import 'announcements_screen.dart';
import 'legal_document_screen.dart';
import 'profile_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _backgroundColor = Color(0xFF0D0D0D);
  static const _elevatedColor = Color(0xFF242424);
  static const _cyan = Color(0xFF00D4FF);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFFA0A0A0);
  static const _textDisabled = Color(0xFF555555);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: const CustomAppBar(
        showBackButton: false,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Settings',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Summary
            _buildProfileSummary(context, user),
            // CONFIGURATION Section
            _buildSectionLabel('CONFIGURATION'),
            const SizedBox(height: 4),
            _buildSettingsItem(
              context,
              title: 'Notifications',
              icon: Icons.chevron_right,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsScreen(),
                  ),
                );
              },
            ),
            _buildSettingsItem(
              context,
              title: 'Account Settings',
              icon: Icons.chevron_right,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AccountSettingsScreen(),
                  ),
                );
              },
            ),
            _buildSettingsItem(
              context,
              title: 'Announcements',
              icon: Icons.chevron_right,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AnnouncementsScreen(),
                  ),
                );
              },
            ),
            // LEGAL & PRIVACY Section
            const SizedBox(height: 32),
            _buildSectionLabel('LEGAL & PRIVACY'),
            const SizedBox(height: 4),
            _buildSettingsItem(
              context,
              title: 'Privacy Policy',
              icon: Icons.chevron_right,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LegalDocumentScreen(
                      title: 'Privacy Policy',
                      assetPath: 'assets/privacy_policy.md',
                    ),
                  ),
                );
              },
            ),
            _buildSettingsItem(
              context,
              title: 'Terms of Service',
              icon: Icons.chevron_right,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LegalDocumentScreen(
                      title: 'Terms of Service',
                      assetPath: 'assets/terms_of_service.md',
                    ),
                  ),
                );
              },
            ),
            // Footer (Logout + Version)
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummary(BuildContext context, User? user) {
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final name = data?['name'] as String? ?? '';
        final email = data?['email'] as String? ?? user.email ?? '';
        final iconUrl = data?['iconUrl'] as String?;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _elevatedColor,
                  border: Border.all(color: _elevatedColor, width: 3),
                ),
                child: iconUrl != null && iconUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          iconUrl,
                          fit: BoxFit.cover,
                          width: 96,
                          height: 96,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: _textSecondary,
                        size: 48,
                      ),
              ),
              const SizedBox(height: 24),
              // User name
              Text(
                name,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              // Email
              Text(
                email,
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 24),
              // Edit Profile button
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileSettingsScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _elevatedColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: _cyan,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        label,
        style: const TextStyle(
          color: _textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          splashColor: _elevatedColor,
          highlightColor: _elevatedColor,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, color: _textSecondary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          const SizedBox(height: 48),
          CustomButton(
            text: 'Logout of Session',
            variant: CustomButtonVariant.danger,
            height: 44,
            onPressed: () => _handleLogout(context),
          ),
          const SizedBox(height: 24),
          const Text(
            'VERSION 1.0.0 \u2022 EMOFF STOIC',
            style: TextStyle(
              color: _textDisabled,
              fontSize: 10,
              letterSpacing: 3.0,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showCustomConfirmDialog(
      context,
      title: 'ログアウト',
      message: 'ログアウトしますか？',
      confirmText: 'ログアウト',
      cancelText: 'キャンセル',
      confirmVariant: CustomButtonVariant.danger,
    );

    if (!confirmed) return;
    if (!context.mounted) return;

    try {
      await AuthService().signOut();
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
}
