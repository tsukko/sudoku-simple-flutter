import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'services/game_service.dart';
import 'services/settings_service.dart';
import 'services/ad_service.dart';
import 'theme/app_colors.dart';
import 'top_page.dart';
import 'l10n.dart';

// アプリ全体で共有する情報
class AppConfig {
  static String version = '';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 各種サービスの初期化（キャッシュ構築）
  await SettingsService.init();
  await GameService.init();
  await AdService.init();
  
  // バージョン情報の事前取得
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    AppConfig.version = packageInfo.version;
  } catch (e) {
    AppConfig.version = '1.0.1';
  }
  
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
      debugShowCheckedModeBanner: true,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.washi,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.tokiwa,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.tokiwa,
          surface: AppColors.washi,
        ),
      ),
      home: const TopPage(),
    );
  }
}
