import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'top_page.dart';
import 'l10n.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 画面の回転を固定（縦向きのみ）
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: L10n.appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TopPage(),
    );
  }
}
