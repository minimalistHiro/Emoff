import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/chat_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/custom_dialog_helper.dart';
import '../widgets/custom_loading_indicator.dart';
import '../widgets/custom_text_field.dart';
import 'group_management_screen.dart';
import 'subscription_screen.dart';

class TalkRoomScreen extends StatefulWidget {
  const TalkRoomScreen({
    super.key,
    required this.chatId,
    required this.chatType,
    this.otherUserName,
    this.groupName,
  });

  final String chatId;
  final String chatType; // 'direct' or 'group'
  final String? otherUserName;
  final String? groupName;

  @override
  State<TalkRoomScreen> createState() => _TalkRoomScreenState();
}

class _TalkRoomScreenState extends State<TalkRoomScreen>
    with SingleTickerProviderStateMixin {
  final _chatService = ChatService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  static const _backgroundColor = Color(0xFF0D0D0D);
  static const _surfaceColor = Color(0xFF1A1A1A);
  static const _elevateColor = Color(0xFF242424);
  static const _borderColor = Color(0xFF333333);
  static const _cyan = Color(0xFF00D4FF);
  static const _cyanLight = Color(0xFF7EEEFF);
  static const _tertiary = Color(0xFF5E5C78);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFFA0A0A0);
  static const _textDisabled = Color(0xFF555555);
  static const _sentBubbleColor = Color(0xFF1A3A4A);

  String _displayName = '';
  String _displaySubtitle = '';
  String? _otherUid;
  bool _isLoading = true;

  // Free上限管理
  static const _dailyLimit = 30;
  static const _warningThreshold = 25;
  int _dailySentCount = 0;
  bool _isLimitReached = false;
  final bool _isFreePlan = true; // MVP: 全ユーザーをFreeプランとして扱う
  bool _showWarningBanner = false;

  // トーン選択
  String _selectedTone = 'neutral';
  static const _toneData = [
    {
      'id': 'neutral',
      'name': 'ニュートラル',
      'short': '中立',
      'desc': '感情を排除し、事実だけを伝える標準トーン',
      'icon': Icons.balance,
      'previewLabel': 'NEUTRALIZING TONE',
      'badge': 'NEUTRALIZED',
    },
    {
      'id': 'business',
      'name': 'ビジネス敬語',
      'short': '敬語',
      'desc': '取引先・上司向けの丁寧なビジネス文体',
      'icon': Icons.business_center,
      'previewLabel': 'BUSINESS TONE',
      'badge': 'BUSINESS',
    },
    {
      'id': 'casual',
      'name': 'カジュアル',
      'short': '軽め',
      'desc': '親しい同僚向け。堅すぎない文体',
      'icon': Icons.sentiment_satisfied,
      'previewLabel': 'CASUAL TONE',
      'badge': 'CASUAL',
    },
    {
      'id': 'concise',
      'name': '簡潔',
      'short': '簡潔',
      'desc': '最小限の文字数で要点だけを伝える',
      'icon': Icons.short_text,
      'previewLabel': 'CONCISE TONE',
      'badge': 'CONCISE',
    },
  ];

  // AI変換プレビュートレイ用
  late final AnimationController _trayAnimController;
  late final Animation<Offset> _traySlideAnimation;
  bool _showPreviewTray = false;
  String _originalText = '';
  String _convertedText = '';
  bool _isConverting = false;
  bool _isSending = false;

  // トーク内検索
  bool _isSearchMode = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // ブロックユーザーフィルター
  Set<String> _blockedUserIds = {};
  StreamSubscription<Set<String>>? _blockedSubscription;

  @override
  void initState() {
    super.initState();
    _trayAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _traySlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _trayAnimController,
      curve: Curves.easeOutCubic,
    ));
    _loadChatInfo();
    _loadDailySentCount();
    _loadSelectedTone();
    // 既読を更新
    _chatService.updateLastRead(widget.chatId);
    // ブロックユーザー一覧を購読
    _blockedSubscription = _chatService.getBlockedUserIds().listen((ids) {
      if (mounted) setState(() => _blockedUserIds = ids);
    });
  }

  @override
  void dispose() {
    _blockedSubscription?.cancel();
    _trayAnimController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChatInfo() async {
    if (widget.chatType == 'group') {
      setState(() {
        _displayName = widget.groupName ?? 'グループ';
        _displaySubtitle = 'GROUP CHAT';
        _isLoading = false;
      });
      return;
    }

    // 1対1: 相手のユーザー情報を取得
    if (widget.otherUserName != null) {
      setState(() {
        _displayName = widget.otherUserName!;
        _displaySubtitle = 'DIRECT MESSAGE';
        _isLoading = false;
      });
    }

    final otherUser = await _chatService.getOtherUser(widget.chatId);
    if (otherUser != null && mounted) {
      setState(() {
        _displayName = otherUser['name'] as String? ?? _displayName;
        _otherUid = otherUser['uid'] as String?;
        _displaySubtitle = 'DIRECT MESSAGE';
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // --- Free上限管理 ---

  Future<void> _loadDailySentCount() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString('daily_sent_date') ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (savedDate != today) {
      // 日付が変わったらリセット
      await prefs.setInt('daily_sent_count', 0);
      await prefs.setString('daily_sent_date', today);
      if (mounted) {
        setState(() {
          _dailySentCount = 0;
          _isLimitReached = false;
        });
      }
    } else {
      final count = prefs.getInt('daily_sent_count') ?? 0;
      if (mounted) {
        setState(() {
          _dailySentCount = count;
          _isLimitReached = count >= _dailyLimit;
        });
      }
    }
  }

  Future<void> _incrementDailySentCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString('daily_sent_date', today);
    final newCount = _dailySentCount + 1;
    await prefs.setInt('daily_sent_count', newCount);

    if (!mounted) return;
    setState(() {
      _dailySentCount = newCount;
      _isLimitReached = newCount >= _dailyLimit;
    });

    // ステージ1: 残り5通警告
    if (newCount == _warningThreshold) {
      setState(() => _showWarningBanner = true);
    }

    // ステージ2: 上限到達
    if (newCount >= _dailyLimit) {
      _showLimitReachedDialog();
    }
  }

  // --- トーン選択管理 ---

  Future<void> _loadSelectedTone() async {
    final prefs = await SharedPreferences.getInstance();
    final tone = prefs.getString('tone_${widget.chatId}') ?? 'neutral';
    if (mounted) {
      setState(() => _selectedTone = tone);
    }
  }

  Future<void> _saveTone(String toneId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tone_${widget.chatId}', toneId);
    if (mounted) {
      setState(() => _selectedTone = toneId);
    }
  }

  Map<String, Object> get _currentTone =>
      _toneData.firstWhere((t) => t['id'] == _selectedTone,
          orElse: () => _toneData.first);

  void _showToneSelectorSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _elevateColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ハンドルバー
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _textDisabled,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '変換トーン',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'AIが変換する文体を選択できます。',
                  style: TextStyle(color: _textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ..._toneData.map((tone) {
                  final isSelected = tone['id'] == _selectedTone;
                  return GestureDetector(
                    onTap: () {
                      _saveTone(tone['id'] as String);
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (context.mounted) Navigator.pop(context);
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? _surfaceColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? const Border(
                                left: BorderSide(color: _cyan, width: 3),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            tone['icon'] as IconData,
                            size: 28,
                            color: isSelected ? _cyan : _textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tone['name'] as String,
                                  style: TextStyle(
                                    color: isSelected
                                        ? _textPrimary
                                        : _textSecondary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tone['desc'] as String,
                                  style: const TextStyle(
                                    color: _textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          isSelected
                              ? const Icon(Icons.check_circle,
                                  color: _cyan, size: 24)
                              : Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _textDisabled,
                                      width: 2,
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, size: 48, color: Color(0xFFFF4D4D)),
            SizedBox(height: 16),
            Text(
              '本日の送信上限に達しました',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Freeプランでは1日30通までメッセージを送信できます。明日0:00にリセットされます。',
              style: TextStyle(color: _textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          CustomButton(
            text: 'Proプランにアップグレード',
            variant: CustomButtonVariant.primary,
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SubscriptionScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          CustomButton(
            text: '明日まで待つ',
            variant: CustomButtonVariant.secondary,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// CONFIRMボタンタップ → AI変換プレビュートレイを表示
  Future<void> _onConfirmTap() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || (_isFreePlan && _isLimitReached)) return;

    setState(() {
      _originalText = text;
      _convertedText = '';
      _isConverting = true;
      _showPreviewTray = true;
    });
    _trayAnimController.forward();

    // MVP: AI変換モック（原文をそのまま返す）
    // TODO: 実際のAI API連携時にここを差し替え
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    setState(() {
      _convertedText = text; // モック: 原文と同じ
      _isConverting = false;
    });
  }

  /// REFINE AI → 再変換を実行
  Future<void> _refineAi() async {
    setState(() {
      _isConverting = true;
    });

    // MVP: モック再変換
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() {
      _convertedText = _originalText; // モック: 原文と同じ
      _isConverting = false;
    });
  }

  /// SEND NEUTRALIZED → 変換後テキストを送信
  Future<void> _sendNeutralized() async {
    if (_convertedText.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    await _chatService.sendMessage(
      chatId: widget.chatId,
      convertedText: _convertedText,
      originalText: _originalText,
      tone: _selectedTone,
    );
    await _chatService.updateLastRead(widget.chatId);

    // Free上限カウント
    if (_isFreePlan) {
      await _incrementDailySentCount();
    }

    _messageController.clear();
    await _closePreviewTray();

    if (mounted) {
      setState(() => _isSending = false);
    }
  }

  /// プレビュートレイを閉じる
  Future<void> _closePreviewTray() async {
    await _trayAnimController.reverse();
    if (mounted) {
      setState(() {
        _showPreviewTray = false;
        _originalText = '';
        _convertedText = '';
        _isConverting = false;
      });
    }
  }

  PreferredSizeWidget _buildSearchAppBar() {
    return CustomAppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: _cyan),
        onPressed: () {
          setState(() {
            _isSearchMode = false;
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
          hintText: 'メッセージを検索...',
          hintStyle: TextStyle(color: _textDisabled, fontSize: 16),
          border: InputBorder.none,
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value.trim().toLowerCase());
        },
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close, color: _textSecondary),
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
              });
            },
          ),
      ],
    );
  }

  // --- オプションメニュー ---

  void _showOptionsMenu() {
    final isGroup = widget.chatType == 'group';
    showModalBottomSheet(
      context: context,
      backgroundColor: _elevateColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // グループ管理（グループチャットのみ）
              if (isGroup)
                _menuItem(
                  icon: Icons.group,
                  text: 'グループ管理',
                  color: _textPrimary,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(this.context).push(
                      MaterialPageRoute(
                        builder: (_) => GroupManagementScreen(
                          chatId: widget.chatId,
                        ),
                      ),
                    );
                  },
                ),
              // 1対1チャットのみ: 通報・ブロック
              if (!isGroup) ...[
                _menuItem(
                  icon: Icons.flag,
                  text: '通報する',
                  color: const Color(0xFFFF4D4D),
                  onTap: () {
                    Navigator.pop(context);
                    _showReportSheet(targetUid: _getOtherUid());
                  },
                ),
                Container(height: 1, color: _borderColor),
                _menuItem(
                  icon: Icons.block,
                  text: 'ブロック',
                  color: const Color(0xFFFF4D4D),
                  onTap: () {
                    Navigator.pop(context);
                    _showBlockDialog();
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(color: color, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  String _getOtherUid() {
    // 1対1チャットの場合、相手のUIDを取得（簡易版: chatIdからの推定）
    // 実際の取得はchatドキュメントから
    return _otherUid ?? '';
  }

  // --- 通報フロー ---

  void _showReportSheet({required String targetUid, String? messageId}) {
    String? selectedReason;
    final detailController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _elevateColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final canSubmit = selectedReason != null &&
                (selectedReason != 'other' ||
                    detailController.text.trim().isNotEmpty);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ハンドルバー
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _textDisabled,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // タイトル
                      const Text(
                        '通報する',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '該当する理由を選択してください。通報内容は相手に通知されません。',
                        style: TextStyle(color: _textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      // 理由リスト
                      ..._reportReasons.map((r) => _buildReasonItem(
                            reason: r,
                            selectedReason: selectedReason,
                            onTap: () {
                              setSheetState(() => selectedReason = r['value'] as String?);
                            },
                          )),
                      // 補足入力欄（otherのみ）
                      if (selectedReason == 'other') ...[
                        const SizedBox(height: 12),
                        const Text(
                          '詳細を入力してください',
                          style:
                              TextStyle(color: _textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: detailController,
                          hintText: '具体的な内容を記入...',
                          maxLines: 4,
                          onChanged: (_) => setSheetState(() {}),
                        ),
                      ],
                      const SizedBox(height: 20),
                      // 送信ボタン
                      CustomButton(
                        text: '通報を送信',
                        variant: CustomButtonVariant.danger,
                        isLoading: isSubmitting,
                        onPressed: canSubmit
                            ? () async {
                                setSheetState(() => isSubmitting = true);
                                try {
                                  await _chatService.submitReport(
                                    targetUid: targetUid,
                                    reason: selectedReason!,
                                    detail: selectedReason == 'other'
                                        ? detailController.text.trim()
                                        : null,
                                    messageId: messageId,
                                    chatId: widget.chatId,
                                  );
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  _showReportCompleteDialog();
                                } catch (e) {
                                  setSheetState(() => isSubmitting = false);
                                  if (!context.mounted) return;
                                  showCustomDialog(
                                    context,
                                    title: 'エラー',
                                    message: toUserFriendlyError(e),
                                  );
                                }
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static final _reportReasons = [
    {'value': 'spam', 'text': 'スパム・迷惑行為', 'icon': Icons.block},
    {'value': 'harassment', 'text': '嫌がらせ・いじめ', 'icon': Icons.warning},
    {
      'value': 'inappropriate_content',
      'text': '不適切なコンテンツ',
      'icon': Icons.visibility_off,
    },
    {'value': 'other', 'text': 'その他', 'icon': Icons.more_horiz},
  ];

  Widget _buildReasonItem({
    required Map<String, dynamic> reason,
    required String? selectedReason,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedReason == reason['value'];
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            Icon(reason['icon'] as IconData, color: _textSecondary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                reason['text'] as String,
                style: const TextStyle(color: _textPrimary, fontSize: 16),
              ),
            ),
            // ラジオボタン
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _cyan : _textDisabled,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _cyan,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showReportCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 48, color: Color(0xFF00E676)),
            SizedBox(height: 16),
            Text(
              '通報を受け付けました',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '内容を確認のうえ、必要に応じて対応いたします。',
              style: TextStyle(color: _textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          CustomButton(
            text: '閉じる',
            variant: CustomButtonVariant.secondary,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // --- ブロック確認ダイアログ ---

  void _showBlockDialog() {
    final otherUid = _getOtherUid();
    if (otherUid.isEmpty) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isBlocking = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => CustomDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block, size: 48, color: Color(0xFFFF4D4D)),
                const SizedBox(height: 16),
                Text(
                  '$_displayNameさんをブロック',
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BlockInfoRow('相手からのメッセージが届かなくなります'),
                    SizedBox(height: 4),
                    _BlockInfoRow('友達リストからお互いに削除されます'),
                    SizedBox(height: 4),
                    _BlockInfoRow('ブロックしたことは相手に通知されません'),
                  ],
                ),
              ],
            ),
            actions: [
              CustomButton(
                text: 'ブロックする',
                variant: CustomButtonVariant.danger,
                isLoading: isBlocking,
                onPressed: isBlocking
                    ? null
                    : () async {
                        setDialogState(() => isBlocking = true);
                        try {
                          await _chatService.blockUser(otherUid);
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          // トーク一覧画面に戻る
                          if (mounted) {
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          }
                        } catch (e) {
                          setDialogState(() => isBlocking = false);
                          if (!dialogContext.mounted) return;
                          showCustomDialog(
                            dialogContext,
                            title: 'エラー',
                            message: toUserFriendlyError(e),
                          );
                        }
                      },
              ),
              const SizedBox(height: 8),
              CustomButton(
                text: 'キャンセル',
                variant: CustomButtonVariant.secondary,
                onPressed: isBlocking
                    ? null
                    : () => Navigator.pop(dialogContext),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              // 区切り線
              Container(height: 1, color: _elevateColor),
              // メッセージキャンバス
              Expanded(child: _buildMessageCanvas()),
              // Free上限: 残り5通警告バナー
              if (_showWarningBanner && _isFreePlan)
                _buildWarningBanner(),
              // Free上限: 残数カウンター
              if (_isFreePlan) _buildRemainingCounter(),
              // インプットドック
              _isLimitReached && _isFreePlan
                  ? _buildLockedInputDock()
                  : _buildInputDock(),
            ],
          ),
          // AI変換プレビュートレイ（オーバーレイ）
          if (_showPreviewTray) ...[
            // 半透明オーバーレイ
            GestureDetector(
              onTap: _closePreviewTray,
              child: FadeTransition(
                opacity: _trayAnimController,
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
            ),
            // プレビュートレイ本体
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: _traySlideAnimation,
                child: _buildPreviewTray(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_isSearchMode) {
      return _buildSearchAppBar();
    }
    return CustomAppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: _cyan),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: _isLoading
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _displayName,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Manrope',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _displaySubtitle,
                  style: const TextStyle(
                    color: _textDisabled,
                    fontSize: 10,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: _cyan),
          onPressed: () {
            setState(() => _isSearchMode = true);
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: _cyan),
          onPressed: _showOptionsMenu,
        ),
      ],
    );
  }

  Widget _buildMessageCanvas() {
    final uid = _chatService.currentUid;
    if (uid == null) {
      return const Center(child: CustomLoadingIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessages(widget.chatId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'メッセージの読み込みに失敗しました',
              style: TextStyle(color: _textSecondary),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CustomLoadingIndicator());
        }

        var docs = snapshot.data?.docs ?? [];

        // ブロックユーザーのメッセージを非表示
        if (_blockedUserIds.isNotEmpty) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final senderId = data['senderId'] as String? ?? '';
            return !_blockedUserIds.contains(senderId);
          }).toList();
        }

        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        // 検索フィルター
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final text =
                (data['convertedText'] as String? ?? '').toLowerCase();
            return text.contains(_searchQuery);
          }).toList();

          if (docs.isEmpty) {
            return Center(
              child: Text(
                '「$_searchQuery」に一致するメッセージはありません',
                style: const TextStyle(color: _textSecondary, fontSize: 14),
              ),
            );
          }
        }

        // メッセージは descending で取得しているので、ListView.builder で reverse 表示
        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final isMe = data['senderId'] == uid;

            // 日付インジケーターの表示判定
            Widget? dateIndicator;
            final currentDate = _extractDate(data['createdAt'] as Timestamp?);
            if (index == docs.length - 1) {
              // 最古のメッセージには必ず日付を表示
              dateIndicator = _buildDateIndicator(currentDate);
            } else {
              final nextData =
                  docs[index + 1].data() as Map<String, dynamic>;
              final nextDate =
                  _extractDate(nextData['createdAt'] as Timestamp?);
              if (currentDate != null &&
                  nextDate != null &&
                  !_isSameDay(currentDate, nextDate)) {
                dateIndicator = _buildDateIndicator(currentDate);
              }
            }

            final messageId = docs[index].id;
            return Column(
              children: [
                if (dateIndicator != null) dateIndicator,
                _buildMessageBubble(data, isMe, messageId),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 48, color: _textDisabled),
          const SizedBox(height: 16),
          Text(
            '${widget.chatType == 'group' ? 'グループ' : ''}チャットを始めましょう',
            style: const TextStyle(color: _textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'メッセージを入力して送信してください',
            style: TextStyle(color: _textDisabled, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDateIndicator(DateTime? date) {
    if (date == null) return const SizedBox.shrink();

    final text = _formatDateIndicator(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
      Map<String, dynamic> data, bool isMe, String messageId) {
    final text = data['convertedText'] as String? ?? '';
    final createdAt = data['createdAt'] as Timestamp?;
    final senderName = data['senderName'] as String? ?? '';
    final senderId = data['senderId'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // グループチャットの場合、相手のメッセージに送信者名を表示
          if (!isMe && widget.chatType == 'group')
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                senderName,
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          // バブル（受信メッセージは長押しで通報メニュー）
          GestureDetector(
            onLongPress: isMe
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    _showReportSheet(
                      targetUid: senderId,
                      messageId: messageId,
                    );
                  },
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isMe ? _sentBubbleColor : _elevateColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isMe
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          // タイムスタンプ + NEUTRALIZEDバッジ
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                // トーンバッジ（送信メッセージのみ）
                if (isMe) ...[
                  Builder(builder: (context) {
                    final msgTone = data['tone'] as String? ?? 'neutral';
                    final badgeText = _toneData
                        .firstWhere((t) => t['id'] == msgTone,
                            orElse: () => _toneData.first)['badge'] as String;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _tertiary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 6),
                ],
                // タイムスタンプ
                if (createdAt != null)
                  Text(
                    _formatTimestamp(createdAt),
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemainingCounter() {
    final remaining = (_dailyLimit - _dailySentCount).clamp(0, _dailyLimit);
    final progress = _dailySentCount / _dailyLimit;
    Color barColor;
    if (remaining <= 0) {
      barColor = const Color(0xFFFF4D4D);
    } else if (remaining <= 5) {
      barColor = const Color(0xFFFFB800);
    } else {
      barColor = _cyan;
    }

    return Container(
      color: _backgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '残り $remaining 通',
                style: const TextStyle(color: _textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 2,
              backgroundColor: _elevateColor,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB800).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info, color: Color(0xFFFFB800), size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '本日の残り送信回数はあと5通です',
              style: TextStyle(color: Color(0xFFFFB800), fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showWarningBanner = false),
            child: const Icon(Icons.close, color: _textSecondary, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedInputDock() {
    return Container(
      decoration: const BoxDecoration(
        color: _backgroundColor,
        border: Border(
          top: BorderSide(color: _elevateColor, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            children: [
              // ロック状態の入力エリア
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _borderColor, width: 1),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Text(
                  '本日の送信上限に達しました',
                  style: TextStyle(color: _textDisabled, fontSize: 15),
                ),
              ),
              const SizedBox(height: 8),
              // アップグレードリンク
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Proプランで無制限に →',
                  style: TextStyle(
                    color: _cyan,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: _cyan,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputDock() {
    return Container(
      decoration: const BoxDecoration(
        color: _backgroundColor,
        border: Border(
          top: BorderSide(color: _elevateColor, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 添付ファイルアイコン
              IconButton(
                icon: const Icon(Icons.attach_file, color: _textSecondary),
                onPressed: () {
                  // TODO: ファイル添付メニュー
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
              ),
              const SizedBox(width: 8),
              // テキスト入力フィールド
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _borderColor, width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 15,
                          ),
                          cursorColor: _cyan,
                          maxLines: 5,
                          minLines: 1,
                          decoration: const InputDecoration(
                            hintText: 'Draft your message...',
                            hintStyle: TextStyle(
                              color: _textDisabled,
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      // マイクアイコン
                      const Padding(
                        padding: EdgeInsets.only(right: 8, bottom: 6),
                        child: Icon(
                          Icons.mic,
                          color: _textDisabled,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // トーン選択チップ（Pro以上のみ）
              if (!_isFreePlan) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showToneSelectorSheet,
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: _surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _cyan.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tune, size: 16, color: _cyan),
                        const SizedBox(width: 4),
                        Text(
                          _currentTone['short'] as String,
                          style: const TextStyle(
                            color: _cyan,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              // CONFIRMボタン
              GestureDetector(
                onTap: _messageController.text.trim().isEmpty
                    ? null
                    : _onConfirmTap,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: _messageController.text.trim().isEmpty
                        ? _borderColor
                        : _cyan,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CONFIRM',
                        style: TextStyle(
                          color: _messageController.text.trim().isEmpty
                              ? _textDisabled
                              : _backgroundColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: _messageController.text.trim().isEmpty
                            ? _textDisabled
                            : _backgroundColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewTray() {
    return SafeArea(
      top: false,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        margin: EdgeInsets.only(
          left: MediaQuery.of(context).size.width * 0.025,
          right: MediaQuery.of(context).size.width * 0.025,
          bottom: 8,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _elevateColor.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダー行
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: _tertiary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI PREVIEW: ${_currentTone['previewLabel']}',
                    style: const TextStyle(
                      color: _cyanLight,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _closePreviewTray,
                  child: const Icon(
                    Icons.close,
                    color: _textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 比較エリア（2カラム）
            if (_isConverting)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CustomLoadingIndicator(),
              )
            else
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左: Original Draft
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ORIGINAL DRAFT',
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 9,
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _originalText,
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 縦の区切り線
                    Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: _elevateColor,
                    ),
                    // 右: Emoff-ed Version
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EMOFF-ED VERSION',
                            style: TextStyle(
                              color: _tertiary,
                              fontSize: 9,
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _convertedText,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            // 区切り線
            Container(height: 1, color: _elevateColor),
            const SizedBox(height: 16),
            // アクションボタン行
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // REFINE AI
                GestureDetector(
                  onTap: _isConverting ? null : _refineAi,
                  child: Text(
                    'REFINE AI',
                    style: TextStyle(
                      color: _isConverting ? _textDisabled : _cyan,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // SEND NEUTRALIZED
                GestureDetector(
                  onTap: (_isConverting || _isSending) ? null : _sendNeutralized,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: (_isConverting || _isSending)
                          ? _borderColor
                          : _cyan,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SEND NEUTRALIZED',
                          style: TextStyle(
                            color: (_isConverting || _isSending)
                                ? _textDisabled
                                : _backgroundColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.send,
                          size: 14,
                          color: (_isConverting || _isSending)
                              ? _textDisabled
                              : _backgroundColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- ヘルパー ---

  DateTime? _extractDate(Timestamp? timestamp) {
    if (timestamp == null) return null;
    return timestamp.toDate();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateIndicator(DateTime date) {
    const days = [
      'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY',
      'FRIDAY', 'SATURDAY', 'SUNDAY',
    ];
    const months = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
    ];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }
}

/// ブロック確認ダイアログの説明行
class _BlockInfoRow extends StatelessWidget {
  const _BlockInfoRow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 14)),
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
