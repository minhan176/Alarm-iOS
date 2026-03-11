import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Centralized AdMob service for managing all ad types.
/// 
/// Ad placement strategy for maximum revenue:
/// - Banner ads: All 4 main tabs (World Clock, Alarm, Stopwatch, Timer) + Settings
/// - Interstitial ads: After saving/editing an alarm, after dismissing alarm ring
/// - App Open ads: On app resume from background
/// - NO ads on Alarm Ring / Timer Ring screens (critical UX)
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // ============================================================
  // TODO: Replace these test IDs with your real AdMob ad unit IDs
  // ============================================================

  // TODO: Replace these test IDs with your real AdMob ad unit IDs
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111'; // Test
  static const String interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712'; // Test
  static const String appOpenAdUnitId = 'ca-app-pub-3940256099942544/9257395921'; // Test
  static const String nativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110'; // Test

  // ============================================================
  // Initialization
  // ============================================================

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await MobileAds.instance.initialize();
    _isInitialized = true;
  }

  // ============================================================
  // Interstitial Ad
  // ============================================================

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  int _actionCount = 0;
  static const int _interstitialFrequency = 3; // Show every 3 actions

  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialAdReady = false;
              loadInterstitialAd(); // Preload next
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isInterstitialAdReady = false;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  /// Call this after user actions (save alarm, dismiss alarm, etc.)
  /// Shows interstitial every [_interstitialFrequency] actions.
  void showInterstitialAd() {
    _actionCount++;
    if (_actionCount % _interstitialFrequency == 0 && _isInterstitialAdReady) {
      _interstitialAd?.show();
    }
  }

  /// Force show interstitial (for important transitions)
  void forceShowInterstitialAd() {
    if (_isInterstitialAdReady) {
      _interstitialAd?.show();
    }
  }

  // ============================================================
  // App Open Ad
  // ============================================================

  AppOpenAd? _appOpenAd;
  bool _isAppOpenAdReady = false;
  DateTime? _appOpenAdLoadTime;

  void loadAppOpenAd() {
    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isAppOpenAdReady = true;
          _appOpenAdLoadTime = DateTime.now();
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isAppOpenAdReady = false;
              loadAppOpenAd(); // Preload next
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isAppOpenAdReady = false;
              loadAppOpenAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isAppOpenAdReady = false;
        },
      ),
    );
  }

  /// Show app open ad when user returns to app.
  /// Only shows if ad was loaded less than 4 hours ago.
  void showAppOpenAd() {
    if (!_isAppOpenAdReady) return;
    if (_appOpenAdLoadTime != null &&
        DateTime.now().difference(_appOpenAdLoadTime!).inHours >= 4) {
      // Ad is stale, reload
      _appOpenAd?.dispose();
      _isAppOpenAdReady = false;
      loadAppOpenAd();
      return;
    }
    _appOpenAd?.show();
  }

  // ============================================================
  // Dispose
  // ============================================================

  void dispose() {
    _interstitialAd?.dispose();
    _appOpenAd?.dispose();
  }
}

// ============================================================
// Banner Ad Widget - Reusable across screens
// ============================================================

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null) {
      _loadAd();
    }
  }

  void _loadAd() {
    final adSize = AdSize.banner;
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

// ============================================================
// Inline Adaptive Banner Ad Widget - for better revenue
// ============================================================

class AdaptiveBannerAdWidget extends StatefulWidget {
  const AdaptiveBannerAdWidget({super.key});

  @override
  State<AdaptiveBannerAdWidget> createState() => _AdaptiveBannerAdWidgetState();
}

class _AdaptiveBannerAdWidgetState extends State<AdaptiveBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null) {
      _loadAd();
    }
  }

  void _loadAd() async {
    final adSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.of(context).size.width.truncate(),
    );

    if (adSize == null) return;

    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
