import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_loading_indicator.dart';
import '../widgets/custom_dialog_helper.dart';

class FriendRequestManagementScreen extends StatefulWidget {
  const FriendRequestManagementScreen({super.key});

  @override
  State<FriendRequestManagementScreen> createState() =>
      _FriendRequestManagementScreenState();
}

class _FriendRequestManagementScreenState
    extends State<FriendRequestManagementScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  static const _backgroundColor = Color(0xFF0D0D0D);
  static const _cyan = Color(0xFF00D4FF);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFFA0A0A0);
  static const _textDisabled = Color(0xFF555555);

  // 処理中の申請ID（二重タップ防止）
  final Set<String> _processingIds = {};

  // フェードアウト中の申請ID
  final Set<String> _fadingOutIds = {};

  // userIdキャッシュ（fromUid -> userId）
  final Map<String, String> _userIdCache = {};

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        appBar: const CustomAppBar(titleText: 'REQUESTS'),
        body: const Center(child: CustomLoadingIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(uid),
      body: _buildBody(uid),
    );
  }

  // === AppBar ===
  PreferredSizeWidget _buildAppBar(String uid) {
    return CustomAppBar(
      title: StreamBuilder<QuerySnapshot>(
        stream: _pendingRequestsStream(uid),
        builder: (context, snapshot) {
          final count = snapshot.data?.docs.length ?? 0;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'REQUESTS',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: const BoxDecoration(
                    color: _cyan,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Color(0xFF0D0D0D),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // === Body ===
  Widget _buildBody(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: _pendingRequestsStream(uid),
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

        final docs = snapshot.data?.docs ?? [];

        // フェードアウト中でないドキュメントのみ表示
        final visibleDocs =
            docs.where((d) => !_fadingOutIds.contains(d.id)).toList();

        if (visibleDocs.isEmpty && _fadingOutIds.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // セクションヘッダー
            _buildSectionHeader(visibleDocs.length),
            // 申請リスト
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: visibleDocs.length,
                itemBuilder: (context, index) {
                  final doc = visibleDocs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _RequestCard(
                    key: ValueKey(doc.id),
                    requestId: doc.id,
                    data: data,
                    isProcessing: _processingIds.contains(doc.id),
                    userIdCache: _userIdCache,
                    onAccept: () => _onAccept(doc.id, data),
                    onReject: () => _onReject(doc.id, data),
                    onUserIdLoaded: (fromUid, userId) {
                      _userIdCache[fromUid] = userId;
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // === セクションヘッダー ===
  Widget _buildSectionHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '受信した友達申請',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '$count件の申請',
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // === 空状態 ===
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mail_outline, size: 64, color: _textDisabled),
          SizedBox(height: 16),
          Text(
            '友達申請はありません',
            style: TextStyle(color: _textSecondary, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            '新しい申請が届くとここに表示されます',
            style: TextStyle(color: _textDisabled, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // === Firestoreストリーム ===
  Stream<QuerySnapshot> _pendingRequestsStream(String uid) {
    return _firestore
        .collection('friend_requests')
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // === 承認処理 ===
  Future<void> _onAccept(String requestId, Map<String, dynamic> data) async {
    final fromName = data['fromName'] as String? ?? '';

    final confirmed = await showCustomConfirmDialog(
      context,
      title: '友達申請の承認',
      message: '$fromNameさんの友達申請を承認しますか？',
      confirmText: '承認',
    );

    if (!confirmed || !mounted) return;

    setState(() => _processingIds.add(requestId));

    try {
      final myUid = _auth.currentUser!.uid;
      final fromUid = data['fromUid'] as String;
      final fromIconUrl = data['fromIconUrl'] as String? ?? '';

      // 自分の情報を取得
      final myDoc = await _firestore.collection('users').doc(myUid).get();
      final myData = myDoc.data() ?? {};
      final myName = myData['name'] as String? ?? '';
      final myIconUrl = myData['iconUrl'] as String? ?? '';

      // バッチ書き込み
      final batch = _firestore.batch();

      // 1. friend_requestのstatusを更新
      batch.update(_firestore.collection('friend_requests').doc(requestId), {
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. 自分のfriendsサブコレクションに追加
      batch.set(
        _firestore
            .collection('users')
            .doc(myUid)
            .collection('friends')
            .doc(fromUid),
        {
          'name': fromName,
          'iconUrl': fromIconUrl,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      // 3. 相手のfriendsサブコレクションに追加
      batch.set(
        _firestore
            .collection('users')
            .doc(fromUid)
            .collection('friends')
            .doc(myUid),
        {
          'name': myName,
          'iconUrl': myIconUrl,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      if (!mounted) return;

      setState(() {
        _processingIds.remove(requestId);
        _fadingOutIds.add(requestId);
      });

      // フェードアウト後に削除
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() => _fadingOutIds.remove(requestId));
        }
      });

      showCustomDialog(
        context,
        title: '友達になりました',
        message: '$fromNameさんと友達になりました',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _processingIds.remove(requestId));
      showCustomDialog(
        context,
        title: 'エラー',
        message: toUserFriendlyError(e),
      );
    }
  }

  // === 拒否処理 ===
  Future<void> _onReject(String requestId, Map<String, dynamic> data) async {
    final fromName = data['fromName'] as String? ?? '';

    final confirmed = await showCustomConfirmDialog(
      context,
      title: '友達申請の拒否',
      message: '$fromNameさんの友達申請を拒否しますか？',
      confirmText: '拒否',
      confirmVariant: CustomButtonVariant.danger,
    );

    if (!confirmed || !mounted) return;

    setState(() => _processingIds.add(requestId));

    try {
      await _firestore.collection('friend_requests').doc(requestId).update({
        'status': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _processingIds.remove(requestId);
        _fadingOutIds.add(requestId);
      });

      // フェードアウト後に削除（拒否は静かに処理、ダイアログなし）
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() => _fadingOutIds.remove(requestId));
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _processingIds.remove(requestId));
      showCustomDialog(
        context,
        title: 'エラー',
        message: toUserFriendlyError(e),
      );
    }
  }
}

// === 申請カードウィジェット ===
class _RequestCard extends StatefulWidget {
  const _RequestCard({
    super.key,
    required this.requestId,
    required this.data,
    required this.isProcessing,
    required this.userIdCache,
    required this.onAccept,
    required this.onReject,
    required this.onUserIdLoaded,
  });

  final String requestId;
  final Map<String, dynamic> data;
  final bool isProcessing;
  final Map<String, String> userIdCache;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final void Function(String fromUid, String userId) onUserIdLoaded;

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  static const _cardColor = Color(0xFF1A1A1A);
  static const _elevateColor = Color(0xFF242424);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFFA0A0A0);
  static const _textDisabled = Color(0xFF555555);

  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final fromUid = widget.data['fromUid'] as String? ?? '';
    if (fromUid.isEmpty) return;

    // キャッシュを確認
    if (widget.userIdCache.containsKey(fromUid)) {
      setState(() => _userId = widget.userIdCache[fromUid]);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(fromUid)
          .get();
      if (mounted && doc.exists) {
        final userId = doc.data()?['userId'] as String?;
        if (userId != null) {
          setState(() => _userId = userId);
          widget.onUserIdLoaded(fromUid, userId);
        }
      }
    } catch (_) {
      // ユーザーID取得失敗は無視（表示されないだけ）
    }
  }

  @override
  Widget build(BuildContext context) {
    final fromName = widget.data['fromName'] as String? ?? '';
    final fromIconUrl = widget.data['fromIconUrl'] as String?;
    final createdAt = widget.data['createdAt'] as Timestamp?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // 上段: アバター + 名前・ID + 日時
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // アバター
                _buildAvatar(fromIconUrl),
                const SizedBox(width: 12),
                // 名前 + ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fromName,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _userId != null ? '@$_userId' : '',
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // 日時
                if (createdAt != null)
                  Text(
                    _formatRelativeTime(createdAt.toDate()),
                    style: const TextStyle(
                      color: _textDisabled,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // 下段: 承認・拒否ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 96,
                  child: CustomButton(
                    text: '承認',
                    height: 36,
                    isLoading: widget.isProcessing,
                    onPressed: widget.isProcessing ? null : widget.onAccept,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 96,
                  child: CustomButton(
                    text: '拒否',
                    height: 36,
                    variant: CustomButtonVariant.secondary,
                    onPressed: widget.isProcessing ? null : widget.onReject,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? iconUrl) {
    if (iconUrl != null && iconUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(iconUrl),
        backgroundColor: _elevateColor,
      );
    }
    return const CircleAvatar(
      radius: 24,
      backgroundColor: Color(0xFF555555),
      child: Icon(Icons.person, size: 24, color: Color(0xFFA0A0A0)),
    );
  }

  /// 相対時間フォーマット
  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'たった今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    if (diff.inDays < 7) return '${diff.inDays}日前';

    // 7日以上: MM/DD形式
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$month/$day';
  }
}
