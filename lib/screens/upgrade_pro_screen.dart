import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../l10n/app_localizations.dart';
import '../services/pro_access_service.dart';

class UpgradeProScreen extends StatefulWidget {
  const UpgradeProScreen({super.key});

  @override
  State<UpgradeProScreen> createState() => _UpgradeProScreenState();
}

class _UpgradeProScreenState extends State<UpgradeProScreen> {
  static const String _productId = 'pro_lifetime';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  List<ProductDetails> _productDetails = [];
  bool _isAvailable = false;
  bool _isLoading = true;
  bool _isPurchasing = false;
  bool _isProUnlocked = false;
  String _priceText = '₫99.000';
  String? _statusMessage;

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
          _statusMessage = 'Không thể mở luồng mua hàng.';
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
        _statusMessage = 'Mua hàng trong ứng dụng hiện không khả dụng trên thiết bị này.';
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
      if (_productDetails.isNotEmpty) {
        _priceText = _productDetails.first.price;
      }
      if (response.notFoundIDs.isNotEmpty) {
        _statusMessage = 'Không tìm thấy gói Pro trong cửa hàng. Hãy kiểm tra product ID.';
      }
      if (response.error != null) {
        _statusMessage = response.error!.message;
      }
    });
  }

  Future<void> _buyPro() async {
    if (_isLoading || _isPurchasing || _isProUnlocked) {
      return;
    }

    if (!_isAvailable || _productDetails.isEmpty) {
      _showInfoDialog(
        title: AppLocalizations.of(context).upgradePro,
        content: 'Hiện chưa thể mua Pro. Kiểm tra product ID và trạng thái cửa hàng.',
      );
      return;
    }

    setState(() {
      _isPurchasing = true;
      _statusMessage = null;
    });

    final product = _productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: product);

    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> _restorePurchases() async {
    if (_isLoading || _isPurchasing) {
      return;
    }

    setState(() {
      _isPurchasing = true;
      _statusMessage = null;
    });

    await _inAppPurchase.restorePurchases();
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          if (mounted) {
            setState(() {
              _isPurchasing = true;
              _statusMessage = 'Đang xử lý giao dịch...';
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
              _statusMessage = purchaseDetails.error?.message ?? 'Giao dịch thất bại.';
            });
          }
          break;
        case PurchaseStatus.canceled:
          if (mounted) {
            setState(() {
              _isPurchasing = false;
              _statusMessage = 'Giao dịch đã bị hủy.';
            });
          }
          break;
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.productID != _productId) {
      return;
    }

    await ProAccessService.setUnlocked(true);

    if (!mounted) {
      return;
    }

    setState(() {
      _isProUnlocked = true;
      _isPurchasing = false;
      _statusMessage = 'Pro đã được mở khóa vĩnh viễn trên thiết bị này.';
    });

    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(context).upgradePro),
        content: const Text('Pro đã được mở khóa vĩnh viễn trên thiết bị này.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context).ok),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog({required String title, required String content}) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF0F0F12),
      child: SafeArea(
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
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 0,
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Icon(
                          CupertinoIcons.chevron_left,
                          color: CupertinoColors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        localizations.upgradePro,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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
                              color: CupertinoColors.systemOrange.withOpacity(0.18),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                CupertinoIcons.star_circle_fill,
                                color: CupertinoColors.systemOrange,
                                size: 42,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                localizations.proIntro,
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 22,
                                  height: 1.25,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                localizations.proLifetimeNote,
                                style: const TextStyle(
                                  color: CupertinoColors.systemGrey,
                                  fontSize: 14,
                                  height: 1.4,
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    localizations.proPriceLabel,
                                    style: const TextStyle(
                                      color: CupertinoColors.systemGrey,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _priceText,
                                    style: const TextStyle(
                                      color: CupertinoColors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemGreen.withOpacity(0.16),
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
                        if (_statusMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              _statusMessage!,
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        CupertinoButton.filled(
                          borderRadius: BorderRadius.circular(18),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          onPressed: _isPurchasing || _isProUnlocked ? null : _buyPro,
                          child: _isPurchasing
                              ? const CupertinoActivityIndicator()
                              : Text(
                                  _isProUnlocked ? 'Đã mở Pro' : localizations.proBuyNow,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _isPurchasing ? null : _restorePurchases,
                          child: Text(
                            'Khôi phục mua hàng',
                            style: TextStyle(
                              color: CupertinoColors.systemOrange.withOpacity(_isPurchasing ? 0.4 : 1),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Sau khi mua, Pro sẽ được mở vĩnh viễn trên thiết bị này. Nếu đăng nhập lại cùng tài khoản cửa hàng, bạn có thể khôi phục mua hàng.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
      ),
    );
  }
}
