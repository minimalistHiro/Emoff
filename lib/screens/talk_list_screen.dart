import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_loading_indicator.dart';

class TalkListScreen extends StatefulWidget {
  const TalkListScreen({super.key});

  @override
  State<TalkListScreen> createState() => _TalkListScreenState();
}

class _TalkListScreenState extends State<TalkListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchExpanded = false;

  static const _backgroundColor = Color(0xFF0D0D0D);
  static const _elevateColor = Color(0xFF242424);
  static const _cyan = Color(0xFF00D4FF);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFFA0A0A0);
  static const _textDisabled = Color(0xFF555555);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      drawer: const Drawer(),
      appBar: _isSearchExpanded ? _buildSearchAppBar() : _buildNormalAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildNormalAppBar() {
    final user = FirebaseAuth.instance.currentUser;

    return CustomAppBar(
      showBackButton: false,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: _cyan),
          onPressed: () {
            // TODO: サイドドロワー（4-7）実装後に接続
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      title: const Text(
        'EMOFF',
        style: TextStyle(
          color: _textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 3.0,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: _cyan),
          onPressed: () {
            setState(() => _isSearchExpanded = true);
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              // TODO: プロフィール設定画面（4-1）実装後に遷移を接続
            },
            child: _buildProfileAvatar(user),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileAvatar(User? user) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: _elevateColor,
      child: Text(
        user?.displayName?.isNotEmpty == true
            ? user!.displayName![0].toUpperCase()
            : 'U',
        style: const TextStyle(
          color: _cyan,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
    return CustomAppBar(
      showBackButton: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: _cyan),
        onPressed: () {
          setState(() {
            _isSearchExpanded = false;
            _searchQuery = '';
            _searchController.clear();
          });
        },
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(color: _textPrimary, fontSize: 16),
        cursorColor: _cyan,
        decoration: const InputDecoration(
          hintText: 'Search chats...',
          hintStyle: TextStyle(color: _textDisabled),
          border: InputBorder.none,
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close, color: _textSecondary),
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
            },
          ),
      ],
    );
  }

  Widget _buildBody() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: CustomLoadingIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('members', arrayContains: uid)
          .orderBy('lastMessageAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'エラーが発生しました',
              style: TextStyle(color: _textSecondary),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CustomLoadingIndicator());
        }

        final chats = snapshot.data?.docs ?? [];
        final filteredChats = _searchQuery.isEmpty
            ? chats
            : chats.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final type = data['type'] as String? ?? 'direct';
                if (type == 'group') {
                  final groupName =
                      (data['groupName'] as String? ?? '').toLowerCase();
                  return groupName.contains(_searchQuery);
                }
                // 1対1チャットは相手の名前で検索（lastMessage内にないため、今はスキップ）
                final lastMessage =
                    (data['lastMessage'] as String? ?? '').toLowerCase();
                return lastMessage.contains(_searchQuery);
              }).toList();

        return CustomScrollView(
          slivers: [
            // セクションヘッダー
            SliverToBoxAdapter(child: _buildSectionHeader()),
            // トークリスト
            if (filteredChats.isEmpty && chats.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              )
            else if (filteredChats.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      '検索結果がありません',
                      style: TextStyle(color: _textSecondary, fontSize: 14),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final data =
                          filteredChats[index].data() as Map<String, dynamic>;
                      final chatId = filteredChats[index].id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _ChatItem(
                          chatId: chatId,
                          data: data,
                          currentUid: uid,
                          onTap: () {
                            // TODO: トークルーム画面（3-1）実装後に遷移を接続
                          },
                        ),
                      );
                    },
                    childCount: filteredChats.length,
                  ),
                ),
              ),
            // AI Concierge ステータスセクション
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 100),
                child: _buildAiConciergeSection(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COMMUNICATION HUB',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Chats',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              // TODO: 新規トーク作成（友達選択 or グループ作成）の実装後に接続
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _cyan,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'New Discussion',
                style: TextStyle(
                  color: _backgroundColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAiConciergeSection(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildAiConciergeSection() {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: _textDisabled,
        borderRadius: 16,
        dashWidth: 6,
        dashSpace: 4,
        strokeWidth: 1.5,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        child: const Column(
          children: [
            Icon(Icons.auto_awesome, size: 36, color: _textDisabled),
            SizedBox(height: 16),
            Text(
              'AI Concierge Ready',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'All messages are currently being processed\nto maintain a professional and objective tone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// トークアイテムウィジェット
class _ChatItem extends StatefulWidget {
  const _ChatItem({
    required this.chatId,
    required this.data,
    required this.currentUid,
    required this.onTap,
  });

  final String chatId;
  final Map<String, dynamic> data;
  final String currentUid;
  final VoidCallback onTap;

  @override
  State<_ChatItem> createState() => _ChatItemState();
}

class _ChatItemState extends State<_ChatItem> {
  static const _cardColor = Color(0xFF1A1A1A);
  static const _elevateColor = Color(0xFF242424);
  static const _cyan = Color(0xFF00D4FF);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFFA0A0A0);

  // 1対1チャットの相手ユーザー情報
  String? _otherUserName;
  String? _otherUserIconUrl;

  @override
  void initState() {
    super.initState();
    _loadChatInfo();
  }

  @override
  void didUpdateWidget(covariant _ChatItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId) {
      _loadChatInfo();
    }
  }

  Future<void> _loadChatInfo() async {
    final type = widget.data['type'] as String? ?? 'direct';
    if (type == 'group') return;

    final members =
        List<String>.from(widget.data['members'] as List? ?? []);
    final otherUid = members.firstWhere(
      (uid) => uid != widget.currentUid,
      orElse: () => '',
    );

    if (otherUid.isEmpty) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(otherUid)
        .get();
    final userData = doc.data();

    if (mounted) {
      setState(() {
        _otherUserName = userData?['name'] as String?;
        _otherUserIconUrl = userData?['iconUrl'] as String?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.data['type'] as String? ?? 'direct';
    final isGroup = type == 'group';
    final lastMessage = widget.data['lastMessage'] as String? ?? '';
    final lastMessageAt = widget.data['lastMessageAt'] as Timestamp?;
    final lastReadAtMap =
        widget.data['lastReadAt'] as Map<String, dynamic>?;
    final myLastReadAt =
        lastReadAtMap?[widget.currentUid] as Timestamp?;

    final isUnread = lastMessageAt != null &&
        (myLastReadAt == null ||
            lastMessageAt.compareTo(myLastReadAt) > 0);

    final chatName = isGroup
        ? (widget.data['groupName'] as String? ?? 'グループ')
        : (_otherUserName ?? '...');

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isUnread ? _cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // アバター
            _buildAvatar(isGroup),
            const SizedBox(width: 16),
            // 名前 + メッセージプレビュー
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 名前 + 日時
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chatName,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastMessageAt != null)
                        Text(
                          _formatTimestamp(lastMessageAt),
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // メッセージプレビュー + 未読インジケーター
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage.isEmpty
                              ? 'No messages yet'
                              : lastMessage,
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 15,
                            fontWeight: isUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _cyan,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isGroup) {
    if (isGroup) {
      return _buildGroupAvatar();
    }
    return _buildDirectAvatar();
  }

  Widget _buildGroupAvatar() {
    final groupIconUrl = widget.data['groupIconUrl'] as String?;

    if (groupIconUrl != null && groupIconUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(groupIconUrl),
        backgroundColor: _elevateColor,
      );
    }

    return const CircleAvatar(
      radius: 28,
      backgroundColor: _elevateColor,
      child: Icon(Icons.group, color: _cyan, size: 24),
    );
  }

  Widget _buildDirectAvatar() {
    Widget avatar;
    if (_otherUserIconUrl != null && _otherUserIconUrl!.isNotEmpty) {
      avatar = CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(_otherUserIconUrl!),
        backgroundColor: _elevateColor,
      );
      // グレースケール20%を適用
      avatar = ColorFiltered(
        colorFilter: ColorFilter.matrix(_grayscaleMatrix(0.2)),
        child: avatar,
      );
    } else {
      final initial = (_otherUserName?.isNotEmpty == true)
          ? _otherUserName![0].toUpperCase()
          : '?';
      avatar = CircleAvatar(
        radius: 28,
        backgroundColor: _elevateColor,
        child: Text(
          initial,
          style: const TextStyle(
            color: _cyan,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // オンラインステータスインジケーター付きStack
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        children: [
          avatar,
          // TODO: オンラインステータスの実装（Firestoreにonlineフィールド追加後）
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(messageDay).inDays;

    if (diff == 0) {
      final hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = hour < 12 ? 'AM' : 'PM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$displayHour:$minute $period';
    } else if (diff == 1) {
      return 'Yesterday';
    } else if (diff < 7) {
      const days = [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday',
        'Friday', 'Saturday', 'Sunday',
      ];
      return days[date.weekday - 1];
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}';
    }
  }

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

/// 破線ボーダーを描画するカスタムペインター
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
    required this.dashWidth,
    required this.dashSpace,
    required this.strokeWidth,
  });

  final Color color;
  final double borderRadius;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        final extractPath = metric.extractPath(distance, end);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius;
  }
}
