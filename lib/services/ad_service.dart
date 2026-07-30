import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/ad_units.dart';
import '../main.dart';
import 'pro_access_service.dart';

class AdService {
  static AppOpenAd? _appOpenAd;
  static bool _isShowingAd = false;
  static DateTime? _lastAdShowedTime;
  static int _activeRingingScreensCount = 0;
  static bool shouldSuppressAppOpenAd = false;

  static InterstitialAd? _interstitialAd;
  static bool _isShowingInterstitialAd = false;

  static bool get isRingingScreenActive => _activeRingingScreensCount > 0;
  static bool get isInterstitialAdLoaded => _interstitialAd != null;

  /// Called when Pro is purchased to immediately discard any loaded ad.
  static void clearAd() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _interstitialAd?.dispose();
    _interstitialAd = null;
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

  static String get _appOpenAdUnitId => AdUnits.appOpenAdUnitId;

  static String get _interstitialAdUnitId => AdUnits.interstitialAdUnitId;

  static Future<bool> loadAppOpenAd() async {
    final isPro = await ProAccessService.isUnlocked();
    if (isPro) return false;

    if (_appOpenAd != null) return true;

    final adUnitId = _appOpenAdUnitId;
    if (adUnitId.isEmpty) return false;

    final now = DateTime.now();
    if (_lastAdShowedTime != null &&
        now.difference(_lastAdShowedTime!).inSeconds < 55) {
      debugPrint(
        'AdOpenApp: Suppressed showing ad because of 55s interval limit.',
      );
      return false;
    }

    final completer = Completer<bool>();

    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          debugPrint('AdOpenApp: Loaded successfully.');
          if (!completer.isCompleted) completer.complete(true);
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdOpenApp: Failed to load: $error');
          _appOpenAd = null;
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    return completer.future;
  }

  static Future<bool> loadInterstitialAd() async {
    final isPro = await ProAccessService.isUnlocked();
    if (isPro) return false;

    if (_interstitialAd != null) return true;

    final adUnitId = _interstitialAdUnitId;
    if (adUnitId.isEmpty) return false;

    final now = DateTime.now();
    if (_lastAdShowedTime != null &&
        now.difference(_lastAdShowedTime!).inSeconds < 55) {
      debugPrint(
        'AdInterstitial: Suppressed showing ad because of 55s interval limit.',
      );
      return false;
    }

    final completer = Completer<bool>();

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          debugPrint('AdInterstitial: Loaded successfully.');
          if (!completer.isCompleted) completer.complete(true);
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdInterstitial: Failed to load: $error');
          _interstitialAd = null;
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    return completer.future;
  }

  static Future<bool> _showLoadingDialogAndLoad(
    BuildContext context,
    Future<bool> Function() loadFunction,
  ) async {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xEE1C1C1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CupertinoActivityIndicator(
                  color: CupertinoColors.systemOrange,
                  radius: 12,
                ),
                const SizedBox(width: 14),
                DefaultTextStyle(
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 16,
                    //fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                  child: Text('3s cho quảng cáo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    bool loaded = false;
    try {
      loaded = await Future.any([
        loadFunction(),
        Future.delayed(const Duration(seconds: 3), () => false),
      ]);
    } catch (_) {
      loaded = false;
    }

    final navContext = navigatorKey.currentContext;
    if (navContext != null && Navigator.canPop(navContext)) {
      Navigator.pop(navContext);
    }

    return loaded;
  }

  static void showAppOpenAdIfAvailable() async {
    print('DEBUG: ABCABCABCabcabcabc');
    if (shouldSuppressAppOpenAd) {
      debugPrint('AdOpenApp: Suppressed due to shouldSuppressAppOpenAd flag.');
      shouldSuppressAppOpenAd = false; // Reset sau khi chặn
      return;
    }

    final isPro = await ProAccessService.isUnlocked();
    if (isPro) return;

    if (_isShowingAd) return;

    if (isRingingScreenActive) {
      debugPrint(
        'AdOpenApp: Suppressed showing ad because alarm/timer is ringing.',
      );
      return;
    }

    final now = DateTime.now();
    if (_lastAdShowedTime != null &&
        now.difference(_lastAdShowedTime!).inSeconds < 55) {
      debugPrint(
        'AdOpenApp: Suppressed showing ad because of 55s interval limit.',
      );
      return;
    }

    if (_appOpenAd == null) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        final loaded = await _showLoadingDialogAndLoad(context, loadAppOpenAd);
        if (!loaded || _appOpenAd == null) {
          return;
        }
      } else {
        return;
      }
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        _appOpenAd = null;
        _lastAdShowedTime = DateTime.now();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        _appOpenAd = null;
        loadAppOpenAd();
      },
    );

    _appOpenAd!.show();
  }

  static void showInterstitialAdIfAvailable() async {
    final isPro = await ProAccessService.isUnlocked();
    if (isPro) return;

    if (_isShowingInterstitialAd) return;

    final now = DateTime.now();
    if (_lastAdShowedTime != null &&
        now.difference(_lastAdShowedTime!).inSeconds < 55) {
      debugPrint(
        'AdInterstitial: Suppressed showing ad because of 55s interval limit.',
      );
      return;
    }

    if (_interstitialAd == null) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        final loaded = await _showLoadingDialogAndLoad(
          context,
          loadInterstitialAd,
        );
        if (!loaded || _interstitialAd == null) {
          return;
        }
      } else {
        return;
      }
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingInterstitialAd = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingInterstitialAd = false;
        _interstitialAd = null;
        shouldSuppressAppOpenAd = true;
        _lastAdShowedTime = DateTime.now();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingInterstitialAd = false;
        _interstitialAd = null;
        loadInterstitialAd();
      },
    );

    _interstitialAd!.show();
  }
}
