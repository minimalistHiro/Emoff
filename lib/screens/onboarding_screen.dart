import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import 'main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _SlideData(
      icon: Icons.chat_bubble_outline,
      secondaryIcon: Icons.filter_alt_outlined,
      title: '感情を抜く、新しいコミュニケーション',
      description: '言い方に悩む時間をゼロに。\nEmoffがあなたの言葉をシンプルに整えます。',
    ),
    _SlideData(
      icon: Icons.edit_note,
      secondaryIcon: Icons.arrow_forward,
      thirdIcon: Icons.send,
      title: '思ったまま書いて、AIにおまかせ',
      description: 'メッセージを入力して「確認」を押すだけ。\nAIが要点を整理した文章に変換します。',
    ),
    _SlideData(
      icon: Icons.shield_outlined,
      secondaryIcon: null,
      title: 'あなたの原文は誰にも届きません',
      description: '相手に届くのはAIが整えた文章だけ。\n変換前のテキストは自動的に削除されます。',
    ),
  ];

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            // スキップボタン（右上）
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 16, right: 24),
                child: GestureDetector(
                  onTap: _goToHome,
                  child: const Text(
                    'スキップ',
                    style: TextStyle(
                      color: Color(0xFFA0A0A0),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

            // スライドコンテンツ
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return _SlideContent(slide: slide);
                },
              ),
            ),

            // ページインジケーター
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? const Color(0xFF00D4FF)
                          : const Color(0xFF555555),
                    ),
                  );
                }),
              ),
            ),

            // ボタン
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: CustomButton(
                text: _currentPage == _slides.length - 1 ? 'はじめる' : '次へ',
                onPressed: _currentPage == _slides.length - 1
                    ? _goToHome
                    : _nextPage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.icon,
    this.secondaryIcon,
    this.thirdIcon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final IconData? secondaryIcon;
  final IconData? thirdIcon;
  final String title;
  final String description;
}

class _SlideContent extends StatelessWidget {
  const _SlideContent({required this.slide});

  final _SlideData slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // イラスト領域（上部50%）
          Expanded(
            child: Center(
              child: _buildIllustration(),
            ),
          ),

          // テキスト領域
          Text(
            slide.title,
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            slide.description,
            style: const TextStyle(
              color: Color(0xFFA0A0A0),
              fontSize: 14,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    if (slide.thirdIcon != null) {
      // スライド2: 3ステップ図解
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _iconCircle(slide.icon),
          const SizedBox(width: 12),
          const Icon(
            Icons.arrow_forward,
            color: Color(0xFF555555),
            size: 20,
          ),
          const SizedBox(width: 12),
          _iconCircle(Icons.preview_outlined),
          const SizedBox(width: 12),
          const Icon(
            Icons.arrow_forward,
            color: Color(0xFF555555),
            size: 20,
          ),
          const SizedBox(width: 12),
          _iconCircle(slide.thirdIcon!),
        ],
      );
    }

    if (slide.secondaryIcon != null) {
      // スライド1: 2アイコン構成
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _iconCircle(slide.icon),
          const SizedBox(width: 20),
          _iconCircle(slide.secondaryIcon!),
        ],
      );
    }

    // スライド3: 単一アイコン
    return _iconCircle(slide.icon, size: 80);
  }

  Widget _iconCircle(IconData icon, {double size = 56}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1A1A1A),
        border: Border.all(
          color: const Color(0xFF00D4FF).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Icon(
        icon,
        color: const Color(0xFF00D4FF),
        size: size * 0.45,
      ),
    );
  }
}
