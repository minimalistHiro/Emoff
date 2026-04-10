import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_dialog_helper.dart';
import '../widgets/custom_loading_indicator.dart';

/// プライバシーポリシー・利用規約の共通表示画面。
/// [title] と [assetPath] を切り替えて再利用する。
class LegalDocumentScreen extends StatefulWidget {
  final String title;
  final String assetPath;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  static const _backgroundColor = Color(0xFF0D0D0D);
  static const _textSecondary = Color(0xFFA0A0A0);
  static const _textDisabled = Color(0xFF555555);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _cyan = Color(0xFF00D4FF);

  late Future<String> _markdownFuture;

  @override
  void initState() {
    super.initState();
    _markdownFuture = _loadMarkdown();
  }

  Future<String> _loadMarkdown() async {
    return await rootBundle.loadString(widget.assetPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: CustomAppBar(titleText: widget.title),
      body: FutureBuilder<String>(
        future: _markdownFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CustomLoadingIndicator());
          }

          if (snapshot.hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                showCustomDialog(
                  context,
                  title: 'エラー',
                  message: 'コンテンツの読み込みに失敗しました',
                );
              }
            });
            return const SizedBox.shrink();
          }

          final markdown = snapshot.data ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: MarkdownBody(
              data: markdown,
              selectable: true,
              onTapLink: (text, href, title) {
                if (href != null) {
                  launchUrl(
                    Uri.parse(href),
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
              styleSheet: MarkdownStyleSheet(
                // h1
                h1: const TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                h1Padding: const EdgeInsets.only(top: 0, bottom: 12),
                // h2
                h2: const TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                h2Padding: const EdgeInsets.only(top: 24, bottom: 8),
                // h3
                h3: const TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                h3Padding: const EdgeInsets.only(top: 16, bottom: 4),
                // body text
                p: const TextStyle(
                  color: _textSecondary,
                  fontSize: 14,
                  height: 1.6,
                ),
                // list
                listBullet: const TextStyle(
                  color: _textDisabled,
                  fontSize: 14,
                ),
                listIndent: 16,
                // link
                a: const TextStyle(
                  color: _cyan,
                  fontSize: 14,
                  decoration: TextDecoration.none,
                ),
                // horizontal rule
                horizontalRuleDecoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: _textDisabled, width: 0.5),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
