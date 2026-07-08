import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/username_screen.dart';
import 'services/dictionary_service.dart'; // ★ eklendi

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ★ SplashScreen gösterilirken kelime listesi arka planda yüklenir
  // GameScreen açıldığında zaten hazır olur, kasma olmaz
  DictionaryService.initialize();

  runApp(const WordCrushApp());
}

class WordCrushApp extends StatelessWidget {
  const WordCrushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Word Crush',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B3FA0),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/username': (context) => const UsernameScreen(),
      },
    );
  }
}