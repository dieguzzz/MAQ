import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/firebase_service.dart';

class SubscriptionService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];

  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;

  Future<void> initialize() async {
    _isAvailable = await _inAppPurchase.isAvailable();

    if (!_isAvailable) {
      return;
    }

    // Escuchar actualizaciones de compras
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => print('Error en compras: $error'),
    );

    // Cargar productos disponibles
    await loadProducts();
  }

  Future<void> loadProducts() async {
    if (!_isAvailable) return;

    const Set<String> productIds = {
      'metropty_premium_monthly',
      'metropty_premium_yearly',
    };

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(productIds);

    if (response.notFoundIDs.isNotEmpty) {
      print('Productos no encontrados: ${response.notFoundIDs}');
    }

    _products = response.productDetails;
  }

  Future<void> purchaseProduct(ProductDetails product) async {
    if (!_isAvailable) {
      throw Exception('Las compras in-app no están disponibles');
    }

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: product,
    );

    if (product.id.contains('subscription')) {
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  Future<void> restorePurchases() async {
    if (!_isAvailable) return;

    await _inAppPurchase.restorePurchases();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        // Mostrar indicador de carga
      } else {
        if (purchase.status == PurchaseStatus.error) {
          // Manejar error
          print('Error en compra: ${purchase.error}');
        } else if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          // Verificar y activar suscripción
          _verifyAndActivatePurchase(purchase);
        }

        if (purchase.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchase);
        }
      }
    }
  }

  Future<void> _verifyAndActivatePurchase(PurchaseDetails purchase) async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return;

    // Verificar la compra con el servidor (en producción, verificar con tu backend)
    // Por ahora, activamos directamente
    final isPremium = purchase.productID.contains('premium');

    if (isPremium) {
      await _firestore.collection('users').doc(userId).update({
        'premium': true,
        'premium_since': FieldValue.serverTimestamp(),
        'premium_product_id': purchase.productID,
      });
    }
  }

  Future<bool> checkPremiumStatus(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final data = userDoc.data();
      return data?['premium'] == true;
    } catch (e) {
      print('Error verificando premium: $e');
      return false;
    }
  }

  Future<void> cancelSubscription(String userId) async {
    // En producción, esto debería cancelar la suscripción en el backend
    // Por ahora, solo actualizamos el estado
    await _firestore.collection('users').doc(userId).update({
      'premium': false,
      'premium_cancelled_at': FieldValue.serverTimestamp(),
    });
  }

  void dispose() {
    _subscription?.cancel();
  }
}
