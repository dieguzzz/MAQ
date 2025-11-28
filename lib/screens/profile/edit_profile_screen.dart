import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../theme/metro_theme.dart';
import '../../services/storage_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nombreController;
  bool _isSaving = false;
  bool _hasChanges = false;
  bool _isUploadingImage = false;
  File? _selectedImageFile;
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _nombreController = TextEditingController(text: user?.nombre ?? '');
    _nombreController.addListener(() {
      _checkForChanges();
    });
  }

  void _checkForChanges() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final nombreChanged = _nombreController.text.trim() != (user?.nombre ?? '');
    final imageChanged = _selectedImageFile != null;
    
    setState(() {
      _hasChanges = nombreChanged || imageChanged;
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_hasChanges && _selectedImageFile == null) {
      Navigator.pop(context);
      return;
    }

    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre no puede estar vacío'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (nombre.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre debe tener al menos 2 caracteres'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user == null) {
      setState(() {
        _isSaving = false;
      });
      return;
    }

    String? imageUrl;

    // Subir imagen si hay una seleccionada
    if (_selectedImageFile != null) {
      setState(() {
        _isUploadingImage = true;
      });

      imageUrl = await _storageService.uploadProfileImage(
        user.uid,
        _selectedImageFile!,
      );

      setState(() {
        _isUploadingImage = false;
      });

      if (imageUrl == null) {
        setState(() {
          _isSaving = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al subir la imagen. Intenta nuevamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // Actualizar perfil
    final success = await authProvider.updateProfile(
      nombre: nombre,
      fotoUrl: imageUrl,
    );

    setState(() {
      _isSaving = false;
    });

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Perfil actualizado exitosamente'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar el perfil. Intenta nuevamente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Muestra un diálogo para seleccionar la fuente de la imagen
  Future<void> _showImageSourceDialog() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Imagen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    XFile? pickedFile;
    if (source == ImageSource.gallery) {
      pickedFile = await _storageService.pickImageFromGallery();
    } else {
      pickedFile = await _storageService.pickImageFromCamera();
    }

    if (pickedFile != null && mounted) {
      final path = pickedFile.path;
      if (path.isNotEmpty) {
        setState(() {
          _selectedImageFile = File(path);
        });
        _checkForChanges();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _hasChanges ? _saveProfile : null,
              child: Text(
                'Guardar',
                style: TextStyle(
                  color: _hasChanges
                      ? MetroColors.blue
                      : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;

          if (user == null) {
            return const Center(
              child: Text('Debes iniciar sesión para editar tu perfil'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Foto de perfil
                Center(
                  child: Stack(
                    children: [
                      if (_isUploadingImage)
                        const CircleAvatar(
                          radius: 60,
                          backgroundColor: MetroColors.grayMedium,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(MetroColors.blue),
                          ),
                        )
                      else
                        _buildProfileAvatar(user),
                      if (!_isUploadingImage)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: MetroColors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _isUploadingImage ? null : _showImageSourceDialog,
                    child: Text(
                      _isUploadingImage
                          ? 'Subiendo imagen...'
                          : _selectedImageFile != null
                              ? 'Cambiar foto seleccionada'
                              : 'Cambiar foto de perfil',
                    ),
                  ),
                ),
                if (_selectedImageFile != null)
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedImageFile = null;
                        });
                        _checkForChanges();
                      },
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Cancelar cambio'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                const SizedBox(height: 32),

                // Información del usuario
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Información Personal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: MetroColors.grayDark,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Nombre
                        TextField(
                          controller: _nombreController,
                          decoration: InputDecoration(
                            labelText: 'Nombre',
                            hintText: 'Ingresa tu nombre',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: MetroColors.grayLight,
                          ),
                          textCapitalization: TextCapitalization.words,
                          maxLength: 50,
                        ),
                        const SizedBox(height: 16),

                        // Email (solo lectura)
                        TextField(
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            hintText: user.email,
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: MetroColors.grayLight.withOpacity(0.5),
                          ),
                          controller: TextEditingController(text: user.email),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'El correo electrónico no se puede cambiar desde aquí.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Información adicional (solo lectura)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estadísticas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: MetroColors.grayDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(
                          Icons.star,
                          'Reputación',
                          '${user.reputacion}',
                          MetroColors.energyOrange,
                        ),
                        const Divider(),
                        _buildStatRow(
                          Icons.report,
                          'Reportes',
                          '${user.reportesCount}',
                          MetroColors.blue,
                        ),
                        const Divider(),
                        _buildStatRow(
                          Icons.calendar_today,
                          'Miembro desde',
                          _formatDate(user.creadoEn),
                          MetroColors.green,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botón de guardar
                ElevatedButton(
                  onPressed: _hasChanges && !_isSaving ? _saveProfile : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _hasChanges
                        ? MetroColors.blue
                        : MetroColors.grayMedium,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Guardar Cambios',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: MetroColors.grayDark,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]}, ${date.year}';
  }

  Widget _buildProfileAvatar(UserModel user) {
    ImageProvider? imageProvider;
    
    if (_selectedImageFile != null) {
      imageProvider = FileImage(_selectedImageFile!);
    } else if (user.fotoUrl != null) {
      imageProvider = NetworkImage(user.fotoUrl!);
    }

    return CircleAvatar(
      radius: 60,
      backgroundImage: imageProvider,
      backgroundColor: MetroColors.blue,
      child: imageProvider == null
          ? Text(
              user.nombre[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 48,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}

