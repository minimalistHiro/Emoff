import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/revenue_cat_service.dart';
import '../widgets/custom_loading_indicator.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _indicatorController;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _indicatorFade;

  @override
  void initState() {
    super.initState();

    // ロゴ + タグライン: FadeIn + ScaleUp (600ms)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    );
    _logoScale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    // ローディングインジケーター: FadeIn (300ms), ロゴ完了後に開始
    _indicatorController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _indicatorFade = CurvedAnimation(
      parent: _indicatorController,
      curve: Curves.easeOut,
    );

    _logoController.forward().then((_) {
      _indicatorController.forward();
    });

    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    final stopwatch = Stopwatch()..start();

    // 認証状態の判定
    bool isAuthenticated = false;
    try {
      final user = FirebaseAuth.instance.currentUser;
      isAuthenticated = user != null;
      if (isAuthenticated) {
        await RevenueCatService.init(user.uid);
      }
    } catch (_) {
      // エラー時はログイン画面へ（安全側に倒す）
      isAuthenticated = false;
    }

    // 最低表示時間 1.5秒を保証
    stopwatch.stop();
    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < 1500) {
      await Future.delayed(Duration(milliseconds: 1500 - elapsed));
    }

    if (!mounted) return;

    final destination = isAuthenticated
        ? const MainShell()
        : const LoginScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _indicatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // アンビエントグロー（シアンのぼかし円）
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D4FF).withOpacity(0.04),
                    blurRadius: 150,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          // メインコンテンツ
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ロゴ + タグライン
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'EMOFF',
                          style: TextStyle(
                            color: Color(0xFF00D4FF),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Emotion off.',
                          style: TextStyle(
                            color: Color(0xFFA0A0A0),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                // ローディングインジケーター
                FadeTransition(
                  opacity: _indicatorFade,
                  child: const CustomLoadingIndicator(size: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

