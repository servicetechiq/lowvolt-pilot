import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum RestorePurchaseStatus {
  found,
  noneFound,
  storeUnavailable,
  alreadyRunning,
  error,
}

class RestorePurchaseResult {
  const RestorePurchaseResult(this.status, this.message);

  final RestorePurchaseStatus status;
  final String message;
}

class SubscriptionService {
  SubscriptionService._();
  static final instance = SubscriptionService._();

  static const monthlyId = 'lowvoltpilot_pro_monthly';
  static const annualId = 'lowvoltpilot_pro_annual';
  static const productKey = 'lowvolt_pilot';

  final InAppPurchase _iap = InAppPurchase.instance;
  final _isProController = StreamController<bool>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  Completer<RestorePurchaseResult>? _restoreCompleter;
  Timer? _restoreTimer;

  bool _isPro = false;
  bool _restoring = false;
  String? _entitlementSource;

  bool get isPro => _isPro;
  bool get restoring => _restoring;
  String? get entitlementSource => _entitlementSource;
  Stream<bool> get proChanges => _isProController.stream;

  Future<void> initialize() async {
    _purchaseSub ??= _iap.purchaseStream.listen(
      _handlePurchases,
      onError: (Object error) {
        _completeRestore(
          const RestorePurchaseResult(
            RestorePurchaseStatus.error,
            'Google Play returned an error while checking purchases.',
          ),
        );
      },
    );

    await refreshServerEntitlement();
  }

  Future<void> refreshServerEntitlement() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      _entitlementSource = null;
      _setPro(false);
      return;
    }

    try {
      final row = await Supabase.instance.client
          .from('entitlements')
          .select('tier,status,source,expires_at')
          .eq('user_id', user.id)
          .eq('product_key', productKey)
          .maybeSingle();

      if (row == null) {
        _entitlementSource = null;
        _setPro(false);
        return;
      }

      final status = row['status']?.toString();
      final expiresRaw = row['expires_at']?.toString();
      final expiresAt = expiresRaw == null
          ? null
          : DateTime.tryParse(expiresRaw)?.toUtc();

      final statusAllowsAccess =
          status == 'active' || status == 'trialing' || status == 'grace';
      final notExpired =
          expiresAt == null || expiresAt.isAfter(DateTime.now().toUtc());

      if (statusAllowsAccess && notExpired) {
        _entitlementSource = row['source']?.toString();
        _setPro(true);
      } else {
        _entitlementSource = row['source']?.toString();
        _setPro(false);
      }
    } catch (_) {
      // Do not grant Pro on an entitlement lookup failure.
      _entitlementSource = null;
      _setPro(false);
    }
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

  Future<RestorePurchaseResult> restorePurchases({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (_restoring) {
      return const RestorePurchaseResult(
        RestorePurchaseStatus.alreadyRunning,
        'A purchase check is already running.',
      );
    }

    await initialize();

    if (!await isStoreAvailable()) {
      return const RestorePurchaseResult(
        RestorePurchaseStatus.storeUnavailable,
        'Google Play Billing is not available on this device or build.',
      );
    }

    _restoring = true;
    _restoreCompleter = Completer<RestorePurchaseResult>();

    _restoreTimer = Timer(timeout, () {
      _completeRestore(
        const RestorePurchaseResult(
          RestorePurchaseStatus.noneFound,
          'No LowVolt Pilot subscription was returned for this Google Play account.',
        ),
      );
    });

    try {
      await _iap.restorePurchases();
    } catch (_) {
      _completeRestore(
        const RestorePurchaseResult(
          RestorePurchaseStatus.error,
          'Unable to check purchases right now. Please try again.',
        ),
      );
    }

    final result = await _restoreCompleter!.future;
    _restoreTimer?.cancel();
    _restoreTimer = null;
    _restoreCompleter = null;
    _restoring = false;

    await refreshServerEntitlement();

    return result;
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    var foundLowVoltPilotPurchase = false;

    for (final purchase in purchases) {
      final isLowVoltPilotProduct =
          purchase.productID == monthlyId || purchase.productID == annualId;

      if (isLowVoltPilotProduct &&
          (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored)) {
        foundLowVoltPilotPurchase = true;

        // Temporary local signal only. Before production, Google Play purchase
        // tokens will be verified server-side and written to Supabase
        // entitlements before protected Pro features are unlocked.
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }

    if (foundLowVoltPilotPurchase) {
      _completeRestore(
        const RestorePurchaseResult(
          RestorePurchaseStatus.found,
          'A LowVolt Pilot Pro purchase was found. Server verification is required before Pro access is granted.',
        ),
      );
    }
  }

  void _completeRestore(RestorePurchaseResult result) {
    final completer = _restoreCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }
  }

  void _setPro(bool value) {
    if (_isPro == value) return;
    _isPro = value;
    _isProController.add(value);
  }

  Future<void> dispose() async {
    _restoreTimer?.cancel();
    await _purchaseSub?.cancel();
    await _isProController.close();
  }
}
