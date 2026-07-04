import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/pro_access_service.dart';

class SettingsLargeBannerAd extends StatefulWidget {
  const SettingsLargeBannerAd({super.key});

  @override
  State<SettingsLargeBannerAd> createState() => _SettingsLargeBannerAdState();
}

class _SettingsLargeBannerAdState extends State<SettingsLargeBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isProUnlocked = false;

  @override
  void initState() {
    super.initState();
    _loadProStateAndAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  String? get _adUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    }
    return null;
  }

  Future<void> _loadProStateAndAd() async {
    _isProUnlocked = await ProAccessService.isUnlocked();
    if (!mounted) {
      return;
    }

    if (_isProUnlocked) {
      setState(() {});
      return;
    }

    _loadAd();
  }

  void _loadAd() {
    final adUnitId = _adUnitId;
    if (adUnitId == null) {
      return;
    }

    final bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.largeBanner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Settings banner failed to load: ${error.message}');
        },
      ),
    );
    bannerAd.load();
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid || _isProUnlocked) {
      return const SizedBox.shrink();
    }

    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox();
    }

    return Center(
      child: Column(
        children: [
          SizedBox(height: 8),
          SizedBox(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        ],
      ),
    );
  }
}