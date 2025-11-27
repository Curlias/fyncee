import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class BiometricAuthService {
  static final BiometricAuthService _instance = BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  
  // Keys para SharedPreferences
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyPinEnabled = 'pin_enabled';
  static const String _keyPinHash = 'pin_hash';
  static const String _keyRequireAuth = 'require_auth_on_startup';

  // Verificar si el dispositivo soporta biometría
  Future<bool> canUseBiometrics() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      print('❌ Error verificando biometría: $e');
      return false;
    }
  }

  // Obtener tipos de biometría disponibles
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('❌ Error obteniendo biométricos: $e');
      return [];
    }
  }

  // Autenticar con biometría
  Future<bool> authenticateWithBiometrics({
    String reason = 'Por favor autentícate para continuar',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      print('❌ Error en autenticación biométrica: $e');
      return false;
    }
  }

  // ===== CONFIGURACIÓN =====

  // Verificar si la biometría está habilitada
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  // Habilitar/deshabilitar biometría
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, enabled);
  }

  // Verificar si el PIN está habilitado
  Future<bool> isPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPinEnabled) ?? false;
  }

  // Habilitar/deshabilitar PIN
  Future<void> setPinEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPinEnabled, enabled);
  }

  // Verificar si requiere autenticación al inicio
  Future<bool> requiresAuthOnStartup() async {
    final biometricEnabled = await isBiometricEnabled();
    final pinEnabled = await isPinEnabled();
    return biometricEnabled || pinEnabled;
  }

  // ===== PIN =====

  // Hash del PIN usando SHA256
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Guardar PIN
  Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final hash = _hashPin(pin);
    await prefs.setString(_keyPinHash, hash);
    await setPinEnabled(true);
  }

  // Verificar PIN
  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final savedHash = prefs.getString(_keyPinHash);
    
    if (savedHash == null) {
      return false;
    }
    
    final inputHash = _hashPin(pin);
    return savedHash == inputHash;
  }

  // Eliminar PIN
  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPinHash);
    await setPinEnabled(false);
  }

  // Verificar si existe un PIN guardado
  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyPinHash);
  }

  // ===== AUTENTICACIÓN GENERAL =====

  // Autenticar (intenta biometría primero, luego PIN)
  Future<bool> authenticate({String reason = 'Autentícate para continuar'}) async {
    // Si biometría está habilitada, intentar primero
    if (await isBiometricEnabled()) {
      final canUse = await canUseBiometrics();
      if (canUse) {
        final authenticated = await authenticateWithBiometrics(reason: reason);
        if (authenticated) {
          return true;
        }
      }
    }
    
    // Si falló la biometría o no está disponible, PIN es la alternativa
    // El PIN se maneja en la UI con un diálogo
    return false;
  }

  // Obtener nombre del tipo de biometría
  String getBiometricTypeName(List<BiometricType> types) {
    if (types.isEmpty) return 'Biometría';
    
    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Huella Digital';
    } else if (types.contains(BiometricType.iris)) {
      return 'Iris';
    } else {
      return 'Biometría';
    }
  }
}
