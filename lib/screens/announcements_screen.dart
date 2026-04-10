import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_dialog_helper.dart';
import '../widgets/custom_loading_indicator.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  static const _backgroundColor = Color(0xFF0D0D0D);
  static const _cardColor = Color(0xFF1A1A1A);
  static const _cyan = Color(0xFF00D4FF);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFFA0A0A0);
  static const _textDisabled = Color(0xFF555555);

  List<QueryDocumentSnapshot>? _announcements;
  bool _isLoading = true;
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .get();
      if (!mounted) return;
      setState(() {
        _announcements = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      await showCustomDialog(
        context,
        title: 'エラー',
        message: '通信エラーが発生しました',
      );
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return '${date.year}年${date.month}月${date.day}日';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: const CustomAppBar(
        titleText: 'Announcements',
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CustomLoadingIndicator());
    }

    if (_announcements == null || _announcements!.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: _cyan,
      backgroundColor: _cardColor,
      onRefresh: _fetchAnnouncements,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: _announcements!.length,
        itemBuilder: (context, index) {
          return _buildAnnouncementCard(_announcements![index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: _textDisabled,
          ),
          SizedBox(height: 16),
          Text(
            'お知らせはありません',
            style: TextStyle(
              color: _textDisabled,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] as String? ?? '';
    final body = data['body'] as String? ?? '';
    final createdAt = data['createdAt'] as Timestamp?;
    final isExpanded = _expandedIds.contains(doc.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              title,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // Date
            Text(
              _formatDate(createdAt),
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            // Body
            _buildBodyText(doc.id, body, isExpanded),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyText(String docId, String body, bool isExpanded) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(
          text: body,
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          maxLines: 3,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final exceedsMaxLines = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Text(
                body,
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
                maxLines: isExpanded ? null : 3,
                overflow: isExpanded ? null : TextOverflow.ellipsis,
              ),
            ),
            if (exceedsMaxLines) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedIds.remove(docId);
                    } else {
                      _expandedIds.add(docId);
                    }
                  });
                },
                child: Text(
                  isExpanded ? '閉じる' : 'もっと見る',
                  style: const TextStyle(
                    color: _cyan,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
