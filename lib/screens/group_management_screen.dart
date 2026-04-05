import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/custom_dialog_helper.dart';
import '../widgets/custom_loading_indicator.dart';
import '../widgets/custom_text_field.dart';
import 'friend_profile_screen.dart';

class GroupManagementScreen extends StatefulWidget {
  const GroupManagementScreen({
    super.key,
    required this.chatId,
  });

  final String chatId;

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  static const _backgroundColor = Color(0xFF0D0D0D);
  static const _cardColor = Color(0xFF1A1A1A);
  static const _elevateColor = Color(0xFF242424);
  static const _cyan = Color(0xFF00D4FF);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFFA0A0A0);
  static const _textDisabled = Color(0xFF555555);
  static const _danger = Color(0xFFFF4D4D);

  // グループ名インライン編集
  bool _isEditingName = false;
  final _nameEditController = TextEditingController();

  // メンバー情報キャッシュ: uid -> {name, userId, iconUrl}
  final Map<String, Map<String, dynamic>> _memberCache = {};

  // 友達UIDセット（メンバータップで友達プロフィール遷移可能かの判定用）
  final Set<String> _friendUids = {};

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _nameEditController.dispose();
    super.dispose();
  }

  String get _myUid => _auth.currentUser?.uid ?? '';

  Future<void> _loadFriends() async {
    final uid = _myUid;
    if (uid.isEmpty) return;
    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('friends')
          .get();
      if (!mounted) return;
      setState(() {
        _friendUids.clear();
        for (final doc in snap.docs) {
          _friendUids.add(doc.id);
        }
      });
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _getMemberInfo(String uid) async {
    if (_memberCache.containsKey(uid)) return _memberCache[uid]!;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      _memberCache[uid] = data;
      return data;
    } catch (_) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: const CustomAppBar(
        title: Text(
          'Group Settings',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            _firestore.collection('chats').doc(widget.chatId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'エラーが発生しました',
                style: TextStyle(color: _textSecondary, fontSize: 14),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CustomLoadingIndicator());
          }

          final chatData = snapshot.data!.data() as Map<String, dynamic>?;
          if (chatData == null) {
            return const Center(
              child: Text(
                'グループが見つかりません',
                style: TextStyle(color: _textSecondary, fontSize: 14),
              ),
            );
          }

          final members = List<String>.from(chatData['members'] ?? []);
          final groupName = chatData['groupName'] as String? ?? '';
          final groupIconUrl = chatData['groupIconUrl'] as String?;
          final createdBy = chatData['createdBy'] as String? ?? '';
          final isOwner = createdBy == _myUid;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // グループ情報セクション
                _buildGroupInfoSection(
                  groupName: groupName,
                  groupIconUrl: groupIconUrl,
                  memberCount: members.length,
                  isOwner: isOwner,
                ),
                Container(height: 1, color: _elevateColor),
                // メンバーセクション
                _buildMembersSection(
                  members: members,
                  createdBy: createdBy,
                  isOwner: isOwner,
                ),
                // アクションセクション
                _buildActionSection(
                  isOwner: isOwner,
                  groupName: groupName,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // === グループ情報セクション ===
  Widget _buildGroupInfoSection({
    required String groupName,
    required String? groupIconUrl,
    required int memberCount,
    required bool isOwner,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 24),
      child: Column(
        children: [
          // グループアイコン
          GestureDetector(
            onTap: isOwner ? _onChangeGroupIcon : null,
            child: SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                children: [
                  // アイコン本体
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _elevateColor,
                      image: (groupIconUrl != null && groupIconUrl.isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(groupIconUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: (groupIconUrl == null || groupIconUrl.isEmpty)
                        ? const Icon(Icons.groups, size: 40, color: _textSecondary)
                        : null,
                  ),
                  // カメラオーバーレイ（作成者のみ）
                  if (isOwner)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _cyan,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // グループ名（表示モード or 編集モード）
          _isEditingName
              ? _buildNameEditMode()
              : _buildNameDisplayMode(groupName, isOwner),
          const SizedBox(height: 4),
          // メンバー数
          Text(
            '$memberCount members',
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // === グループ名 表示モード ===
  Widget _buildNameDisplayMode(String groupName, bool isOwner) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            groupName,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (isOwner) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _nameEditController.text = groupName;
                _isEditingName = true;
              });
            },
            child: const Icon(Icons.edit, size: 16, color: _cyan),
          ),
        ],
      ],
    );
  }

  // === グループ名 編集モード ===
  Widget _buildNameEditMode() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(
            children: [
              // キャンセル
              GestureDetector(
                onTap: () => setState(() => _isEditingName = false),
                child: const Icon(Icons.close, size: 20, color: _textSecondary),
              ),
              const SizedBox(width: 8),
              // テキスト入力
              Expanded(
                child: CustomTextField(
                  controller: _nameEditController,
                  hintText: 'グループ名を入力',
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _onConfirmNameEdit(),
                ),
              ),
              const SizedBox(width: 8),
              // 確定
              GestureDetector(
                onTap: _nameEditController.text.trim().isNotEmpty
                    ? _onConfirmNameEdit
                    : null,
                child: Icon(
                  Icons.check,
                  size: 20,
                  color: _nameEditController.text.trim().isNotEmpty
                      ? _cyan
                      : _textDisabled,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_nameEditController.text.length}/50',
              style: TextStyle(
                color: _nameEditController.text.length > 50
                    ? _danger
                    : _textDisabled,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === メンバーセクション ===
  Widget _buildMembersSection({
    required List<String> members,
    required String createdBy,
    required bool isOwner,
  }) {
    // ソート: OWNER→YOU→名前昇順
    final sorted = List<String>.from(members);
    sorted.sort((a, b) {
      if (a == createdBy) return -1;
      if (b == createdBy) return 1;
      if (a == _myUid) return -1;
      if (b == _myUid) return 1;
      final nameA = (_memberCache[a]?['name'] as String? ?? '').toLowerCase();
      final nameB = (_memberCache[b]?['name'] as String? ?? '').toLowerCase();
      return nameA.compareTo(nameB);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // セクションヘッダー
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            children: [
              const Text(
                'MEMBERS',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 12,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${members.length})',
                style: const TextStyle(color: _cyan, fontSize: 12),
              ),
            ],
          ),
        ),
        // メンバー追加ボタン
        _buildAddMemberButton(members),
        // メンバーリスト
        ...sorted.map(
          (uid) => _buildMemberItem(
            uid: uid,
            createdBy: createdBy,
            isOwner: isOwner,
          ),
        ),
      ],
    );
  }

  // === メンバー追加ボタン ===
  Widget _buildAddMemberButton(List<String> currentMembers) {
    return GestureDetector(
      onTap: () => _showAddMemberSheet(currentMembers),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _elevateColor,
              ),
              child: const Icon(Icons.person_add, size: 24, color: _cyan),
            ),
            const SizedBox(width: 16),
            const Text(
              'メンバーを追加',
              style: TextStyle(
                color: _cyan,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === メンバーアイテム ===
  Widget _buildMemberItem({
    required String uid,
    required String createdBy,
    required bool isOwner,
  }) {
    final isCreator = uid == createdBy;
    final isMe = uid == _myUid;
    final isFriend = _friendUids.contains(uid);
    final canTap = !isMe && isFriend;

    return FutureBuilder<Map<String, dynamic>>(
      future: _getMemberInfo(uid),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};
        final name = data['name'] as String? ?? '';
        final userId = data['userId'] as String?;
        final iconUrl = data['iconUrl'] as String?;

        Widget avatar = _buildMemberAvatar(iconUrl, name);

        return GestureDetector(
          onTap: canTap ? () => _navigateToFriendProfile(uid) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // アバター（グレースケール20%）
                avatar,
                const SizedBox(width: 16),
                // 名前 + userId + バッジ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: _textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCreator) ...[
                            const SizedBox(width: 8),
                            _buildBadge('OWNER', _cyan, _backgroundColor),
                          ],
                          if (isMe) ...[
                            const SizedBox(width: 8),
                            _buildBadge('YOU', _elevateColor, _textSecondary),
                          ],
                        ],
                      ),
                      if (userId != null && userId.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '@$userId',
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // 削除ボタン（作成者のみ表示、自分自身には非表示）
                if (isOwner && !isMe)
                  GestureDetector(
                    onTap: () => _showRemoveMemberDialog(uid, name),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.remove_circle_outline,
                        size: 24,
                        color: _danger,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // === メンバーアバター（グレースケール20%） ===
  Widget _buildMemberAvatar(String? iconUrl, String name) {
    if (iconUrl != null && iconUrl.isNotEmpty) {
      return ColorFiltered(
        colorFilter: ColorFilter.matrix(_grayscaleMatrix(0.2)),
        child: CircleAvatar(
          radius: 24,
          backgroundColor: _elevateColor,
          backgroundImage: NetworkImage(iconUrl),
        ),
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: _elevateColor,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: _cyan,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // === バッジ ===
  Widget _buildBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // === アクションセクション ===
  Widget _buildActionSection({
    required bool isOwner,
    required String groupName,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        24,
        16,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        children: [
          Container(height: 1, color: _elevateColor),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _showLeaveGroupDialog(isOwner),
            child: const Row(
              children: [
                Icon(Icons.logout, size: 20, color: _danger),
                SizedBox(width: 12),
                Text(
                  'グループを退出',
                  style: TextStyle(
                    color: _danger,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ロジック
  // ============================================================

  /// グループアイコン変更
  void _onChangeGroupIcon() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _elevateColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // ハンドルバー
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF555555),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 20),
              _iconSheetItem(
                icon: Icons.camera_alt,
                text: '写真を撮る',
                color: _textPrimary,
                onTap: () {
                  Navigator.pop(context);
                  // TODO: image_picker導入後に実装
                  showCustomDialog(
                    this.context,
                    title: '準備中',
                    message: 'カメラ機能は今後対応予定です。',
                  );
                },
              ),
              _iconSheetItem(
                icon: Icons.photo_library,
                text: 'ギャラリーから選択',
                color: _textPrimary,
                onTap: () {
                  Navigator.pop(context);
                  // TODO: image_picker導入後に実装
                  showCustomDialog(
                    this.context,
                    title: '準備中',
                    message: 'ギャラリー機能は今後対応予定です。',
                  );
                },
              ),
              // アイコン削除（設定済みの場合のみ） — MVPではアイコン未対応のため非表示
              _iconSheetItem(
                icon: Icons.close,
                text: 'キャンセル',
                color: _textSecondary,
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _iconSheetItem({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 24),
      title: Text(text, style: TextStyle(color: color, fontSize: 16)),
      onTap: onTap,
    );
  }

  /// グループ名編集確定
  Future<void> _onConfirmNameEdit() async {
    final newName = _nameEditController.text.trim();
    if (newName.isEmpty) return;

    if (newName.length > 50) {
      showCustomDialog(
        context,
        title: 'エラー',
        message: 'グループ名は50文字以内で入力してください。',
      );
      return;
    }

    try {
      await _firestore.collection('chats').doc(widget.chatId).update({
        'groupName': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() => _isEditingName = false);
    } catch (e) {
      if (!mounted) return;
      showCustomDialog(
        context,
        title: 'エラー',
        message: toUserFriendlyError(e),
      );
    }
  }

  /// 友達プロフィール画面へ遷移
  void _navigateToFriendProfile(String uid) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FriendProfileScreen(friendUid: uid),
      ),
    );
  }

  /// メンバー削除確認ダイアログ
  Future<void> _showRemoveMemberDialog(String uid, String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CustomDialog(
        title: 'メンバーを削除しますか？',
        content: Text(
          '${name.isNotEmpty ? name : 'このメンバー'}をこのグループから削除します。',
          style: const TextStyle(color: _textSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        actions: [
          CustomButton(
            text: '削除する',
            variant: CustomButtonVariant.danger,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 8),
          CustomButton(
            text: 'キャンセル',
            variant: CustomButtonVariant.secondary,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );

    if (result != true || !mounted) return;

    try {
      await _firestore.collection('chats').doc(widget.chatId).update({
        'members': FieldValue.arrayRemove([uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (!mounted) return;
      showCustomDialog(
        context,
        title: 'エラー',
        message: toUserFriendlyError(e),
      );
    }
  }

  /// グループ退出確認ダイアログ
  Future<void> _showLeaveGroupDialog(bool isOwner) async {
    final message = isOwner
        ? 'あなたはこのグループの作成者です。退出すると、グループ名やアイコンの編集・メンバーの削除ができなくなります。'
        : 'このグループから退出します。再度参加するにはメンバーからの招待が必要です。';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CustomDialog(
        title: 'グループを退出しますか？',
        content: Text(
          message,
          style: const TextStyle(color: _textSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        actions: [
          CustomButton(
            text: '退出する',
            variant: CustomButtonVariant.danger,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 8),
          CustomButton(
            text: 'キャンセル',
            variant: CustomButtonVariant.secondary,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );

    if (result != true || !mounted) return;

    try {
      await _firestore.collection('chats').doc(widget.chatId).update({
        'members': FieldValue.arrayRemove([_myUid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // メインシェル（トーク一覧タブ）に戻る
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      showCustomDialog(
        context,
        title: 'エラー',
        message: toUserFriendlyError(e),
      );
    }
  }

  /// メンバー追加ボトムシート
  Future<void> _showAddMemberSheet(List<String> currentMembers) async {
    final currentMemberSet = currentMembers.toSet();
    final selectedNewMembers = <String, Map<String, dynamic>>{};
    final searchController = TextEditingController();
    var searchQuery = '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _elevateColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    // ハンドルバー
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF555555),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // タイトル
                    const Text(
                      'メンバーを追加',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 検索バー
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: searchController,
                        style: const TextStyle(
                            color: _textPrimary, fontSize: 16),
                        cursorColor: _cyan,
                        decoration: InputDecoration(
                          hintText: '友達を検索...',
                          hintStyle: const TextStyle(color: _textDisabled),
                          prefixIcon:
                              const Icon(Icons.search, color: _textDisabled),
                          filled: true,
                          fillColor: _cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(100),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setSheetState(
                              () => searchQuery = value.toLowerCase());
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 友達リスト
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('users')
                            .doc(_myUid)
                            .collection('friends')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CustomLoadingIndicator());
                          }

                          final friends = snapshot.data!.docs;
                          final filtered = searchQuery.isEmpty
                              ? friends
                              : friends.where((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final name =
                                      (data['name'] as String? ?? '')
                                          .toLowerCase();
                                  return name.contains(searchQuery);
                                }).toList();

                          if (filtered.isEmpty) {
                            return const Center(
                              child: Text(
                                '友達が見つかりません',
                                style: TextStyle(
                                    color: _textSecondary, fontSize: 14),
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: scrollController,
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final doc = filtered[index];
                              final friendUid = doc.id;
                              final data =
                                  doc.data() as Map<String, dynamic>;
                              final name =
                                  data['name'] as String? ?? '';
                              final iconUrl =
                                  data['iconUrl'] as String?;
                              final isExistingMember =
                                  currentMemberSet.contains(friendUid);
                              final isSelected = selectedNewMembers
                                  .containsKey(friendUid);

                              return _buildAddMemberItem(
                                friendUid: friendUid,
                                name: name,
                                iconUrl: iconUrl,
                                isExistingMember: isExistingMember,
                                isSelected: isSelected,
                                onTap: isExistingMember
                                    ? null
                                    : () {
                                        setSheetState(() {
                                          if (isSelected) {
                                            selectedNewMembers
                                                .remove(friendUid);
                                          } else {
                                            selectedNewMembers[friendUid] =
                                                data;
                                          }
                                        });
                                      },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    // 追加ボタン
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: _cardColor, width: 1),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: CustomButton(
                          text: selectedNewMembers.isEmpty
                              ? '追加する'
                              : '追加する (${selectedNewMembers.length})',
                          onPressed: selectedNewMembers.isNotEmpty
                              ? () => _onAddMembers(
                                    sheetContext,
                                    selectedNewMembers.keys.toList(),
                                  )
                              : null,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );

    searchController.dispose();
  }

  // === メンバー追加リストアイテム ===
  Widget _buildAddMemberItem({
    required String friendUid,
    required String name,
    required String? iconUrl,
    required bool isExistingMember,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    // 既存メンバーはグレーアウト
    final nameColor = isExistingMember ? _textDisabled : _textPrimary;

    Widget avatar;
    if (iconUrl != null && iconUrl.isNotEmpty) {
      avatar = CircleAvatar(
        radius: 24,
        backgroundColor: _elevateColor,
        backgroundImage: NetworkImage(iconUrl),
      );
      // 既存メンバーは50%グレースケール、通常は選択時カラー/未選択時20%グレースケール
      final grayscale = isExistingMember ? 0.5 : (isSelected ? 0.0 : 0.2);
      if (grayscale > 0) {
        avatar = ColorFiltered(
          colorFilter: ColorFilter.matrix(_grayscaleMatrix(grayscale)),
          child: avatar,
        );
      }
    } else {
      avatar = CircleAvatar(
        radius: 24,
        backgroundColor: _elevateColor,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: isExistingMember ? _textDisabled : _cyan,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? _cardColor : Colors.transparent,
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: nameColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isExistingMember) ...[
                    const SizedBox(height: 2),
                    const Text(
                      '参加中',
                      style: TextStyle(color: _textDisabled, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            // チェックマーク（既存メンバーには非表示）
            if (!isExistingMember) _buildCheckMark(isSelected),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckMark(bool isSelected) {
    if (isSelected) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: _cyan,
        ),
        child: const Icon(Icons.check, size: 16, color: Colors.white),
      );
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _textDisabled, width: 1.5),
      ),
    );
  }

  /// メンバー追加処理
  Future<void> _onAddMembers(
    BuildContext sheetContext,
    List<String> newMemberUids,
  ) async {
    final navigator = Navigator.of(sheetContext);
    try {
      await _firestore.collection('chats').doc(widget.chatId).update({
        'members': FieldValue.arrayUnion(newMemberUids),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      showCustomDialog(
        context,
        title: 'エラー',
        message: toUserFriendlyError(e),
      );
    }
  }

  /// グレースケールマトリクス
  List<double> _grayscaleMatrix(double amount) {
    final s = 1.0 - amount;
    return [
      0.2126 + 0.7874 * s, 0.7152 - 0.7152 * s, 0.0722 - 0.0722 * s, 0, 0,
      0.2126 - 0.2126 * s, 0.7152 + 0.2848 * s, 0.0722 - 0.0722 * s, 0, 0,
      0.2126 - 0.2126 * s, 0.7152 - 0.7152 * s, 0.0722 + 0.9278 * s, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }
}
