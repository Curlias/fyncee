import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

/// Servicio de autenticación con Supabase
/// 
/// Maneja registro, login, logout, recuperación de contraseña y sesión
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// Usuario actual (null si no está autenticado)
  User? get currentUser => _client.auth.currentUser;

  /// ID del usuario actual
  String? get currentUserId => currentUser?.id;

  /// Email del usuario actual
  String? get currentUserEmail => currentUser?.email;

  /// Verificar si hay un usuario autenticado
  bool get isAuthenticated => currentUser != null;

  /// Stream de cambios en el estado de autenticación
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ==================== REGISTRO ====================

  /// Registrar un nuevo usuario
  /// 
  /// [email]: Email del usuario
  /// [password]: Contraseña (mínimo 6 caracteres)
  /// [fullName]: Nombre completo (opcional)
  /// 
  /// Retorna el usuario creado o lanza una excepción
  Future<User> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName ?? '',
        },
      );

      if (response.user == null) {
        throw 'Error al crear usuario';
      }

      print('✅ Usuario registrado: ${response.user!.email}');
      return response.user!;
    } catch (e) {
      print('❌ Error en registro: $e');
      rethrow;
    }
  }

  // ==================== LOGIN ====================

  /// Iniciar sesión con email y contraseña
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw 'Error al iniciar sesión';
      }

      print('✅ Sesión iniciada: ${response.user!.email}');
      return response.user!;
    } catch (e) {
      print('❌ Error en login: $e');
      rethrow;
    }
  }

  /// Iniciar sesión con Google (requiere configuración adicional)
  Future<User?> signInWithGoogle() async {
    try {
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'fyncee://callback',
      );

      print('✅ Iniciando sesión con Google...');
      return null; // El usuario se obtendrá en el callback
    } catch (e) {
      print('❌ Error en login con Google: $e');
      rethrow;
    }
  }

  /// Iniciar sesión con Apple (requiere configuración adicional)
  Future<User?> signInWithApple() async {
    try {
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'fyncee://callback',
      );

      print('✅ Iniciando sesión con Apple...');
      return null; // El usuario se obtendrá en el callback
    } catch (e) {
      print('❌ Error en login con Apple: $e');
      rethrow;
    }
  }

  // ==================== LOGOUT ====================

  /// Cerrar sesión
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      print('✅ Sesión cerrada');
    } catch (e) {
      print('❌ Error al cerrar sesión: $e');
      rethrow;
    }
  }

  // ==================== RECUPERAR CONTRASEÑA ====================

  /// Enviar email para recuperar contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'fyncee://reset-password',
      );
      print('✅ Email de recuperación enviado a: $email');
    } catch (e) {
      print('❌ Error al enviar email de recuperación: $e');
      rethrow;
    }
  }

  /// Actualizar contraseña (requiere estar autenticado)
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      print('✅ Contraseña actualizada');
    } catch (e) {
      print('❌ Error al actualizar contraseña: $e');
      rethrow;
    }
  }

  // ==================== VERIFICACIÓN DE EMAIL ====================

  /// Reenviar email de verificación
  Future<void> resendVerificationEmail() async {
    if (!isAuthenticated) throw 'Usuario no autenticado';

    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: currentUserEmail!,
      );
      print('✅ Email de verificación reenviado');
    } catch (e) {
      print('❌ Error al reenviar email de verificación: $e');
      rethrow;
    }
  }

  /// Refrescar la sesión para obtener el estado actualizado
  Future<void> refreshSession() async {
    try {
      await _client.auth.refreshSession();
      print('✅ Sesión refrescada');
    } catch (e) {
      print('❌ Error al refrescar sesión: $e');
      rethrow;
    }
  }

  // ==================== PERFIL ====================

  /// Obtener perfil del usuario actual
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    if (!isAuthenticated) return null;

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', currentUserId!)
          .single();

      return response;
    } catch (e) {
      print('❌ Error obteniendo perfil: $e');
      return null;
    }
  }

  /// Actualizar perfil del usuario
  Future<void> updateProfile({
    String? fullName,
    String? avatarUrl,
    String? phone,
    String? currency,
    String? language,
    bool? notificationsEnabled,
    String? theme,
  }) async {
    if (!isAuthenticated) throw 'Usuario no autenticado';

    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (phone != null) updates['phone'] = phone;
      if (currency != null) updates['currency'] = currency;
      if (language != null) updates['language'] = language;
      if (notificationsEnabled != null) {
        updates['notifications_enabled'] = notificationsEnabled;
      }
      if (theme != null) updates['theme'] = theme;

      await _client
          .from('profiles')
          .update(updates)
          .eq('id', currentUserId!);

      print('✅ Perfil actualizado');
    } catch (e) {
      print('❌ Error actualizando perfil: $e');
      rethrow;
    }
  }

  /// Subir foto de perfil
  Future<String> uploadAvatar(String filePath) async {
    if (!isAuthenticated) throw 'Usuario no autenticado';

    try {
      final file = File(filePath);
      final fileName = 'avatar_${currentUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _client.storage
          .from('avatars')
          .upload(fileName, file);

      final url = _client.storage
          .from('avatars')
          .getPublicUrl(fileName);

      // Actualizar perfil con nueva URL
      await updateProfile(avatarUrl: url);

      print('✅ Avatar subido: $url');
      return url;
    } catch (e) {
      print('❌ Error subiendo avatar: $e');
      rethrow;
    }
  }

  // ==================== VALIDACIONES ====================

  /// Validar formato de email
  bool isValidEmail(String email) {
    // Regex más permisivo que acepta emails válidos estándar
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    return emailRegex.hasMatch(email.trim());
  }

  /// Validar fortaleza de contraseña
  bool isValidPassword(String password) {
    // Mínimo 6 caracteres
    return password.length >= 6;
  }

  /// Obtener mensaje de fortaleza de contraseña
  String getPasswordStrength(String password) {
    if (password.isEmpty) return '';
    if (password.length < 6) return 'Muy débil';
    if (password.length < 8) return 'Débil';
    
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    int strength = 0;
    if (hasUppercase) strength++;
    if (hasLowercase) strength++;
    if (hasDigits) strength++;
    if (hasSpecialChars) strength++;
    
    if (strength >= 4 && password.length >= 12) return 'Muy fuerte';
    if (strength >= 3) return 'Fuerte';
    if (strength >= 2) return 'Media';
    return 'Débil';
  }

  // ==================== UTILIDADES ====================

  /// Manejar errores de Supabase Auth
  String getErrorMessage(dynamic error) {
    if (error == null) return 'Error desconocido';
    
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('invalid login credentials')) {
      return 'Email o contraseña incorrectos';
    }
    if (errorString.contains('user already registered')) {
      return 'Este email ya está registrado';
    }
    if (errorString.contains('email not confirmed')) {
      return 'Por favor confirma tu email';
    }
    if (errorString.contains('invalid email')) {
      return 'Email inválido';
    }
    if (errorString.contains('password')) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (errorString.contains('network')) {
      return 'Error de conexión. Verifica tu internet';
    }
    
    return 'Error: ${error.toString()}';
  }
}
