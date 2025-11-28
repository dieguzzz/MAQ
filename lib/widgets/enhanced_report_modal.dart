import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/station_model.dart';
import '../models/train_model.dart';
import '../models/report_model.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/report_provider.dart';
import '../services/storage_service.dart';
import '../services/ad_session_service.dart';
import '../services/ad_service.dart';
import '../theme/metro_theme.dart';

class EnhancedReportModal extends StatefulWidget {
  final StationModel? station;
  final TrainModel? train;

  const EnhancedReportModal({
    super.key,
    this.station,
    this.train,
  }) : assert(station != null || train != null, 'Debe proporcionar una estación o un tren');

  @override
  State<EnhancedReportModal> createState() => _EnhancedReportModalState();
}

class _EnhancedReportModalState extends State<EnhancedReportModal>
    with SingleTickerProviderStateMixin {
  String? _selectedEstadoPrincipal;
  final Set<String> _selectedProblemas = {};
  bool _prioridad = false;
  File? _selectedImage;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
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
    _animationController.dispose();
    super.dispose();
  }

  TipoReporte get _tipo => widget.station != null ? TipoReporte.estacion : TipoReporte.tren;
  String get _objetivoId => widget.station?.id ?? widget.train?.id ?? '';
  String get _objetivoNombre => widget.station?.nombre ?? (widget.train != null ? 'Tren ${widget.train!.id}' : '');
  String get _linea => widget.station?.linea ?? widget.train?.linea ?? '';

  List<_EstadoOption> get _estadosDisponibles {
    if (_tipo == TipoReporte.estacion) {
      return [
        const _EstadoOption(value: 'normal', emoji: '🟢', label: 'Normal', color: Colors.green),
        const _EstadoOption(value: 'moderado', emoji: '🟡', label: 'Moderado', color: Colors.orange),
        const _EstadoOption(value: 'lleno', emoji: '🔴', label: 'Lleno', color: Colors.red),
        const _EstadoOption(value: 'retraso', emoji: '⚠️', label: 'Retraso', color: Colors.amber),
        const _EstadoOption(value: 'cerrado', emoji: '🚫', label: 'Cerrado', color: Colors.grey),
      ];
    } else {
      return [
        const _EstadoOption(value: 'asientos_disponibles', emoji: '🟢', label: 'Asientos Disponibles', color: Colors.green),
        const _EstadoOption(value: 'de_pie_comodo', emoji: '🟡', label: 'De Pie Cómodo', color: Colors.orange),
        const _EstadoOption(value: 'sardina', emoji: '🔴', label: 'Sardina', color: Colors.red),
        const _EstadoOption(value: 'express', emoji: '⚡', label: 'Express', color: Colors.blue),
        const _EstadoOption(value: 'lento', emoji: '🐌', label: 'Lento', color: Colors.amber),
        const _EstadoOption(value: 'detenido', emoji: '🛑', label: 'Detenido', color: Colors.red),
      ];
    }
  }

  List<_ProblemaOption> get _problemasDisponibles {
    if (_tipo == TipoReporte.estacion) {
      return [
        const _ProblemaOption(value: 'aire_acondicionado', emoji: '❄️', label: 'Aire Acondicionado roto'),
        const _ProblemaOption(value: 'puertas', emoji: '🚪', label: 'Puertas automáticas fallando'),
        const _ProblemaOption(value: 'limpieza', emoji: '🧹', label: 'Problemas de limpieza'),
        const _ProblemaOption(value: 'mantenimiento', emoji: '🔧', label: 'Mantenimiento en progreso'),
        const _ProblemaOption(value: 'sonido', emoji: '🔊', label: 'Sistema de sonido dañado'),
      ];
    } else {
      return [
        const _ProblemaOption(value: 'aire_acondicionado', emoji: '❄️', label: 'A/C no funciona'),
        const _ProblemaOption(value: 'luces', emoji: '💡', label: 'Luces intermitentes'),
        const _ProblemaOption(value: 'sonido', emoji: '🔊', label: 'Sonido defectuoso'),
        const _ProblemaOption(value: 'puertas', emoji: '🚪', label: 'Puertas problemáticas'),
      ];
    }
  }

  CategoriaReporte _getCategoriaFromEstado(String estado) {
    switch (estado) {
      case 'normal':
      case 'asientos_disponibles':
        return CategoriaReporte.servicioNormal;
      case 'moderado':
      case 'de_pie_comodo':
        return CategoriaReporte.aglomeracion;
      case 'lleno':
      case 'sardina':
        return CategoriaReporte.aglomeracion;
      case 'retraso':
      case 'lento':
      case 'detenido':
        return CategoriaReporte.retraso;
      case 'cerrado':
        return CategoriaReporte.fallaTecnica;
      default:
        return CategoriaReporte.aglomeracion;
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitReport() async {
    if (_selectedEstadoPrincipal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un estado principal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final locationProvider = context.read<LocationProvider>();
    final reportProvider = context.read<ReportProvider>();

    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para reportar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userLocation = locationProvider.currentPosition;
    if (userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activa tu ubicación para enviar reportes'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    GeoPoint targetLocation;
    if (widget.station != null) {
      targetLocation = widget.station!.ubicacion;
    } else if (widget.train != null) {
      targetLocation = widget.train!.ubicacionActual;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo obtener la ubicación'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final geoPoint = GeoPoint(targetLocation.latitude, targetLocation.longitude);

    setState(() {
      _isSubmitting = true;
    });

    String? fotoUrl;
    if (_selectedImage != null) {
      setState(() {
        _isUploadingImage = true;
      });

      // Subir imagen (usaremos un ID temporal, luego se actualizará)
      final storageService = StorageService();
      final tempReportId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      fotoUrl = await storageService.uploadReportImage(tempReportId, _selectedImage!);
      
      setState(() {
        _isUploadingImage = false;
      });
    }

    String? reportId;
    String? errorMessage;
    
    try {
      reportId = await reportProvider.createReport(
        usuarioId: authProvider.currentUser!.uid,
        tipo: _tipo,
        objetivoId: _objetivoId,
        categoria: _getCategoriaFromEstado(_selectedEstadoPrincipal!),
        ubicacion: geoPoint,
        estadoPrincipal: _selectedEstadoPrincipal,
        problemasEspecificos: _selectedProblemas.toList(),
        prioridad: _prioridad,
        fotoUrl: fotoUrl,
        userLocation: userLocation,
      );
    } on Exception catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      print('Error al crear reporte: $e');
    } catch (e) {
      errorMessage = 'Ocurrió un error inesperado. Por favor intenta de nuevo.';
      print('Error inesperado al crear reporte: $e');
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (reportId != null) {
      // Incrementar contador de reportes en la sesión
      await AdSessionService.instance.incrementReportCount();
      
      // Mostrar animación de éxito
      _showSuccessAnimation();
      
      // Esperar un momento para que se vea la animación
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (!mounted) return;
      
      // Verificar si se debe mostrar intersticial
      final shouldShowInterstitial = await AdSessionService.instance.shouldShowInterstitialAfterReport();
      if (shouldShowInterstitial) {
        await AdService.instance.showInterstitialIfAppropriate(
          onAdDismissed: () {},
        );
      }
      
      if (!mounted) return;
      Navigator.of(context).pop();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Ocurrió un error al enviar el reporte'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSuccessAnimation() {
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
  Widget build(BuildContext context) {
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: MetroColors.grayMedium,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Header
                      _buildHeader(),
                      const SizedBox(height: 20),
                      // Estados principales
                      _buildEstadosPrincipales(),
                      const SizedBox(height: 20),
                      // Problemas específicos
                      _buildProblemasEspecificos(),
                      const SizedBox(height: 16),
                      // Prioridad
                      _buildPrioridadOption(),
                      const SizedBox(height: 16),
                      // Foto opcional
                      _buildFotoOption(),
                      const SizedBox(height: 20),
                      // Botón de envío
                      _buildSubmitButton(),
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _objetivoNombre,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
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
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (_linea == 'linea1' ? MetroColors.blue : MetroColors.green)
                .withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _linea == 'linea1' ? 'Línea 1' : 'Línea 2',
            style: TextStyle(
              color: _linea == 'linea1' ? MetroColors.blue : MetroColors.green,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstadosPrincipales() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estado principal',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: MetroColors.grayDark,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _estadosDisponibles.map((estado) {
            final isSelected = _selectedEstadoPrincipal == estado.value;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedEstadoPrincipal = estado.value;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? estado.color.withOpacity(0.2)
                      : MetroColors.grayLight,
                  border: Border.all(
                    color: isSelected ? estado.color : Colors.transparent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      estado.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      estado.label,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? estado.color : MetroColors.grayDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProblemasEspecificos() {
    if (_problemasDisponibles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Problemas específicos (opcional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: MetroColors.grayDark,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _problemasDisponibles.map((problema) {
            final isSelected = _selectedProblemas.contains(problema.value);
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(problema.emoji),
                  const SizedBox(width: 6),
                  Text(problema.label),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedProblemas.add(problema.value);
                  } else {
                    _selectedProblemas.remove(problema.value);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrioridadOption() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Marcar como prioridad',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: MetroColors.grayDark,
            ),
          ),
        ),
        Switch(
          value: _prioridad,
          onChanged: (value) {
            setState(() {
              _prioridad = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildFotoOption() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto (opcional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: MetroColors.grayDark,
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedImage != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
            ],
          )
        else
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Tomar foto'),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isSubmitting || _isUploadingImage) ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSubmitting || _isUploadingImage
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Enviando...'),
                ],
              )
            : const Text(
                'Enviar reporte',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class _EstadoOption {
  final String value;
  final String emoji;
  final String label;
  final Color color;

  const _EstadoOption({
    required this.value,
    required this.emoji,
    required this.label,
    required this.color,
  });
}

class _ProblemaOption {
  final String value;
  final String emoji;
  final String label;

  const _ProblemaOption({
    required this.value,
    required this.emoji,
    required this.label,
  });
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
                      color: Colors.green.withOpacity(0.3),
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

