import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // --- 広告ユニットIDの管理 ---
  
  static String get bannerAdUnitId {
    if (kDebugMode) return 'ca-app-pub-3940256099942544/6300978111'; // Test ID
    return const String.fromEnvironment(
      'ZEN_SUDOKU_ADMOB_BANNER_ID',
      defaultValue: 'ca-app-pub-3940256099942544/6300978111',
    );
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) return 'ca-app-pub-3940256099942544/1033173712'; // Test ID
    return const String.fromEnvironment(
      'ZEN_SUDOKU_ADMOB_INTERSTITIAL_ID',
      defaultValue: 'ca-app-pub-3940256099942544/1033173712',
    );
  }

  static String get rewardHintAdUnitId {
    if (kDebugMode) return 'ca-app-pub-3940256099942544/5224354917'; // Test ID
    return const String.fromEnvironment(
      'ZEN_SUDOKU_ADMOB_REWARD_HINT_ID',
      defaultValue: 'ca-app-pub-3940256099942544/5224354917',
    );
  }

  static String get rewardLifeAdUnitId {
    if (kDebugMode) return 'ca-app-pub-3940256099942544/5224354917'; // Test ID
    return const String.fromEnvironment(
      'ZEN_SUDOKU_ADMOB_REWARD_LIFE_ID',
      defaultValue: 'ca-app-pub-3940256099942544/5224354917',
    );
  }

  // --- 初期化 ---

  static Future<void> init() async {
    await MobileAds.instance.initialize();
  }

  // --- バナー広告の作成 ---

  static BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('BannerAd failed to load: $error');
        },
      ),
    );
  }

  // --- インタースティシャル広告のロードと表示 ---

  static void showInterstitialAd({required VoidCallback onComplete}) {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              onComplete();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              onComplete();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          onComplete();
        },
      ),
    );
  }

  // --- リワード広告のロードと表示 ---

  static void showRewardedAd({
    required String adUnitId,
    required Function(RewardItem) onRewardEarned,
    required VoidCallback onClosed,
  }) {
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              onClosed();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              onClosed();
            },
          );
          ad.show(onUserEarnedReward: (ad, reward) => onRewardEarned(reward));
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
          onClosed();
        },
      ),
    );
  }
}
