import 'dart:async';

import 'package:clock_os_26/widgets/custom_buttons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/ad_service.dart';
import '../services/pro_access_service.dart';
import '../providers/settings_provider.dart';
import '../utils/alarm_toast.dart';

class UpgradeProScreen extends StatefulWidget {
  const UpgradeProScreen({super.key});

  @override
  State<UpgradeProScreen> createState() => _UpgradeProScreenState();
}

class _UpgradeProScreenState extends State<UpgradeProScreen> {
  static const String _productId = 'com.oaptech.clock_unlockpro';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  List<ProductDetails> _productDetails = [];
  bool _isAvailable = false;
  bool _isLoading = true;
  bool _isPurchasing = false;
  bool _isProUnlocked = false;

  ProductDetails? get _product =>
      _productDetails.isNotEmpty ? _productDetails.first : null;

  @override
  void initState() {
    super.initState();
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdated,
      onDone: () {
        _purchaseSubscription?.cancel();
      },
      onError: (Object error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isPurchasing = false;
        });
      },
    );
    _initializeStore();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeStore() async {
    final unlocked = await ProAccessService.isUnlocked();
    final available = await _inAppPurchase.isAvailable();

    if (!mounted) {
      return;
    }

    if (!available) {
      setState(() {
        _isAvailable = false;
        _isLoading = false;
        _isProUnlocked = unlocked;
      });
      return;
    }

    final response = await _inAppPurchase.queryProductDetails({_productId});
    if (!mounted) {
      return;
    }

    setState(() {
      _isAvailable = true;
      _isLoading = false;
      _isProUnlocked = unlocked;
      _productDetails = response.productDetails;
      if (response.notFoundIDs.isNotEmpty) {}
      if (response.error != null) {}
    });
  }

  Future<void> _buyPro() async {
    if (_isLoading || _isPurchasing || _isProUnlocked) {
      return;
    }

    if (!_isAvailable || _productDetails.isEmpty) {
      return;
    }

    setState(() {
      _isPurchasing = true;
    });

    final product = _product;
    if (product == null) {
      setState(() {
        _isPurchasing = false;
      });
      return;
    }

    final purchaseParam = PurchaseParam(productDetails: product);

    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> _restorePurchases() async {
    if (_isLoading || _isPurchasing) {
      return;
    }

    setState(() {
      _isPurchasing = true;
    });
    await _inAppPurchase.restorePurchases();
    Future.delayed(const Duration(seconds: 5), () {
      if (_isPurchasing) {
        setState(() {
          _isPurchasing = false;
        });
        AlarmToast.showAlarmToast(
          null,
          context,
          customMessage: 'Không tìm thấy giao dịch mua nào',
          bottom: 70,
        );
      }
    });
  }

  Future<void> _onPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          if (mounted) {
            setState(() {
              _isPurchasing = true;
            });
          }
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _handleSuccessfulPurchase(purchaseDetails);
          break;
        case PurchaseStatus.error:
          if (mounted) {
            setState(() {
              _isPurchasing = false;
            });
          }
          break;
        case PurchaseStatus.canceled:
          if (mounted) {
            setState(() {
              _isPurchasing = false;
            });
          }
          break;
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(
    PurchaseDetails purchaseDetails,
  ) async {
    if (purchaseDetails.productID != _productId) {
      return;
    }

    await ProAccessService.setUnlocked(true);
    AdService.clearAd();

    if (!mounted) {
      return;
    }

    Provider.of<SettingsProvider>(context, listen: false).setProUnlocked(true);

    setState(() {
      _isProUnlocked = true;
      _isPurchasing = false;
    });

    AlarmToast.showAlarmToast(
      null,
      context,
      customMessage: 'Đã kích hoạt Pro thành công!',
    );
    Navigator.of(context).pop();
  }

  void _handleSuccessfulPurchase2() {
    // if (purchaseDetails.productID != _productId) {
    //   return;
    // }

    // await ProAccessService.setUnlocked(true);

    if (!mounted) {
      return;
    }

    Provider.of<SettingsProvider>(context, listen: false).setProUnlocked(true);

    setState(() {
      _isProUnlocked = true;
      _isPurchasing = false;
    });

    AlarmToast.showAlarmToast(
      null,
      context,
      customMessage: 'Đã kích hoạt Pro thành công!',
      bottom: 70,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final product = _product;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF0F0F12),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    CupertinoColors.systemOrange.withOpacity(0.24),
                    CupertinoColors.systemOrange.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -70,
            left: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    CupertinoColors.systemYellow.withOpacity(0.16),
                    CupertinoColors.systemYellow.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                CustomNavBar(
                  backgroundColor: Colors.transparent,
                  leading: NavIconButton(
                    icon: CupertinoIcons.xmark,
                    iconColor: CupertinoColors.white,
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true).pop(),
                  ),
                  middle: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      localizations.upgradePro,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E).withOpacity(0.92),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: CupertinoColors.systemOrange.withOpacity(
                                0.18,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.workspace_premium,
                                color: CupertinoColors.systemOrange,
                                size: 42,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                localizations.proIntro,
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 18,
                                  height: 1.25,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                localizations.proLifetimeNote,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: CupertinoColors.systemOrange,
                                  fontSize: 14,
                                  height: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E).withOpacity(0.92),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (_isLoading)
                                const CupertinoActivityIndicator()
                              else
                                Text(
                                  product?.price ?? '--',
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemGreen
                                      .withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  '1 lần • mãi mãi',
                                  style: TextStyle(
                                    color: CupertinoColors.systemGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        CupertinoButton.filled(
                          borderRadius: BorderRadius.circular(18),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          onPressed: _isPurchasing || _isProUnlocked
                              ? null
                              : _buyPro,
                          child: _isPurchasing
                              ? const CupertinoActivityIndicator()
                              : Text(
                                  localizations.proBuyNow,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                        CupertinoButton.filled(
                          borderRadius: BorderRadius.circular(18),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          onPressed: _handleSuccessfulPurchase2,
                          child: _isPurchasing
                              ? const CupertinoActivityIndicator()
                              : Text(
                                  'proBuyNow',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                        //Spacer(),
                        const SizedBox(height: 24),
                        const Text(
                          'Sau khi mua, Pro sẽ được mở vĩnh viễn trên thiết bị này. Nếu đăng nhập lại cùng tài khoản cửa hàng đã dùng để mua ở thiết bị khác, bạn chỉ cần nhấn Khôi phục mua hàng.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _isPurchasing ? null : _restorePurchases,
                          child: Text(
                            'Khôi phục mua hàng',
                            style: TextStyle(
                              color: CupertinoColors.systemOrange.withOpacity(
                                _isPurchasing ? 0.4 : 1,
                              ),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Color(0x66000000),
                  child: Center(child: CupertinoActivityIndicator()),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
