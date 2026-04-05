import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_loading_indicator.dart';
import '../widgets/custom_dialog_helper.dart';
import 'friend_request_management_screen.dart';

class FriendRequestScreen extends StatefulWidget {
  const FriendRequestScreen({super.key});

  @override
  State<FriendRequestScreen> createState() => _FriendRequestScreenState();
}

class _FriendRequestScreenState extends State<FriendRequestScreen> {
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

  // 検索状態
  _SearchState _searchState = _SearchState.initial;
  // 検索結果のユーザーデータ
  Map<String, dynamic>? _foundUser;
  String? _foundUserUid;
  // 申請ボタンの状態
  _ButtonState _buttonState = _ButtonState.sendRequest;
  // バリデーションエラー
  String? _validationError;
  // 自分のuserId
  String? _myUserId;
  // 検索中・申請送信中のロック
  bool _isSearching = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMyUserId();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMyUserId() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (mounted && doc.exists) {
      setState(() {
        _myUserId = doc.data()?['userId'] as String?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: const CustomAppBar(
        title: Text(
          'ADD FRIEND',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // 説明セクション
                  _buildDescriptionSection(),
                  const SizedBox(height: 32),
                  // 検索入力エリア
                  _buildSearchInput(),
                  const SizedBox(height: 24),
                  // 検索結果エリア
                  _buildSearchResult(),
                ],
              ),
            ),
          ),
          // 自分のID表示セクション（画面下部固定）
          _buildMyIdSection(),
        ],
      ),
    );
  }

  // === 説明セクション ===
  Widget _buildDescriptionSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'IDで友達を検索',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '相手のユーザーIDを入力して友達申請を送りましょう',
          style: TextStyle(
            color: _textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // === 検索入力エリア ===
  Widget _buildSearchInput() {
    final hasText = _searchController.text.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomTextField(
            controller: _searchController,
            hintText: 'ユーザーIDを入力',
            textInputAction: TextInputAction.search,
            errorText: _validationError,
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 16, right: 4),
              child: Text(
                '@',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
            onChanged: (_) {
              if (_validationError != null) {
                setState(() => _validationError = null);
              }
              setState(() {});
            },
            onSubmitted: (_) => _onSearch(),
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: GestureDetector(
            onTap: (hasText && !_isSearching) ? _onSearch : null,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (hasText && !_isSearching) ? _cyan : _textDisabled,
              ),
              child: const Icon(
                Icons.search,
                color: _backgroundColor,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // === 検索結果エリア ===
  Widget _buildSearchResult() {
    switch (_searchState) {
      case _SearchState.initial:
        return _buildInitialState();
      case _SearchState.searching:
        return _buildSearchingState();
      case _SearchState.found:
        return _buildFoundState();
      case _SearchState.notFound:
        return _buildNotFoundState();
    }
  }

  // 4-a. 初期状態
  Widget _buildInitialState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 64),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.person_search, size: 64, color: _textDisabled),
            SizedBox(height: 16),
            Text(
              'IDを入力して検索してください',
              style: TextStyle(color: _textDisabled, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // 4-b. 検索中
  Widget _buildSearchingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 64),
      child: Center(
        child: Column(
          children: [
            CustomLoadingIndicator(),
            SizedBox(height: 16),
            Text(
              '検索中...',
              style: TextStyle(color: _textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // 4-c. ユーザー発見
  Widget _buildFoundState() {
    if (_foundUser == null) return const SizedBox.shrink();

    final name = _foundUser!['name'] as String? ?? '';
    final userId = _foundUser!['userId'] as String? ?? '';
    final bio = _foundUser!['bio'] as String?;
    final iconUrl = _foundUser!['iconUrl'] as String?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // アバター
          CircleAvatar(
            radius: 36,
            backgroundColor: _elevateColor,
            backgroundImage:
                (iconUrl != null && iconUrl.isNotEmpty) ? NetworkImage(iconUrl) : null,
            child: (iconUrl == null || iconUrl.isEmpty)
                ? const Icon(Icons.person, size: 36, color: _textDisabled)
                : null,
          ),
          const SizedBox(height: 12),
          // ユーザー名
          Text(
            name,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 18,
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
          ),
          // 自己紹介文
          if (bio != null && bio.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              bio,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 20),
          // 申請ボタン
          _buildActionButton(),
        ],
      ),
    );
  }

  // 申請ボタン（5パターン分岐）
  Widget _buildActionButton() {
    switch (_buttonState) {
      case _ButtonState.sendRequest:
        return CustomButton(
          text: '友達申請を送る',
          isLoading: _isSending,
          onPressed: _isSending ? null : _onSendRequest,
        );
      case _ButtonState.alreadyFriend:
        return const CustomButton(
          text: '友達です',
          variant: CustomButtonVariant.secondary,
          onPressed: null,
        );
      case _ButtonState.alreadySent:
        return const CustomButton(
          text: '申請済み',
          variant: CustomButtonVariant.secondary,
          onPressed: null,
        );
      case _ButtonState.receivedRequest:
        return CustomButton(
          text: '申請が届いています',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FriendRequestManagementScreen(),
              ),
            );
          },
        );
      case _ButtonState.isSelf:
        return const CustomButton(
          text: '自分のIDです',
          variant: CustomButtonVariant.secondary,
          onPressed: null,
        );
    }
  }

  // 4-d. ユーザー未発見
  Widget _buildNotFoundState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 64),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.person_off, size: 64, color: _textDisabled),
            SizedBox(height: 16),
            Text(
              'ユーザーが見つかりませんでした',
              style: TextStyle(color: _textSecondary, fontSize: 14),
            ),
            SizedBox(height: 4),
            Text(
              'IDを確認して再度検索してください',
              style: TextStyle(color: _textDisabled, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // === 自分のID表示セクション ===
  Widget _buildMyIdSection() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _elevateColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'YOUR ID',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _myUserId != null ? '@$_myUserId' : '...',
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (_myUserId != null)
              GestureDetector(
                onTap: _onCopyMyId,
                child: const Icon(
                  Icons.content_copy,
                  size: 20,
                  color: _cyan,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // === ロジック ===

  /// 入力バリデーション
  bool _validateInput(String input) {
    if (input.isEmpty) return false;
    final regex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!regex.hasMatch(input)) {
      setState(() {
        _validationError = '半角英数字とアンダースコアのみ使用できます';
      });
      return false;
    }
    return true;
  }

  /// 検索実行
  Future<void> _onSearch() async {
    FocusScope.of(context).unfocus();
    final input = _searchController.text.trim();
    if (!_validateInput(input)) return;

    setState(() {
      _searchState = _SearchState.searching;
      _isSearching = true;
      _validationError = null;
    });

    try {
      final myUid = _auth.currentUser!.uid;

      // ユーザーをuserIdで検索
      final querySnapshot = await _firestore
          .collection('users')
          .where('userId', isEqualTo: input)
          .limit(1)
          .get();

      if (!mounted) return;

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _searchState = _SearchState.notFound;
          _isSearching = false;
        });
        return;
      }

      final userDoc = querySnapshot.docs.first;
      final targetUid = userDoc.id;
      final userData = userDoc.data();

      // ブロック中のユーザーチェック（自分がブロックしている相手）
      final blockedDoc = await _firestore
          .collection('users')
          .doc(myUid)
          .collection('blocked_users')
          .doc(targetUid)
          .get();

      if (!mounted) return;

      if (blockedDoc.exists) {
        // ブロック中のユーザーは「見つかりませんでした」と表示
        setState(() {
          _searchState = _SearchState.notFound;
          _isSearching = false;
        });
        return;
      }

      // ボタン状態を判定
      final buttonState = await _determineButtonState(myUid, targetUid);

      if (!mounted) return;

      setState(() {
        _foundUser = userData;
        _foundUserUid = targetUid;
        _buttonState = buttonState;
        _searchState = _SearchState.found;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchState = _SearchState.initial;
        _isSearching = false;
      });
      showCustomDialog(
        context,
        title: 'エラー',
        message: toUserFriendlyError(e),
      );
    }
  }

  /// ボタン状態の判定
  Future<_ButtonState> _determineButtonState(
      String myUid, String targetUid) async {
    // 自分自身チェック
    if (myUid == targetUid) {
      return _ButtonState.isSelf;
    }

    // 既に友達チェック
    final friendDoc = await _firestore
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .doc(targetUid)
        .get();

    if (friendDoc.exists) {
      return _ButtonState.alreadyFriend;
    }

    // 自分→相手への申請済みチェック
    final sentQuery = await _firestore
        .collection('friend_requests')
        .where('fromUid', isEqualTo: myUid)
        .where('toUid', isEqualTo: targetUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (sentQuery.docs.isNotEmpty) {
      return _ButtonState.alreadySent;
    }

    // 相手→自分への申請受信チェック
    final receivedQuery = await _firestore
        .collection('friend_requests')
        .where('fromUid', isEqualTo: targetUid)
        .where('toUid', isEqualTo: myUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (receivedQuery.docs.isNotEmpty) {
      return _ButtonState.receivedRequest;
    }

    return _ButtonState.sendRequest;
  }

  /// 友達申請送信
  Future<void> _onSendRequest() async {
    if (_foundUser == null || _foundUserUid == null) return;

    final name = _foundUser!['name'] as String? ?? '';

    // 確認ダイアログ
    final confirmed = await showCustomConfirmDialog(
      context,
      title: '友達申請',
      message: '$nameさんに友達申請を送りますか？',
      confirmText: '送る',
    );

    if (!confirmed || !mounted) return;

    setState(() => _isSending = true);

    try {
      final myUid = _auth.currentUser!.uid;
      final myDoc = await _firestore.collection('users').doc(myUid).get();
      final myData = myDoc.data() ?? {};

      await _firestore.collection('friend_requests').add({
        'fromUid': myUid,
        'toUid': _foundUserUid,
        'fromName': myData['name'] ?? '',
        'fromIconUrl': myData['iconUrl'] ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _buttonState = _ButtonState.alreadySent;
        _isSending = false;
      });

      showCustomDialog(
        context,
        title: '送信完了',
        message: '友達申請を送りました',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      showCustomDialog(
        context,
        title: 'エラー',
        message: toUserFriendlyError(e),
      );
    }
  }

  /// 自分のIDをコピー
  Future<void> _onCopyMyId() async {
    if (_myUserId == null) return;
    await Clipboard.setData(ClipboardData(text: _myUserId!));
    if (!mounted) return;
    showCustomDialog(
      context,
      message: 'IDをコピーしました',
    );
  }
}

// 検索状態の列挙
enum _SearchState { initial, searching, found, notFound }

// ボタン状態の列挙
enum _ButtonState {
  sendRequest,
  alreadyFriend,
  alreadySent,
  receivedRequest,
  isSelf,
}
