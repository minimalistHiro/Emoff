import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/custom_dialog_helper.dart';
import '../widgets/custom_loading_indicator.dart';
import 'talk_room_screen.dart';

class FriendProfileScreen extends StatefulWidget {
  const FriendProfileScreen({
    super.key,
    required this.friendUid,
  });

  final String friendUid;

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _chatService = ChatService();

  static const _backgroundColor = Color(0xFF0D0D0D);
  static const _cardColor = Color(0xFF1A1A1A);
  static const _elevateColor = Color(0xFF242424);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFFA0A0A0);
  static const _textDisabled = Color(0xFF555555);
  static const _danger = Color(0xFFFF4D4D);

  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final doc =
          await _firestore.collection('users').doc(widget.friendUid).get();
      if (!mounted) return;

      if (!doc.exists) {
        showCustomDialog(
          context,
          title: 'エラー',
          message: 'このユーザーは存在しません',
        ).then((_) {
          if (mounted) Navigator.of(context).pop();
        });
        return;
      }

      setState(() {
        _userData = doc.data();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      showCustomDialog(
        context,
        title: 'エラー',
        message: toUserFriendlyError(e),
      ).then((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: _textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CustomLoadingIndicator()),
      );
    }

    final data = _userData!;
    final name = data['name'] as String? ?? '';
    final userId = data['userId'] as String? ?? '';
    final iconUrl = data['iconUrl'] as String?;
    final backgroundUrl = data['backgroundUrl'] as String?;
    final bio = data['bio'] as String?;

    return Scaffold(
      backgroundColor: _backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(name),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 背景画像 + アイコン
            _buildHeaderSection(backgroundUrl, iconUrl),
            const SizedBox(height: 16),
            // ユーザー情報
            _buildUserInfo(name, userId, bio),
          ],
        ),
      ),
      bottomNavigationBar: _buildTalkButton(name),
    );
  }

  // === 透過AppBar ===
  PreferredSizeWidget _buildAppBar(String friendName) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios,
          color: _textPrimary,
          shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_vert,
            color: _textPrimary,
            shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
          ),
          color: _elevateColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) {
            if (value == 'block') {
              _showBlockDialog(friendName);
            } else if (value == 'report') {
              showCustomDialog(
                context,
                title: 'お知らせ',
                message: '通報機能は準備中です',
              );
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(Icons.block, color: _danger, size: 20),
                  SizedBox(width: 8),
                  Text('ブロック', style: TextStyle(color: _danger)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.flag, color: _textSecondary, size: 20),
                  SizedBox(width: 8),
                  Text('通報', style: TextStyle(color: _textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // === 背景画像 + アイコン ===
  Widget _buildHeaderSection(String? backgroundUrl, String? iconUrl) {
    const backgroundHeight = 240.0;
    const iconRadius = 48.0;

    return SizedBox(
      height: backgroundHeight + iconRadius,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 背景画像
          if (backgroundUrl != null && backgroundUrl.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: backgroundHeight,
              child: Image.network(
                backgroundUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultBackground(),
              ),
            )
          else
            _buildDefaultBackground(),
          // グラデーションオーバーレイ
          Positioned(
            bottom: iconRadius,
            left: 0,
            right: 0,
            height: backgroundHeight,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    _backgroundColor.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
          // プロフィールアイコン
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _textPrimary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildAvatarCircle(iconUrl, iconRadius),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultBackground() {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_cardColor, _elevateColor],
        ),
      ),
    );
  }

  Widget _buildAvatarCircle(String? iconUrl, double radius) {
    if (iconUrl != null && iconUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(iconUrl),
        backgroundColor: _cardColor,
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: _cardColor,
      child: Icon(Icons.person, size: radius, color: _textDisabled),
    );
  }

  // === ユーザー情報 ===
  Widget _buildUserInfo(String name, String userId, String? bio) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // ユーザー名
          Text(
            name,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // ユーザーID
          Text(
            '@$userId',
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          // 自己紹介文（ある場合のみ）
          if (bio != null && bio.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 1,
              color: _elevateColor,
            ),
            const SizedBox(height: 16),
            Text(
              bio,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // === トークボタン（下部固定） ===
  Widget _buildTalkButton(String friendName) {
    return Container(
      color: _backgroundColor,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: SafeArea(
        top: false,
        child: CustomButton(
          text: 'トーク',
          icon: Icons.chat_bubble_outline,
          onPressed: () => _navigateToTalkRoom(friendName),
        ),
      ),
    );
  }

  // === トークルームへ遷移 ===
  Future<void> _navigateToTalkRoom(String friendName) async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null) return;

    try {
      // friendsサブコレクションからchatIdを確認
      final friendDoc = await _firestore
          .collection('users')
          .doc(myUid)
          .collection('friends')
          .doc(widget.friendUid)
          .get();

      String? chatId = friendDoc.data()?['chatId'] as String?;

      if (chatId == null) {
        // 新規チャットを作成
        final chatRef = await _firestore.collection('chats').add({
          'type': 'direct',
          'members': [myUid, widget.friendUid],
          'lastMessage': null,
          'lastMessageAt': null,
          'lastReadAt': {},
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        chatId = chatRef.id;

        // 両方のfriendsサブコレクションにchatIdを書き戻す
        final batch = _firestore.batch();
        batch.update(
          _firestore
              .collection('users')
              .doc(myUid)
              .collection('friends')
              .doc(widget.friendUid),
          {'chatId': chatId},
        );
        batch.update(
          _firestore
              .collection('users')
              .doc(widget.friendUid)
              .collection('friends')
              .doc(myUid),
          {'chatId': chatId},
        );
        await batch.commit();
      }

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TalkRoomScreen(
            chatId: chatId!,
            chatType: 'direct',
            otherUserName: friendName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showCustomDialog(
        context,
        title: 'エラー',
        message: toUserFriendlyError(e),
      );
    }
  }

  // === ブロック確認ダイアログ ===
  Future<void> _showBlockDialog(String friendName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CustomDialog(
        title: '$friendNameさんをブロック',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, size: 48, color: _danger),
            const SizedBox(height: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BulletText('相手からのメッセージが届かなくなります'),
                SizedBox(height: 8),
                _BulletText('友達リストからお互いに削除されます'),
                SizedBox(height: 8),
                _BulletText('ブロックしたことは相手に通知されません'),
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
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'ブロックする',
                  variant: CustomButtonVariant.danger,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (result != true || !mounted) return;

    await _executeBlock();
  }

  // === ブロック処理（友達削除はCloud Functions onBlockUserが処理） ===
  Future<void> _executeBlock() async {
    try {
      await _chatService.blockUser(widget.friendUid);

      if (!mounted) return;

      // ホーム画面に戻る
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      showCustomDialog(
        context,
        title: 'エラー',
        message: toUserFriendlyError(e),
      );
    }
  }
}

// === 箇条書きテキスト ===
class _BulletText extends StatelessWidget {
  const _BulletText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '・',
          style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 14),
        ),
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
