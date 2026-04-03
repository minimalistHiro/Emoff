import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const _backgroundColor = Color(0xFF0D0D0D);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emoff',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: _backgroundColor,
        colorScheme: const ColorScheme.dark(
          surface: _backgroundColor,
          primary: Color(0xFF00D4FF),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
