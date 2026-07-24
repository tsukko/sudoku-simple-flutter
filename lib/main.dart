import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/ad_service.dart';
import 'top_page.dart';
import 'l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // AdMobの初期化
  await AdService.init();
  
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
      // 英語版の表示をテストしたい場合は以下のコメントを外してください
      // locale: const Locale('en'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TopPage(),
    );
  }
}
