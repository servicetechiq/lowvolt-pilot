import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionService {
  SubscriptionService._();
  static final instance = SubscriptionService._();

  static const monthlyId = 'lowvoltpilot_pro_monthly';
  static const annualId = 'lowvoltpilot_pro_annual';

  final InAppPurchase _iap = InAppPurchase.instance;
  final _isProController = StreamController<bool>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  bool _isPro = false;
  bool get isPro => _isPro;
  Stream<bool> get proChanges => _isProController.stream;

  Future<void> initialize() async {
    _purchaseSub ??= _iap.purchaseStream.listen(
      _handlePurchases,
      onError: (_) {},
    );
  }

  Future<bool> isStoreAvailable() => _iap.isAvailable();

  Future<List<ProductDetails>> loadProducts() async {
    final response = await _iap.queryProductDetails({monthlyId, annualId});
    return response.productDetails;
  }

  Future<void> buy(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() => _iap.restorePurchases();

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        if (purchase.productID == monthlyId || purchase.productID == annualId) {
          // TODO: Replace local trust with server-side receipt validation before production.
          _setPro(true);
        }
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  void _setPro(bool value) {
    if (_isPro == value) return;
    _isPro = value;
    _isProController.add(value);
  }

  Future<void> dispose() async {
    await _purchaseSub?.cancel();
    await _isProController.close();
  }
}
