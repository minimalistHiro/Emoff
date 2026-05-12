import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'custom_button.dart';
import 'custom_dialog.dart';
import 'custom_dialog_helper.dart';
import 'custom_text_field.dart';

const _elevateColor = Color(0xFF242424);
const _textPrimary = Color(0xFFFFFFFF);
const _textSecondary = Color(0xFFA0A0A0);
const _textDisabled = Color(0xFF555555);
const _cyan = Color(0xFF00D4FF);

const _reportReasons = [
  {'value': 'spam', 'text': 'スパム・迷惑行為', 'icon': Icons.block},
  {'value': 'harassment', 'text': '嫌がらせ・いじめ', 'icon': Icons.warning},
  {
    'value': 'inappropriate_content',
    'text': '不適切なコンテンツ',
    'icon': Icons.visibility_off,
  },
  {'value': 'other', 'text': 'その他', 'icon': Icons.more_horiz},
];

/// 通報ボトムシートを表示する
///
/// [targetUid] 通報対象のユーザーUID
/// [messageId] 通報対象のメッセージID（メッセージ通報の場合）
/// [chatId] 通報元のチャットID（チャットからの通報の場合）
void showReportSheet(
  BuildContext context, {
  required String targetUid,
  String? messageId,
  String? chatId,
}) {
  final chatService = ChatService();
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
                            setSheetState(
                                () => selectedReason = r['value'] as String?);
                          },
                        )),
                    // 補足入力欄（otherのみ）
                    if (selectedReason == 'other') ...[
                      const SizedBox(height: 12),
                      const Text(
                        '詳細を入力してください',
                        style: TextStyle(color: _textSecondary, fontSize: 13),
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
                                await chatService.submitReport(
                                  targetUid: targetUid,
                                  reason: selectedReason!,
                                  detail: selectedReason == 'other'
                                      ? detailController.text.trim()
                                      : null,
                                  messageId: messageId,
                                  chatId: chatId,
                                );
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                _showReportCompleteDialog(context);
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

void _showReportCompleteDialog(BuildContext context) {
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
