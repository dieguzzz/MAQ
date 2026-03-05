import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../services/subscription_service.dart';
import '../../services/firebase_service.dart';
import '../../theme/metro_theme.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _subscriptionService.initialize();
    await _checkPremiumStatus();
    setState(() {});
  }

  Future<void> _checkPremiumStatus() async {
    final userId = _firebaseService.getCurrentUser()?.uid;
    if (userId == null) return;

    final isPremium = await _subscriptionService.checkPremiumStatus(userId);
    setState(() {
      _isPremium = isPremium;
    });
  }

  Future<void> _purchaseProduct(ProductDetails product) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _subscriptionService.purchaseProduct(product);
      await _checkPremiumStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Suscripción activada exitosamente!'),
            backgroundColor: MetroColors.stateNormal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _subscriptionService.restorePurchases();
      await _checkPremiumStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compras restauradas'),
            backgroundColor: MetroColors.stateNormal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: MetroColors.stateCritical,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _subscriptionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isPremium) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Premium'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified,
                size: 80,
                color: MetroColors.energyOrange,
              ),
              const SizedBox(height: 24),
              const Text(
                '¡Eres Premium!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Disfruta de todas las funciones premium',
                style: TextStyle(
                    fontSize: 16,
                    color: MetroColors.grayDark.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _restorePurchases,
                child: const Text('Restaurar Compras'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade a Premium'),
      ),
      body: _subscriptionService.isAvailable
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  const Icon(
                    Icons.star,
                    size: 80,
                    color: MetroColors.energyOrange,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Desbloquea Premium',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Accede a funciones exclusivas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: MetroColors.grayDark.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildFeatureItem(
                    Icons.notifications_active,
                    'Alertas Tempranas',
                    'Recibe notificaciones antes de que llegue el tren',
                  ),
                  _buildFeatureItem(
                    Icons.analytics,
                    'Estadísticas Avanzadas',
                    'Análisis detallado de tus reportes y actividad',
                  ),
                  _buildFeatureItem(
                    Icons.offline_pin,
                    'Mapas Offline',
                    'Accede a los mapas sin conexión a internet',
                  ),
                  _buildFeatureItem(
                    Icons.palette,
                    'Temas Exclusivos',
                    'Personaliza la apariencia con temas premium',
                  ),
                  _buildFeatureItem(
                    Icons.priority_high,
                    'Reportes Prioritarios',
                    'Tus reportes aparecen primero en la lista',
                  ),
                  const SizedBox(height: 32),
                  if (_subscriptionService.products.isEmpty)
                    const Center(
                      child: CircularProgressIndicator(),
                    )
                  else
                    ..._subscriptionService.products.map((product) {
                      final isMonthly = product.id.contains('monthly');
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 0,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            isMonthly ? 'Mensual' : 'Anual',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            product.price,
                            style: const TextStyle(
                              fontSize: 18,
                              color: MetroColors.energyOrange,
                            ),
                          ),
                          trailing: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _purchaseProduct(product),
                            child: const Text('Suscribirse'),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading ? null : _restorePurchases,
                    child: const Text('Restaurar Compras'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            )
          : const Center(
              child: Text('Las compras in-app no están disponibles'),
            ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: MetroColors.blue, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: MetroColors.grayDark.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
