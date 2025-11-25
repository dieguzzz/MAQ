import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Servicio para manejar la subida de archivos a Firebase Storage
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  /// Selecciona una imagen desde la galería
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Comprimir a 85% de calidad
        maxWidth: 1024, // Redimensionar si es muy grande
        maxHeight: 1024,
      );
      return image;
    } catch (e) {
      print('Error seleccionando imagen de galería: $e');
      return null;
    }
  }

  /// Selecciona una imagen desde la cámara
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      return image;
    } catch (e) {
      print('Error tomando foto con cámara: $e');
      return null;
    }
  }

  /// Sube una imagen de perfil a Firebase Storage
  /// Retorna la URL de descarga de la imagen
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      // Crear referencia al archivo en Storage
      // Ruta: profile_images/{userId}/profile.jpg
      final ref = _storage.ref().child('profile_images').child(userId).child('profile.jpg');

      // Subir el archivo
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'public, max-age=31536000', // Cache por 1 año
        ),
      );

      // Esperar a que termine la subida
      final snapshot = await uploadTask;
      
      // Obtener la URL de descarga
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error subiendo imagen de perfil: $e');
      return null;
    }
  }

  /// Elimina la imagen de perfil anterior
  Future<void> deleteProfileImage(String userId) async {
    try {
      final ref = _storage.ref().child('profile_images').child(userId).child('profile.jpg');
      await ref.delete();
    } catch (e) {
      // Ignorar error si el archivo no existe
      print('Error eliminando imagen anterior (puede que no exista): $e');
    }
  }

  /// Muestra un diálogo para seleccionar la fuente de la imagen
  Future<XFile?> pickImageWithSourceChoice() async {
    // Este método se puede llamar desde un diálogo en la UI
    // Por ahora retornamos null, la UI manejará el diálogo
    return null;
  }
}

