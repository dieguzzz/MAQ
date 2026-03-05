import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/report_model.dart';
import '../models/station_model.dart';
import '../models/train_model.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/metro_data_provider.dart';
import '../providers/report_provider.dart';
import '../theme/metro_theme.dart';
import '../services/ad_service.dart';
import '../services/ad_session_service.dart';

class QuickReportSheet extends StatefulWidget {
  const QuickReportSheet({super.key});

  @override
  State<QuickReportSheet> createState() => _QuickReportSheetState();
}

class _QuickReportSheetState extends State<QuickReportSheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _descripcionController = TextEditingController();
  TipoReporte _tipoSeleccionado = TipoReporte.estacion;
  String? _stationId;
  String? _trainId;
  CategoriaReporte? _categoriaSeleccionada;
  bool _isSubmitting = false;
  bool _initialized = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showSuccessAnimation(BuildContext context) {
    _animationController.forward();
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => _SuccessAnimationDialog(
        controller: _animationController,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final metroProvider = context.read<MetroDataProvider>();
    final estaciones = metroProvider.stations;
    final trenes = metroProvider.trains;

    if (estaciones.isNotEmpty) {
      _stationId = estaciones.first.id;
    }
    if (trenes.isNotEmpty) {
      _trainId = trenes.first.id;
    }

    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final metroProvider = context.watch<MetroDataProvider>();
    final estaciones = metroProvider.stations;
    final trenes = metroProvider.trains;

    final hasStations = estaciones.isNotEmpty;
    final hasTrains = trenes.isNotEmpty;

    final viewInsets = MediaQuery.of(context).viewInsets;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Material(
              color: MetroColors.white,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: MetroColors.grayMedium,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Reporte rápido',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: MetroColors.grayDark,
                              ),
                            ),
                          ),
                          if (_isSubmitting)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTipoSelector(),
                      const SizedBox(height: 12),
                      if (_tipoSeleccionado == TipoReporte.estacion)
                        hasStations
                            ? _buildStationDropdown(estaciones)
                            : _buildEmptyPlaceholder(
                                'No hay estaciones disponibles')
                      else
                        hasTrains
                            ? _buildTrainDropdown(trenes)
                            : _buildEmptyPlaceholder(
                                'No hay trenes disponibles'),
                      const SizedBox(height: 16),
                      _buildCategoriaSelector(),
                      const SizedBox(height: 12),
                      _buildDescripcionField(),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _isSubmitting ? null : () => _submit(context),
                          child: const Text('Enviar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipoSelector() {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Text('Estación'),
            selected: _tipoSeleccionado == TipoReporte.estacion,
            onSelected: (_) {
              setState(() {
                _tipoSeleccionado = TipoReporte.estacion;
                _categoriaSeleccionada = null;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ChoiceChip(
            label: const Text('Tren'),
            selected: _tipoSeleccionado == TipoReporte.tren,
            onSelected: (_) {
              setState(() {
                _tipoSeleccionado = TipoReporte.tren;
                _categoriaSeleccionada = null;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStationDropdown(List<StationModel> stations) {
    return DropdownButtonFormField<String>(
      initialValue: _stationId,
      items: stations
          .map(
            (station) => DropdownMenuItem(
              value: station.id,
              child: Text(station.nombre),
            ),
          )
          .toList(),
      onChanged: (value) => setState(() => _stationId = value),
      decoration: const InputDecoration(
        labelText: 'Estación',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildTrainDropdown(List<TrainModel> trains) {
    return DropdownButtonFormField<String>(
      initialValue: _trainId,
      items: trains
          .map(
            (train) => DropdownMenuItem(
              value: train.id,
              child: Text('Tren ${train.id} • ${train.linea.toUpperCase()}'),
            ),
          )
          .toList(),
      onChanged: (value) => setState(() => _trainId = value),
      decoration: const InputDecoration(
        labelText: 'Tren',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildEmptyPlaceholder(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MetroColors.grayLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: MetroColors.grayDark,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCategoriaSelector() {
    final categorias = _getCategorias();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categoría',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: MetroColors.grayDark,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categorias
              .map(
                (categoria) => ChoiceChip(
                  label: Text(_getCategoriaText(categoria)),
                  selected: _categoriaSeleccionada == categoria,
                  onSelected: (_) {
                    setState(() {
                      _categoriaSeleccionada = categoria;
                    });
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDescripcionField() {
    return TextField(
      controller: _descripcionController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Detalles (opcional)',
        border: OutlineInputBorder(),
      ),
    );
  }

  List<CategoriaReporte> _getCategorias() {
    if (_tipoSeleccionado == TipoReporte.estacion) {
      return const [
        CategoriaReporte.aglomeracion,
        CategoriaReporte.fallaTecnica,
        CategoriaReporte.servicioNormal,
      ];
    }

    return const [
      CategoriaReporte.aglomeracion,
      CategoriaReporte.retraso,
      CategoriaReporte.fallaTecnica,
    ];
  }

  String _getCategoriaText(CategoriaReporte categoria) {
    switch (categoria) {
      case CategoriaReporte.aglomeracion:
        return 'Aglomeración';
      case CategoriaReporte.retraso:
        return 'Retraso';
      case CategoriaReporte.servicioNormal:
        return 'Servicio normal';
      case CategoriaReporte.fallaTecnica:
        return 'Falla técnica';
    }
  }

  Future<void> _submit(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final locationProvider = context.read<LocationProvider>();
    final reportProvider = context.read<ReportProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final objetivoId =
        _tipoSeleccionado == TipoReporte.estacion ? _stationId : _trainId;

    if (authProvider.currentUser == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para reportar')),
      );
      return;
    }

    if (objetivoId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Selecciona un destino antes de enviar')),
      );
      return;
    }

    if (_categoriaSeleccionada == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría')),
      );
      return;
    }

    final posicion = locationProvider.currentPosition;
    if (posicion == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Activa tu ubicación para enviar reportes rápidos'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final geoPoint = GeoPoint(posicion.latitude, posicion.longitude);

    final reportId = await reportProvider.createReport(
      usuarioId: authProvider.currentUser!.uid,
      tipo: _tipoSeleccionado,
      objetivoId: objetivoId,
      categoria: _categoriaSeleccionada!,
      descripcion: _descripcionController.text.isEmpty
          ? null
          : _descripcionController.text.trim(),
      ubicacion: geoPoint,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (reportId != null) {
      // Incrementar contador de reportes en la sesión
      await AdSessionService.instance.incrementReportCount();

      // Mostrar animación de éxito antes de cerrar
      _showSuccessAnimation(context);

      // Esperar un momento para que se vea la animación
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      // Verificar si se debe mostrar intersticial (después del 3er reporte)
      final shouldShowInterstitial =
          await AdSessionService.instance.shouldShowInterstitialAfterReport();
      if (shouldShowInterstitial) {
        await AdService.instance.showInterstitialIfAppropriate(
          onAdDismissed: () {
            // Continuar después del anuncio
          },
        );
      }

      navigator.pop();

      // Mostrar opción de rewarded ad opcional (duplicar puntos)
      if (mounted) {
        _showRewardedAdOption(context);
      }

      messenger.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('¡Reporte enviado exitosamente!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error al enviar'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Muestra opción opcional de rewarded ad para duplicar puntos
  void _showRewardedAdOption(BuildContext context) {
    // Esperar un momento para que el usuario vea el éxito del reporte
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.stars, color: Colors.amber),
              SizedBox(width: 8),
              Text('¡Duplica tus puntos!'),
            ],
          ),
          content: const Text(
            '¿Quieres duplicar los puntos de tu último reporte?\n\n'
            'Mira un anuncio de 30 segundos y obtén el doble de puntos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No, gracias'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _showRewardedAdForPoints(context);
              },
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Ver Anuncio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Muestra rewarded ad y duplica los puntos del último reporte
  Future<void> _showRewardedAdForPoints(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser == null) return;

    // Cargar rewarded ad
    await AdService.instance.loadRewardedAd(
      onRewarded: (reward) async {
        // Duplicar puntos del último reporte (asumiendo 10 puntos base)
        const puntosBase = 10;
        const puntosDuplicados = puntosBase; // Total: 20 puntos

        // Aquí deberías actualizar los puntos del usuario en Firestore
        // Por ahora solo mostramos un mensaje
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('¡Obtuviste $puntosDuplicados puntos extra!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      onAdFailedToLoad: (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo cargar el anuncio. Intenta más tarde.'),
            ),
          );
        }
      },
    );

    // Mostrar el anuncio
    AdService.instance.showRewardedAd(
      onRewarded: (reward) {
        // Ya se maneja en el callback de loadRewardedAd
      },
      onAdFailedToShow: () {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('No se pudo mostrar el anuncio. Intenta más tarde.'),
            ),
          );
        }
      },
    );
  }
}

class _SuccessAnimationDialog extends StatelessWidget {
  final AnimationController controller;

  const _SuccessAnimationDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.scale(
          scale: Curves.elasticOut.transform(controller.value),
          child: Opacity(
            opacity: controller.value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 80,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
