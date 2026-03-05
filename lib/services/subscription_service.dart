// DISABLED: In-app purchases not yet implemented.
// Server-side purchase verification required before enabling.
// See docs/ANALISIS_COMPLETO_APP.md - Crítico 1.1

class SubscriptionService {
  bool get isAvailable => false;
  List<dynamic> get products => [];

  Future<void> initialize() async {}
  Future<void> loadProducts() async {}
  Future<void> purchaseProduct(dynamic product) async {}
  Future<void> restorePurchases() async {}

  Future<bool> checkPremiumStatus(String userId) async => false;
  Future<void> cancelSubscription(String userId) async {}

  void dispose() {}
}
