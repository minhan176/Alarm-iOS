import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'pro_access_service.dart';

class AdService {
  static AppOpenAd? _appOpenAd;
  static bool _isShowingAd = false;
  static DateTime? _lastAdShowedTime;
  static int _activeRingingScreensCount = 0;

  static bool get isRingingScreenActive => _activeRingingScreensCount > 0;

  /// Called when Pro is purchased to immediately discard any loaded ad.
  static void clearAd() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }

  static void incrementRingingScreens() {
    _activeRingingScreensCount++;
    debugPrint(
      'AdOpenApp: Ringing screens count incremented to $_activeRingingScreensCount',
    );
  }

  static void decrementRingingScreens() {
    if (_activeRingingScreensCount > 0) {
      _activeRingingScreensCount--;
    }
    debugPrint(
      'AdOpenApp: Ringing screens count decremented to $_activeRingingScreensCount',
    );
  }

  // Google Test App Open Ad IDs
  static String get _appOpenAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/9257395921';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/5662855259';
    }
    return '';
  }

  static void loadAppOpenAd() async {
    final isPro = await ProAccessService.isUnlocked();
    if (isPro) return;

    final adUnitId = _appOpenAdUnitId;
    if (adUnitId.isEmpty) return;

    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          debugPrint('AdOpenApp: Loaded successfully.');
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdOpenApp: Failed to load: $error');
          _appOpenAd = null;
        },
      ),
    );
  }

  static void showAppOpenAdIfAvailable() async {
    final isPro = await ProAccessService.isUnlocked();
    if (isPro) return;

    if (_isShowingAd) return;

    if (_appOpenAd == null) {
      loadAppOpenAd();
      return;
    }

    if (isRingingScreenActive) {
      debugPrint(
        'AdOpenApp: Suppressed showing ad because alarm/timer is ringing.',
      );
      return;
    }

    final now = DateTime.now();
    if (_lastAdShowedTime != null &&
        now.difference(_lastAdShowedTime!).inSeconds < 30) {
      debugPrint(
        'AdOpenApp: Suppressed showing ad because of 30s interval limit.',
      );
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        _lastAdShowedTime = DateTime.now();
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        _appOpenAd = null;
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        _appOpenAd = null;
        loadAppOpenAd();
      },
    );

    _appOpenAd!.show();
  }
}
