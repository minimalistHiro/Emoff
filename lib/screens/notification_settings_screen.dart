import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_app_bar.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static const _backgroundColor = Color(0xFF0D0D0D);
  static const _surfaceColor = Color(0xFF1A1A1A);
  static const _dividerColor = Color(0xFF242424);
  static const _cyan = Color(0xFF00D4FF);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFFA0A0A0);
  static const _textDisabled = Color(0xFF555555);
  static const _toggleOff = Color(0xFF555555);

  bool _masterEnabled = true;
  bool _messagesEnabled = true;
  bool _friendRequestsEnabled = true;
  bool _announcementsEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _masterEnabled = prefs.getBool('notification_enabled') ?? true;
        _messagesEnabled = prefs.getBool('notification_messages') ?? true;
        _friendRequestsEnabled =
            prefs.getBool('notification_friend_requests') ?? true;
        _announcementsEnabled =
            prefs.getBool('notification_announcements') ?? true;
        _isLoading = false;
      });
    }
  }

  Future<void> _setMasterEnabled(bool value) async {
    if (value) {
      // TODO: FCM実装後 — 端末の通知権限チェック
      // 未許可の場合はOS権限リクエストを表示し、
      // 拒否されたらトグルをOFFに戻してダイアログを表示する
      // 許可されたらFCMトークンを再登録する
      final granted = await _requestNotificationPermission();
      if (!granted) return;
    } else {
      // TODO: FCM実装後 — FCMトークンをサーバーから削除
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_enabled', value);
    if (mounted) {
      setState(() {
        _masterEnabled = value;
      });
    }
  }

  Future<bool> _requestNotificationPermission() async {
    // TODO: FCM実装後（R-10決定後）に実装
    // permission_handler パッケージで通知権限をリクエストし、
    // 拒否された場合はダイアログ表示 + false を返す
    // 現時点ではUI層のみのため常に true を返す
    return true;
  }

  Future<void> _setMessagesEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_messages', value);
    if (mounted) {
      setState(() {
        _messagesEnabled = value;
      });
    }
  }

  Future<void> _setFriendRequestsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_friend_requests', value);
    if (mounted) {
      setState(() {
        _friendRequestsEnabled = value;
      });
    }
  }

  Future<void> _setAnnouncementsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_announcements', value);
    if (mounted) {
      setState(() {
        _announcementsEnabled = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: const CustomAppBar(
        titleText: 'Notifications',
      ),
      body: _isLoading
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Master toggle
                  _buildMasterToggle(),
                  // Divider
                  Container(
                    height: 1,
                    color: _dividerColor,
                  ),
                  // Notification types section
                  _buildSectionLabel(),
                  _buildToggleItem(
                    label: 'Messages',
                    subtitle: '新しいメッセージを受信したとき',
                    value: _messagesEnabled,
                    enabled: _masterEnabled,
                    onChanged: _setMessagesEnabled,
                  ),
                  _buildDivider(),
                  _buildToggleItem(
                    label: 'Friend Requests',
                    subtitle: '友達申請を受け取ったとき',
                    value: _friendRequestsEnabled,
                    enabled: _masterEnabled,
                    onChanged: _setFriendRequestsEnabled,
                  ),
                  _buildDivider(),
                  _buildToggleItem(
                    label: 'Announcements',
                    subtitle: 'アプリからのお知らせ',
                    value: _announcementsEnabled,
                    enabled: _masterEnabled,
                    onChanged: _setAnnouncementsEnabled,
                  ),
                  // Note text
                  _buildNoteText(),
                ],
              ),
            ),
    );
  }

  Widget _buildMasterToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Push Notifications',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '全ての通知を一括で管理',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _masterEnabled,
            onChanged: _setMasterEnabled,
            activeColor: _cyan,
            activeTrackColor: _cyan.withOpacity(0.4),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: _toggleOff,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel() {
    return const Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24),
      child: Text(
        'NOTIFICATION TYPES',
        style: TextStyle(
          color: _textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required String label,
    required String subtitle,
    required bool value,
    required bool enabled,
    required Future<void> Function(bool) onChanged,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: enabled ? (v) => onChanged(v) : null,
              activeColor: _cyan,
              activeTrackColor: _cyan.withOpacity(0.4),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: _toggleOff,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 1,
        color: _surfaceColor,
      ),
    );
  }

  Widget _buildNoteText() {
    return const Padding(
      padding: EdgeInsets.only(left: 32, right: 32, top: 32),
      child: Text(
        '通知が届かない場合は、端末の設定からEmoffの通知を許可してください',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _textDisabled,
          fontSize: 12,
        ),
      ),
    );
  }
}
