import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'supabase_service.dart';

class ProfileImageService {
  final ImagePicker _picker = ImagePicker();
  final SupabaseService _supabase = SupabaseService();
  
  /// Obtener la URL de la imagen de perfil desde Supabase
  Future<String?> getProfileImagePath() async {
    return await _supabase.getProfileImageUrl();
  }
  
  /// Subir imagen a Supabase Storage
  Future<String?> _uploadToSupabase(String filePath) async {
    print('🔄 Subiendo imagen a Supabase...');
    return await _supabase.uploadProfileImage(filePath);
  }
  
  /// Limpiar imagen de perfil (eliminar de Supabase)
  Future<void> clearProfileImage() async {
    // Actualizar el perfil para remover la URL del avatar
    await _supabase.updateUserProfile(customData: {'avatar_url': null});
  }
  
  Future<File?> pickImageFromGallery() async {
    try {
      String? tempPath;
      
      // En macOS, Windows y Linux usamos el selector de archivos nativo
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        const XTypeGroup typeGroup = XTypeGroup(
          label: 'images',
          extensions: <String>['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
        );
        
        final XFile? file = await openFile(
          acceptedTypeGroups: <XTypeGroup>[typeGroup],
        );
        
        if (file != null) {
          // Copiar la imagen temporalmente al directorio de la app
          final appDir = await getApplicationDocumentsDirectory();
          final fileName = path.basename(file.path);
          final savedPath = path.join(appDir.path, 'temp_$fileName');
          
          print('📁 Copiando imagen desde: ${file.path}');
          print('📁 Guardando temporalmente en: $savedPath');
          
          final imageBytes = await File(file.path).readAsBytes();
          final tempFile = await File(savedPath).writeAsBytes(imageBytes);
          
          tempPath = savedPath;
          
          // Subir a Supabase
          final url = await _uploadToSupabase(tempPath);
          
          if (url != null) {
            print('✅ Imagen subida a Supabase: $url');
            // Eliminar archivo temporal
            await tempFile.delete();
            return File(url); // Retornamos un File con la URL como path
          }
        }
      } else {
        // En móviles (Android/iOS) usamos ImagePicker
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 85,
        );
        
        if (image != null) {
          tempPath = image.path;
          
          // Subir a Supabase
          final url = await _uploadToSupabase(tempPath);
          
          if (url != null) {
            print('✅ Imagen subida a Supabase: $url');
            return File(url);
          }
        }
      }
    } catch (e) {
      print('❌ Error picking image: $e');
    }
    return null;
  }
  
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        // Subir a Supabase
        final url = await _uploadToSupabase(image.path);
        
        if (url != null) {
          print('✅ Imagen subida a Supabase: $url');
          return File(url);
        }
      }
    } catch (e) {
      print('❌ Error taking photo: $e');
    }
    return null;
  }
}
