import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/supabase_service.dart';

/// Configuración de apps bancarias para leer notificaciones
class BankAppConfig {
  final String packageName; // Para Android (ej: 'com.bbva.bancomer')
  final String bundleId; // Para iOS (ej: 'com.bbva.mobile')
  final String displayName; // Nombre para mostrar
  final List<String> keywords; // Palabras clave para detectar transacciones
  final RegExp? amountPattern; // Patrón regex para extraer monto
  final bool enabled;

  BankAppConfig({
    required this.packageName,
    required this.bundleId,
    required this.displayName,
    required this.keywords,
    this.amountPattern,
    this.enabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'package_name': packageName,
      'bundle_id': bundleId,
      'display_name': displayName,
      'keywords': keywords,
      'amount_pattern': amountPattern?.pattern,
      'enabled': enabled,
    };
  }

  factory BankAppConfig.fromMap(Map<String, dynamic> map) {
    return BankAppConfig(
      packageName: map['package_name'] as String,
      bundleId: map['bundle_id'] as String,
      displayName: map['display_name'] as String,
      keywords: List<String>.from(map['keywords'] as List),
      amountPattern: map['amount_pattern'] != null 
          ? RegExp(map['amount_pattern'] as String)
          : null,
      enabled: map['enabled'] as bool? ?? true,
    );
  }

  /// Configuraciones predefinidas de bancos mexicanos
  static List<BankAppConfig> mexicanBanks() {
    return [
      BankAppConfig(
        packageName: 'com.bbva.bancomer',
        bundleId: 'com.bbva.mobile',
        displayName: 'BBVA',
        keywords: ['cargo', 'compra', 'retiro', 'pago', 'abono', 'transferencia'],
        amountPattern: RegExp(r'\$\s?([\d,]+\.?\d*)'),
      ),
      BankAppConfig(
        packageName: 'com.banorte.movil',
        bundleId: 'mx.com.banorte',
        displayName: 'Banorte',
        keywords: ['cargo', 'compra', 'retiro', 'depósito', 'transferencia'],
        amountPattern: RegExp(r'\$\s?([\d,]+\.?\d*)'),
      ),
      BankAppConfig(
        packageName: 'com.santander.app',
        bundleId: 'com.santander.supermovil',
        displayName: 'Santander',
        keywords: ['cargo', 'compra', 'pago', 'transferencia'],
        amountPattern: RegExp(r'\$\s?([\d,]+\.?\d*)'),
      ),
      BankAppConfig(
        packageName: 'com.scotiabank.mobile',
        bundleId: 'com.scotiabank.mx',
        displayName: 'Scotiabank',
        keywords: ['cargo', 'compra', 'retiro', 'depósito'],
        amountPattern: RegExp(r'\$\s?([\d,]+\.?\d*)'),
      ),
      BankAppConfig(
        packageName: 'mx.com.citibanamex.banamexmobile',
        bundleId: 'com.banamex.mobile',
        displayName: 'Citibanamex',
        keywords: ['cargo', 'compra', 'pago', 'transferencia'],
        amountPattern: RegExp(r'\$\s?([\d,]+\.?\d*)'),
      ),
      BankAppConfig(
        packageName: 'mx.bancoppel.appbancoppel',
        bundleId: 'mx.bancoppel.mobile',
        displayName: 'BanCoppel',
        keywords: ['cargo', 'compra', 'retiro'],
        amountPattern: RegExp(r'\$\s?([\d,]+\.?\d*)'),
      ),
      BankAppConfig(
        packageName: 'com.google.android.apps.walletnfcrel',
        bundleId: 'com.google.wallet',
        displayName: 'Google Wallet',
        keywords: ['pagaste', 'pago', 'compra'],
        amountPattern: RegExp(r'\$\s?([\d,]+\.?\d*)'),
      ),
    ];
  }
}

/// Modelo de notificación bancaria detectada
class BankNotification {
  final String appName;
  final String title;
  final String body;
  final DateTime timestamp;
  final double? amount;
  final String? transactionType; // 'cargo', 'abono', 'transferencia'
  final String? merchant; // Comercio donde se realizó la compra

  BankNotification({
    required this.appName,
    required this.title,
    required this.body,
    required this.timestamp,
    this.amount,
    this.transactionType,
    this.merchant,
  });

  /// Detectar si es un cargo (gasto) o abono (ingreso)
  bool get isExpense {
    final text = '$title $body'.toLowerCase();
    return text.contains('cargo') || 
           text.contains('compra') || 
           text.contains('retiro') ||
           text.contains('pago');
  }

  bool get isIncome {
    final text = '$title $body'.toLowerCase();
    return text.contains('abono') || 
           text.contains('depósito') ||
           text.contains('transferencia recibida');
  }

  /// Convertir a Transaction
  Transaction toTransaction({required int categoryId}) {
    return Transaction(
      id: DateTime.now().millisecondsSinceEpoch,
      type: isExpense ? 'gasto' : 'ingreso',
      amount: amount ?? 0.0,
      categoryId: categoryId,
      note: merchant ?? 'Detectado automáticamente: $appName',
      date: timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'app_name': appName,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'amount': amount,
      'transaction_type': transactionType,
      'merchant': merchant,
    };
  }
}

/// Servicio para procesar notificaciones bancarias
class NotificationParserService {
  /// Extraer monto de un texto
  static double? extractAmount(String text, RegExp? pattern) {
    final defaultPattern = RegExp(r'\$\s?([\d,]+\.?\d*)');
    final match = (pattern ?? defaultPattern).firstMatch(text);
    
    if (match != null && match.groupCount >= 1) {
      final amountStr = match.group(1)?.replaceAll(',', '') ?? '0';
      return double.tryParse(amountStr);
    }
    return null;
  }

  /// Detectar tipo de transacción
  static String? detectTransactionType(String text) {
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('cargo') || lowerText.contains('compra')) {
      return 'cargo';
    } else if (lowerText.contains('abono') || lowerText.contains('depósito')) {
      return 'abono';
    } else if (lowerText.contains('transferencia')) {
      return 'transferencia';
    } else if (lowerText.contains('retiro')) {
      return 'retiro';
    }
    
    return null;
  }

  /// Extraer nombre del comercio
  static String? extractMerchant(String text) {
    // Patrones comunes:
    // "Compra en OXXO"
    // "Cargo en WALMART"
    // "Pago a NETFLIX"
    
    final patterns = [
      RegExp(r'(?:compra|cargo|pago)\s+(?:en|a)\s+([A-Z\s]+)', caseSensitive: false),
      RegExp(r'en\s+([A-Z][A-Z\s]+\b)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        return match.group(1)?.trim();
      }
    }
    
    return null;
  }

  /// Procesar notificación y crear BankNotification
  static BankNotification? parseNotification({
    required String appName,
    required String title,
    required String body,
    required BankAppConfig config,
  }) {
    final fullText = '$title $body';
    
    // Verificar si contiene palabras clave
    final hasKeyword = config.keywords.any((keyword) => 
      fullText.toLowerCase().contains(keyword.toLowerCase())
    );
    
    if (!hasKeyword) return null;
    
    // Extraer información
    final amount = extractAmount(fullText, config.amountPattern);
    final type = detectTransactionType(fullText);
    final merchant = extractMerchant(fullText);
    
    // Solo crear si encontramos un monto válido
    if (amount == null || amount <= 0) return null;
    
    return BankNotification(
      appName: appName,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      amount: amount,
      transactionType: type,
      merchant: merchant,
    );
  }

  /// Sugerir categoría basada en el comercio
  static Future<int?> suggestCategory(String? merchant) async {
    if (merchant == null) return null;
    
    final merchantLower = merchant.toLowerCase();
    
    // Obtener todas las categorías
    final categories = await SupabaseService().getAllCategories();
    
    // Mapeo de comercios comunes a categorías
    final Map<String, String> merchantToCategoryMap = {
      // Comida
      'oxxo': 'Comida',
      'seven': 'Comida',
      '7-eleven': 'Comida',
      'mcdonalds': 'Comida',
      'burger': 'Comida',
      'pizza': 'Comida',
      'starbucks': 'Comida',
      'restaurante': 'Comida',
      
      // Compras
      'walmart': 'Compras',
      'soriana': 'Compras',
      'chedraui': 'Compras',
      'amazon': 'Compras',
      'mercadolibre': 'Compras',
      'liverpool': 'Compras',
      
      // Transporte
      'uber': 'Transporte',
      'didi': 'Transporte',
      'gasolina': 'Transporte',
      'pemex': 'Transporte',
      
      // Servicios
      'netflix': 'Servicios',
      'spotify': 'Servicios',
      'disney': 'Servicios',
      'hbo': 'Servicios',
      'amazon prime': 'Servicios',
      
      // Salud
      'farmacia': 'Salud',
      'farmacias': 'Salud',
      'hospital': 'Salud',
      'doctor': 'Salud',
    };
    
    // Buscar coincidencia
    for (final entry in merchantToCategoryMap.entries) {
      if (merchantLower.contains(entry.key)) {
        // Buscar categoría por nombre
        final category = categories.firstWhere(
          (c) => (c['name'] as String).toLowerCase() == entry.value.toLowerCase(),
          orElse: () => <String, dynamic>{},
        );
        
        if (category.isNotEmpty) {
          return category['id'] as int;
        }
      }
    }
    
    // Si no hay coincidencia, retornar categoría "Compras" por defecto
    final defaultCategory = categories.firstWhere(
      (c) => (c['name'] as String).toLowerCase() == 'compras',
      orElse: () => categories.isNotEmpty ? categories.first : <String, dynamic>{},
    );
    
    return defaultCategory.isNotEmpty ? defaultCategory['id'] as int : null;
  }
}
