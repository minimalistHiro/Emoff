import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/profile_settings_screen.dart';
import '../screens/announcements_screen.dart';
import '../screens/subscription_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({
    super.key,
    required this.onSwitchToSettings,
  });

  final VoidCallback onSwitchToSettings;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = (screenWidth * 0.75).clamp(0.0, 280.0);

    return Drawer(
      width: drawerWidth,
      backgroundColor: const Color(0xFF0D0D0D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: _DrawerContent(
        onSwitchToSettings: onSwitchToSettings,
      ),
    );
  }
}

class _DrawerContent extends StatefulWidget {
  const _DrawerContent({required this.onSwitchToSettings});

  final VoidCallback onSwitchToSettings;

  @override
  State<_DrawerContent> createState() => _DrawerContentState();
}

class _DrawerContentState extends State<_DrawerContent> {
  static const _cardColor = Color(0xFF1A1A1A);
  static const _elevateColor = Color(0xFF242424);
  static const _cyan = Color(0xFF00D4FF);
  static const _cyanLight = Color(0xFF7EEEFF);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFFA0A0A0);
  static const _textDisabled = Color(0xFF555555);

  int _unreadAnnouncementsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadAnnouncementsCount();
  }

  Future<void> _loadUnreadAnnouncementsCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastViewedMillis = prefs.getInt('announcements_last_viewed') ?? 0;
      final lastViewed =
          DateTime.fromMillisecondsSinceEpoch(lastViewedMillis);

      final query = await FirebaseFirestore.instance
          .collection('announcements')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(lastViewed))
          .get();

      if (mounted) {
        setState(() {
          _unreadAnnouncementsCount = query.docs.length;
        });
      }
    } catch (_) {
      // ignore errors for badge count
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final name = userData['name'] as String? ?? '';
        final userId = userData['userId'] as String? ?? '';
        final iconUrl = userData['iconUrl'] as String? ?? '';
        final plan = userData['plan'] as String? ?? 'free';

        return Column(
          children: [
            // 1. ヘッダー
            _buildHeader(context, name, userId, iconUrl, plan),
            // 区切り線
            Container(height: 1, color: _elevateColor),
            // 2. プランセクション（Freeのみ）
            if (plan == 'free') _buildUpgradeSection(context),
            // 3. ナビゲーションリスト
            Expanded(
              child: _buildNavList(context, plan),
            ),
            // 4. フッター
            _buildFooter(),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String name,
    String userId,
    String iconUrl,
    String plan,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop(); // ドロワーを閉じる
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ProfileSettingsScreen(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        color: _cardColor,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 24,
          bottom: 24,
          left: 24,
          right: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // アバター
            _buildAvatar(name, iconUrl),
            const SizedBox(height: 12),
            // ユーザー名 + プランバッジ
            Row(
              children: [
                Flexible(
                  child: Text(
                    name.isNotEmpty ? name : 'User',
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Manrope',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                _buildPlanBadge(plan),
              ],
            ),
            const SizedBox(height: 4),
            // @userId
            Text(
              '@$userId',
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, String iconUrl) {
    if (iconUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 32,
        backgroundImage: NetworkImage(iconUrl),
        backgroundColor: _elevateColor,
      );
    }
    return CircleAvatar(
      radius: 32,
      backgroundColor: _elevateColor,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: const TextStyle(
          color: _cyan,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPlanBadge(String plan) {
    String label;
    Color bgColor;
    Color textColor;

    switch (plan) {
      case 'pro':
        label = 'PRO';
        bgColor = _cyan;
        textColor = const Color(0xFF0D0D0D);
        break;
      case 'business':
        label = 'BIZ';
        bgColor = _cyanLight;
        textColor = const Color(0xFF0D0D0D);
        break;
      default:
        label = 'FREE';
        bgColor = _elevateColor;
        textColor = _textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUpgradeSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _elevateColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.rocket_launch, size: 24, color: _cyan),
                SizedBox(width: 8),
                Text(
                  'Upgrade to Pro',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Unlock unlimited messages & group chats',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop(); // ドロワーを閉じる
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionScreen(),
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _cyan,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'View Plans',
                  style: TextStyle(
                    color: Color(0xFF0D0D0D),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavList(BuildContext context, String plan) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 16),
      child: Column(
        children: [
          // Subscription
          _buildNavItem(
            icon: Icons.credit_card,
            label: 'Subscription',
            badge: plan != 'free' ? _planDisplayName(plan) : null,
            onTap: () {
              Navigator.of(context).pop(); // ドロワーを閉じる
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SubscriptionScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 2),
          // Announcements
          _buildNavItem(
            icon: Icons.campaign,
            label: 'Announcements',
            badgeCount: _unreadAnnouncementsCount,
            onTap: () {
              Navigator.of(context).pop(); // ドロワーを閉じる
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AnnouncementsScreen(),
                ),
              );
              // お知らせ閲覧後に未読カウントをリセット
              _markAnnouncementsAsRead();
            },
          ),
          const SizedBox(height: 2),
          // Settings
          _buildNavItem(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () {
              Navigator.of(context).pop(); // ドロワーを閉じる
              widget.onSwitchToSettings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    String? badge,
    int badgeCount = 0,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        splashColor: _elevateColor,
        highlightColor: _elevateColor,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 24, color: _textSecondary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // テキストバッジ（プラン名）
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _cyan,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Color(0xFF0D0D0D),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              // 数値バッジ（未読件数）
              if (badgeCount > 0)
                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _cyan,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Color(0xFF0D0D0D),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Container(height: 1, color: _elevateColor),
        Padding(
          padding: EdgeInsets.only(
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          child: const Text(
            'EMOFF v1.0.0',
            style: TextStyle(
              color: _textDisabled,
              fontSize: 10,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ],
    );
  }

  String _planDisplayName(String plan) {
    switch (plan) {
      case 'pro':
        return 'Pro';
      case 'business':
        return 'Business';
      default:
        return 'Free';
    }
  }

  Future<void> _markAnnouncementsAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'announcements_last_viewed',
        DateTime.now().millisecondsSinceEpoch,
      );
      if (mounted) {
        setState(() {
          _unreadAnnouncementsCount = 0;
        });
      }
    } catch (_) {}
  }
}
