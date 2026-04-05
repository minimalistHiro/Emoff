import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_loading_indicator.dart';
import 'friend_request_screen.dart';
import 'friend_request_management_screen.dart';
import 'friend_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchExpanded = false;

  static const _backgroundColor = Color(0xFF0D0D0D);
  static const _cardColor = Color(0xFF1A1A1A);
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
      // TODO: サイドドロワー（4-7）実装後に正式な Drawer に置き換え
      drawer: const Drawer(),
      appBar: _isSearchExpanded ? _buildSearchAppBar() : _buildNormalAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildNormalAppBar() {
    return CustomAppBar(
      showBackButton: false,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: _cyan),
        onPressed: () {
          // TODO: サイドドロワー（4-7）実装後に接続
          Scaffold.of(context).openDrawer();
        },
      ),
      title: const Text(
        'FRIENDS',
        style: TextStyle(
          color: _textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.0,
        ),
      ),
      actions: [
        // 友達申請管理ボタン（バッジ付き）
        _buildRequestsBadgeButton(),
        IconButton(
          icon: const Icon(Icons.person_add, color: _cyan),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FriendRequestScreen(),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.search, color: _cyan),
          onPressed: () {
            setState(() => _isSearchExpanded = true);
          },
        ),
      ],
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
          hintText: 'Search circle...',
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

  Widget _buildRequestsBadgeButton() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friend_requests')
          .where('toUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.mail_outline, color: _cyan),
              if (count > 0)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: _cyan,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Color(0xFF0D0D0D),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FriendRequestManagementScreen(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBody() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: CustomLoadingIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('friends')
          .orderBy('createdAt', descending: true)
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

        final friends = snapshot.data?.docs ?? [];
        final filteredFriends = _searchQuery.isEmpty
            ? friends
            : friends.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] as String? ?? '').toLowerCase();
                return name.contains(_searchQuery);
              }).toList();

        return CustomScrollView(
          slivers: [
            // ヒーローセクション
            SliverToBoxAdapter(child: _buildHeroSection()),
            // 検索バー
            SliverToBoxAdapter(child: _buildSearchBar()),
            // 友達リスト
            if (filteredFriends.isEmpty && friends.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              )
            else if (filteredFriends.isEmpty)
              SliverToBoxAdapter(child: _buildNoSearchResults())
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final data = filteredFriends[index].data()
                          as Map<String, dynamic>;
                      final friendUid = filteredFriends[index].id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FriendCard(
                          friendUid: friendUid,
                          name: data['name'] as String? ?? '',
                          iconUrl: data['iconUrl'] as String?,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => FriendProfileScreen(
                                  friendUid: friendUid,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    childCount: filteredFriends.length,
                  ),
                ),
              ),
            // 招待セクション（リスト下部）
            if (friends.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  child: _buildInviteSection(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeroSection() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Circle of\nClarity',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Your workspace for objective communication\nwith trusted peers. Quality over quantity.',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: GestureDetector(
        onTap: () {
          setState(() => _isSearchExpanded = true);
        },
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const Row(
            children: [
              Icon(Icons.filter_list, color: _textDisabled, size: 20),
              SizedBox(width: 12),
              Text(
                'Search circle...',
                style: TextStyle(color: _textDisabled, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildInviteSection(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          '検索結果がありません',
          style: TextStyle(color: _textSecondary, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildInviteSection() {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: _textDisabled,
        borderRadius: 24,
        dashWidth: 6,
        dashSpace: 4,
        strokeWidth: 1.5,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            const Icon(Icons.add_circle, size: 36, color: _textDisabled),
            const SizedBox(height: 16),
            const Text(
              'Expand your objective circle',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: CustomButton(
                text: 'Invite Friend',
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
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      backgroundColor: _cyan,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const FriendRequestScreen(),
          ),
        );
      },
      child: const Icon(Icons.add, color: _backgroundColor),
    );
  }
}

/// 友達カードウィジェット
class _FriendCard extends StatefulWidget {
  const _FriendCard({
    required this.friendUid,
    required this.name,
    this.iconUrl,
    required this.onTap,
  });

  final String friendUid;
  final String name;
  final String? iconUrl;
  final VoidCallback onTap;

  @override
  State<_FriendCard> createState() => _FriendCardState();
}

class _FriendCardState extends State<_FriendCard>
    with SingleTickerProviderStateMixin {
  static const _cardColor = Color(0xFF1A1A1A);
  static const _elevateColor = Color(0xFF242424);
  static const _cyan = Color(0xFF00D4FF);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFFA0A0A0);
  static const _textDisabled = Color(0xFF555555);

  bool _isPressed = false;
  late AnimationController _colorAnimController;
  late Animation<double> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _colorAnimController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _colorAnimation = CurvedAnimation(
      parent: _colorAnimController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _colorAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _colorAnimController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _colorAnimController.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _colorAnimController.reverse();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isPressed ? _elevateColor : _cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // アバター（グレースケール→カラーアニメーション）
            AnimatedBuilder(
              animation: _colorAnimation,
              builder: (context, child) {
                return _buildAvatar();
              },
            ),
            const SizedBox(width: 16),
            // 名前 + ステータス
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'MEMBER',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _textDisabled, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final saturation = _colorAnimation.value;

    Widget avatar;
    if (widget.iconUrl != null && widget.iconUrl!.isNotEmpty) {
      avatar = CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(widget.iconUrl!),
        backgroundColor: _elevateColor,
      );
    } else {
      avatar = CircleAvatar(
        radius: 28,
        backgroundColor: _elevateColor,
        child: Text(
          widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: _cyan,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // ネットワーク画像がある場合のみグレースケールフィルタを適用
    if (widget.iconUrl != null && widget.iconUrl!.isNotEmpty) {
      return ColorFiltered(
        colorFilter: ColorFilter.matrix(_grayscaleMatrix(1.0 - saturation)),
        child: avatar,
      );
    }
    return avatar;
  }

  /// グレースケール変換マトリクス（amount: 0.0 = カラー, 1.0 = グレースケール）
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
