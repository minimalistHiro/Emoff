import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_loading_indicator.dart';
import '../widgets/custom_dialog_helper.dart';
import 'friend_request_screen.dart';
import 'talk_room_screen.dart';

class GroupCreationScreen extends StatefulWidget {
  const GroupCreationScreen({super.key});

  @override
  State<GroupCreationScreen> createState() => _GroupCreationScreenState();
}

class _GroupCreationScreenState extends State<GroupCreationScreen> {
  final _groupNameController = TextEditingController();
  final _searchController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  static const _backgroundColor = Color(0xFF0D0D0D);
  static const _cardColor = Color(0xFF1A1A1A);
  static const _elevateColor = Color(0xFF242424);
  static const _cyan = Color(0xFF00D4FF);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFFA0A0A0);
  static const _textDisabled = Color(0xFF555555);

  // 選択済みメンバー: uid -> {name, iconUrl}
  final Map<String, Map<String, dynamic>> _selectedMembers = {};
  String _searchQuery = '';
  bool _isCreating = false;

  bool get _canCreate =>
      _groupNameController.text.trim().isNotEmpty &&
      _selectedMembers.isNotEmpty;

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onBack();
      },
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(
              child: _buildBody(),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // === AppBar ===
  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      showBackButton: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: _cyan),
        onPressed: _onBack,
      ),
      title: const Text(
        'New Group',
        style: TextStyle(
          color: _textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _canCreate && !_isCreating ? _onCreateGroup : null,
          child: Text(
            'Create',
            style: TextStyle(
              color: _canCreate && !_isCreating ? _cyan : _textDisabled,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // === Body ===
  Widget _buildBody() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Center(child: CustomLoadingIndicator());
    }

    return CustomScrollView(
      slivers: [
        // グループ情報セクション
        SliverToBoxAdapter(child: _buildGroupInfoSection()),
        // 選択済みメンバープレビュー
        if (_selectedMembers.isNotEmpty)
          SliverToBoxAdapter(child: _buildSelectedMembersPreview()),
        // 友達検索バー
        SliverToBoxAdapter(child: _buildSearchBar()),
        // 友達リスト
        _buildFriendsList(uid),
      ],
    );
  }

  // === グループ情報セクション ===
  Widget _buildGroupInfoSection() {
    return Container(
      color: _cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          // グループアイコン
          GestureDetector(
            onTap: _onSelectGroupIcon,
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _elevateColor,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.groups, size: 36, color: _textSecondary),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.6),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: _cyan,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // グループ名入力
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CustomTextField(
                  controller: _groupNameController,
                  hintText: 'グループ名を入力',
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_groupNameController.text.length}/50',
                  style: TextStyle(
                    color: _groupNameController.text.length > 50
                        ? const Color(0xFFFF4D4D)
                        : _textDisabled,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === 選択済みメンバープレビュー ===
  Widget _buildSelectedMembersPreview() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // セクションラベル
          Row(
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
                '(${_selectedMembers.length})',
                style: const TextStyle(
                  color: _cyan,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // メンバーチップリスト
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _selectedMembers.entries.map((entry) {
                final uid = entry.key;
                final data = entry.value;
                final name = data['name'] as String? ?? '';
                final iconUrl = data['iconUrl'] as String?;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
                    decoration: BoxDecoration(
                      color: _elevateColor,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // アバター
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: _cardColor,
                          backgroundImage: (iconUrl != null && iconUrl.isNotEmpty)
                              ? NetworkImage(iconUrl)
                              : null,
                          child: (iconUrl == null || iconUrl.isEmpty)
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: _cyan,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 6),
                        // 名前
                        Text(
                          name,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // 削除ボタン
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMembers.remove(uid);
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // === 友達検索バー ===
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: _textPrimary, fontSize: 16),
        cursorColor: _cyan,
        decoration: InputDecoration(
          hintText: '友達を検索...',
          hintStyle: const TextStyle(color: _textDisabled),
          prefixIcon: const Icon(Icons.search, color: _textDisabled),
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
          setState(() => _searchQuery = value.toLowerCase());
        },
      ),
    );
  }

  // === 友達リスト ===
  Widget _buildFriendsList(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(uid)
          .collection('friends')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'エラーが発生しました',
                  style: TextStyle(color: _textSecondary, fontSize: 14),
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CustomLoadingIndicator()),
            ),
          );
        }

        final friends = snapshot.data?.docs ?? [];

        // 検索フィルタリング
        final filteredFriends = _searchQuery.isEmpty
            ? friends
            : friends.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] as String? ?? '').toLowerCase();
                final friendId = doc.id.toLowerCase();
                return name.contains(_searchQuery) ||
                    friendId.contains(_searchQuery);
              }).toList();

        // 友達がいない場合
        if (friends.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(),
          );
        }

        // 検索結果なし
        if (filteredFriends.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  '検索結果がありません',
                  style: TextStyle(color: _textSecondary, fontSize: 14),
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final doc = filteredFriends[index];
              final friendUid = doc.id;
              final data = doc.data() as Map<String, dynamic>;
              final isSelected = _selectedMembers.containsKey(friendUid);

              return _buildFriendItem(friendUid, data, isSelected);
            },
            childCount: filteredFriends.length,
          ),
        );
      },
    );
  }

  // === 友達アイテム ===
  Widget _buildFriendItem(
      String friendUid, Map<String, dynamic> data, bool isSelected) {
    final name = data['name'] as String? ?? '';
    final iconUrl = data['iconUrl'] as String?;

    Widget avatar;
    if (iconUrl != null && iconUrl.isNotEmpty) {
      avatar = CircleAvatar(
        radius: 24,
        backgroundColor: _elevateColor,
        backgroundImage: NetworkImage(iconUrl),
      );
      if (!isSelected) {
        avatar = ColorFiltered(
          colorFilter: ColorFilter.matrix(_grayscaleMatrix(0.2)),
          child: avatar,
        );
      }
    } else {
      avatar = CircleAvatar(
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

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedMembers.remove(friendUid);
          } else {
            _selectedMembers[friendUid] = data;
          }
        });
      },
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
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FutureBuilder<DocumentSnapshot>(
                    future: _firestore.collection('users').doc(friendUid).get(),
                    builder: (context, snapshot) {
                      final userId =
                          snapshot.data?.data() is Map<String, dynamic>
                              ? (snapshot.data!.data()
                                  as Map<String, dynamic>)['userId'] as String?
                              : null;
                      return Text(
                        userId != null ? '@$userId' : '',
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 13,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // チェックマーク
            _buildCheckMark(isSelected),
          ],
        ),
      ),
    );
  }

  // === チェックマーク ===
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

  // === Empty State ===
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_add, size: 48, color: _textDisabled),
          const SizedBox(height: 16),
          const Text(
            '友達を追加してからグループを作成しましょう',
            style: TextStyle(color: _textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 200,
            child: CustomButton(
              text: '友達を追加',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FriendRequestScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // === 固定フッター ===
  Widget _buildFooter() {
    return Container(
      decoration: const BoxDecoration(
        color: _backgroundColor,
        border: Border(
          top: BorderSide(color: _elevateColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedMembers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${_selectedMembers.length}人のメンバーを選択中',
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            CustomButton(
              text: 'グループを作成',
              isLoading: _isCreating,
              onPressed: _canCreate && !_isCreating ? _onCreateGroup : null,
            ),
          ],
        ),
      ),
    );
  }

  // === ロジック ===

  /// 戻るボタン処理
  Future<void> _onBack() async {
    final hasInput = _groupNameController.text.trim().isNotEmpty ||
        _selectedMembers.isNotEmpty;

    if (hasInput) {
      final confirmed = await showCustomConfirmDialog(
        context,
        title: '作成を中止しますか？',
        message: '入力した内容は保存されません。',
        confirmText: '中止する',
        confirmVariant: CustomButtonVariant.danger,
        cancelText: '続ける',
      );
      if (!confirmed || !mounted) return;
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  /// グループアイコン選択
  void _onSelectGroupIcon() {
    // TODO: image_picker導入後に実装
    showCustomDialog(
      context,
      title: '準備中',
      message: 'グループアイコンの設定は今後対応予定です。',
    );
  }

  /// グループ作成処理
  Future<void> _onCreateGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty || _selectedMembers.isEmpty) return;

    if (groupName.length > 50) {
      showCustomDialog(
        context,
        title: 'エラー',
        message: 'グループ名は50文字以内で入力してください。',
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final myUid = _auth.currentUser!.uid;
      final memberUids = [myUid, ..._selectedMembers.keys];

      // Firestoreにchatsドキュメントを作成
      final chatRef = await _firestore.collection('chats').add({
        'type': 'group',
        'members': memberUids,
        'groupName': groupName,
        'groupIconUrl': null,
        'createdBy': myUid,
        'lastMessage': null,
        'lastMessageAt': null,
        'lastReadAt': {},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // 作成したグループのトークルームへ遷移
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TalkRoomScreen(
            chatId: chatRef.id,
            chatType: 'group',
            groupName: groupName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCreating = false);
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
