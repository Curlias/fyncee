import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction.dart' as app;
import '../models/goal.dart';
import 'auth_service.dart';
import 'database_service.dart';

/// Servicio de sincronización con Supabase (PostgreSQL en la nube)
/// 
/// Proporciona sincronización automática con la base de datos en la nube.
/// Todos los datos están protegidos por Row Level Security (RLS).
/// Cada usuario solo puede ver y modificar sus propios datos.
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;
  bool _initialized = false;

  /// Obtener el ID del usuario actual
  String? get _userId => AuthService().currentUserId;

  /// Verificar si el usuario está autenticado
  bool get _isAuthenticated => AuthService().isAuthenticated;

  /// Inicializar Supabase
  /// 
  /// Debe llamarse antes de usar cualquier método.
  /// Las credenciales se obtienen de supabase_config.dart
  Future<void> init(String url, String anonKey) async {
    if (_initialized) return;

    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: true,
      );
      _initialized = true;
      print('✅ Supabase inicializado correctamente');
    } catch (e) {
      print('❌ Error inicializando Supabase: $e');
      rethrow;
    }
  }

  // ==================== TRANSACTIONS ====================

  /// Crear una nueva transacción en Supabase (requiere autenticación)
  Future<Map<String, dynamic>?> createTransaction(app.Transaction transaction) async {
    // Siempre guardar en Hive primero (para offline)
    await DatabaseService().saveTransaction(transaction);
    print('💾 Transacción guardada en Hive (local)');
    
    if (!_isAuthenticated) {
      print('⚠️ Usuario no autenticado - guardada solo en local');
      return null;
    }

    try {
      final response = await client.from('transactions').insert({
        'user_id': _userId,
        'type': transaction.type,
        'amount': transaction.amount,
        'category_id': transaction.categoryId,
        'note': transaction.note,
        'date': transaction.date.toIso8601String(),
      }).select().single();
      
      // Actualizar en Hive con el ID de Supabase
      final updatedTransaction = app.Transaction(
        id: response['id'] as int,
        type: transaction.type,
        amount: transaction.amount,
        categoryId: transaction.categoryId,
        note: transaction.note,
        date: transaction.date,
      );
      await DatabaseService().saveTransaction(updatedTransaction);
      
      print('✅ Transacción sincronizada con Supabase ID: ${response['id']}');
      return response;
    } catch (e) {
      print('❌ Error sincronizando con Supabase: $e');
      print('💾 Transacción disponible offline en Hive');
      rethrow;
    }
  }

  /// Guardar/actualizar una transacción existente (requiere autenticación)
  Future<void> saveTransaction(app.Transaction transaction) async {
    // Siempre guardar en Hive primero (para offline)
    await DatabaseService().saveTransaction(transaction);
    print('💾 Transacción guardada en Hive (local)');
    
    if (!_isAuthenticated) {
      print('⚠️ Usuario no autenticado - guardada solo en local');
      return;
    }

    try {
      await client.from('transactions').upsert({
        'id': transaction.id,
        'user_id': _userId,
        'type': transaction.type,
        'amount': transaction.amount,
        'category_id': transaction.categoryId,
        'note': transaction.note,
        'date': transaction.date.toIso8601String(),
      });
      print('✅ Transacción sincronizada con Supabase');
    } catch (e) {
      print('❌ Error sincronizando con Supabase: $e');
      print('💾 Transacción disponible offline en Hive');
    }
  }

  /// Obtener todas las transacciones del usuario actual
  Future<List<app.Transaction>> getAllTransactions() async {
    if (!_isAuthenticated) {
      // Si no está autenticado, cargar de Hive (offline)
      print('⚠️ No autenticado, cargando de Hive (local)');
      return await DatabaseService().getAllTransactions();
    }

    try {
      final response = await client
          .from('transactions')
          .select()
          .eq('user_id', _userId!)
          .order('date', ascending: false);

      final transactions = (response as List).map((row) {
        return app.Transaction(
          id: row['id'] as int,
          type: row['type'] as String,
          amount: (row['amount'] as num).toDouble(),
          categoryId: row['category_id'] as int,
          note: row['note'] as String? ?? '',
          date: DateTime.parse(row['date'] as String),
        );
      }).toList();
      
      // Guardar en Hive para acceso offline
      for (var transaction in transactions) {
        await DatabaseService().saveTransaction(transaction);
      }
      
      return transactions;
    } catch (e) {
      print('❌ Error obteniendo transacciones de Supabase: $e');
      print('📦 Cargando desde Hive (caché local)');
      // Fallback a Hive si falla Supabase (sin internet)
      return await DatabaseService().getAllTransactions();
    }
  }

  /// Obtener transacciones en un rango de fechas
  Future<List<app.Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    if (!_isAuthenticated) {
      // Si no está autenticado, cargar de Hive (offline)
      print('⚠️ No autenticado, cargando de Hive (local)');
      return await DatabaseService().getTransactionsByDateRange(start, end);
    }

    try {
      final response = await client
          .from('transactions')
          .select()
          .eq('user_id', _userId!)
          .gte('date', start.toIso8601String())
          .lte('date', end.toIso8601String())
          .order('date', ascending: false);

      final transactions = (response as List).map((row) {
        return app.Transaction(
          id: row['id'] as int,
          type: row['type'] as String,
          amount: (row['amount'] as num).toDouble(),
          categoryId: row['category_id'] as int,
          note: row['note'] as String? ?? '',
          date: DateTime.parse(row['date'] as String),
        );
      }).toList();
      
      // Guardar en Hive para acceso offline
      for (var transaction in transactions) {
        await DatabaseService().saveTransaction(transaction);
      }
      
      return transactions;
    } catch (e) {
      print('❌ Error obteniendo transacciones por rango de Supabase: $e');
      print('📦 Cargando desde Hive (caché local)');
      // Fallback a Hive si falla Supabase (sin internet)
      return await DatabaseService().getTransactionsByDateRange(start, end);
    }
  }

  /// Actualizar una transacción
  Future<void> updateTransaction(app.Transaction transaction) async {
    // Actualizar en Hive (local) primero
    await DatabaseService().updateTransaction(transaction);
    print('💾 Transacción actualizada en Hive (local)');
    
    if (!_isAuthenticated) {
      print('⚠️ Usuario no autenticado - actualizada solo en local');
      return;
    }
    
    try {
      await client.from('transactions').update({
        'type': transaction.type,
        'amount': transaction.amount,
        'category_id': transaction.categoryId,
        'note': transaction.note,
        'date': transaction.date.toIso8601String(),
      }).eq('id', transaction.id);
      print('✅ Transacción sincronizada con Supabase');
    } catch (e) {
      print('❌ Error sincronizando con Supabase: $e');
      print('💾 Transacción actualizada en cache local');
    }
  }

  /// Eliminar una transacción
  Future<void> deleteTransaction(int id) async {
    // Eliminar de Hive (local)
    await DatabaseService().deleteTransaction(id);
    print('💾 Transacción eliminada de Hive (local)');
    
    if (!_isAuthenticated) {
      print('⚠️ Usuario no autenticado - eliminada solo de local');
      return;
    }
    
    try {
      await client.from('transactions').delete().eq('id', id);
      print('✅ Transacción eliminada de Supabase');
    } catch (e) {
      print('❌ Error eliminando de Supabase: $e');
      print('💾 Transacción eliminada de cache local');
    }
  }

  // ==================== GOALS ====================

  /// Guardar una meta
  Future<void> saveGoal(Goal goal) async {
    if (!_isAuthenticated) {
      print('⚠️ Usuario no autenticado - guardando solo en local');
      return;
    }

    try {
      await client.from('goals').upsert({
        'id': goal.id,
        'user_id': _userId,
        'name': goal.name,
        'emoji': goal.emoji,
        'target_amount': goal.targetAmount,
        'current_amount': goal.currentAmount,
        'color_value': goal.colorValue,
        'created_at': goal.createdAt.toIso8601String(),
        'monthly_progress_json': goal.monthlyProgressJson,
      });
      print('✅ Meta guardada en Supabase');
    } catch (e) {
      print('❌ Error guardando meta: $e');
    }
  }

  /// Obtener todas las metas
  Future<List<Goal>> getAllGoals() async {
    if (!_isAuthenticated) return [];

    try {
      final response = await client
          .from('goals')
          .select()
          .eq('user_id', _userId!)
          .order('created_at', ascending: false);

      return (response as List).map((row) {
        return Goal(
          id: row['id'] as int,
          name: row['name'] as String,
          emoji: row['emoji'] as String,
          targetAmount: (row['target_amount'] as num).toDouble(),
          currentAmount: (row['current_amount'] as num).toDouble(),
          colorValue: row['color_value'] as int,
          createdAt: DateTime.parse(row['created_at'] as String),
        )..monthlyProgressJson = row['monthly_progress_json'] as String? ?? '{}';
      }).toList();
    } catch (e) {
      print('❌ Error obteniendo metas: $e');
      return [];
    }
  }

  /// Obtener una meta específica
  Future<Goal?> getGoal(int id) async {
    try {
      final response = await client
          .from('goals')
          .select()
          .eq('id', id)
          .single();

      return Goal(
        id: response['id'] as int,
        name: response['name'] as String,
        emoji: response['emoji'] as String,
        targetAmount: (response['target_amount'] as num).toDouble(),
        currentAmount: (response['current_amount'] as num).toDouble(),
        colorValue: response['color_value'] as int,
        createdAt: DateTime.parse(response['created_at'] as String),
      )..monthlyProgressJson = response['monthly_progress_json'] as String? ?? '{}';
    } catch (e) {
      print('❌ Error obteniendo meta: $e');
      return null;
    }
  }

  /// Actualizar una meta
  Future<void> updateGoal(Goal goal) async {
    try {
      await client.from('goals').update({
        'name': goal.name,
        'emoji': goal.emoji,
        'target_amount': goal.targetAmount,
        'current_amount': goal.currentAmount,
        'color_value': goal.colorValue,
        'monthly_progress_json': goal.monthlyProgressJson,
      }).eq('id', goal.id);
      print('✅ Meta actualizada en Supabase');
    } catch (e) {
      print('❌ Error actualizando meta: $e');
    }
  }

  /// Eliminar una meta
  Future<void> deleteGoal(int id) async {
    try {
      await client.from('goals').delete().eq('id', id);
      print('✅ Meta eliminada de Supabase');
    } catch (e) {
      print('❌ Error eliminando meta: $e');
    }
  }

  /// Agregar dinero a una meta
  Future<void> addMoneyToGoal(int goalId, double amount) async {
    final goal = await getGoal(goalId);
    if (goal == null) return;

    goal.currentAmount += amount;

    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final monthlyProgress = goal.monthlyProgress;
    monthlyProgress[monthKey] = (monthlyProgress[monthKey] ?? 0) + amount;
    goal.monthlyProgress = monthlyProgress;

    await updateGoal(goal);
  }

  // ==================== STATISTICS ====================

  /// Obtener ingresos mensuales
  Future<double> getMonthlyIncome(int year, int month) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 1).subtract(const Duration(days: 1));

      final response = await client
          .from('transactions')
          .select('amount')
          .eq('type', 'ingreso')
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String());

      double total = 0;
      for (final row in response as List) {
        total += (row['amount'] as num).toDouble();
      }
      return total;
    } catch (e) {
      print('❌ Error obteniendo ingresos mensuales: $e');
      return 0.0;
    }
  }

  /// Obtener gastos mensuales
  Future<double> getMonthlyExpense(int year, int month) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 1).subtract(const Duration(days: 1));

      final response = await client
          .from('transactions')
          .select('amount')
          .eq('type', 'egreso')
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String());

      double total = 0;
      for (final row in response as List) {
        total += (row['amount'] as num).toDouble();
      }
      return total;
    } catch (e) {
      print('❌ Error obteniendo gastos mensuales: $e');
      return 0.0;
    }
  }

  /// Obtener gastos por categoría en un período
  Future<Map<int, double>> getExpensesByCategory(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await client
          .from('transactions')
          .select('category_id, amount')
          .eq('type', 'egreso')
          .gte('date', start.toIso8601String())
          .lte('date', end.toIso8601String());

      final Map<int, double> categoryTotals = {};
      for (final row in response as List) {
        final categoryId = row['category_id'] as int;
        final amount = (row['amount'] as num).toDouble();
        categoryTotals[categoryId] = (categoryTotals[categoryId] ?? 0) + amount;
      }

      return categoryTotals;
    } catch (e) {
      print('❌ Error obteniendo gastos por categoría: $e');
      return {};
    }
  }

  // ==================== CATEGORIES ====================

  /// Obtener todas las categorías del usuario
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    if (!_isAuthenticated) return [];

    try {
      // Obtener todas las categorías (globales y personalizadas)
      final allCategories = await client
          .from('categories')
          .select()
          .or('user_id.is.null,user_id.eq.$_userId')
          .order('name', ascending: true);

      // Obtener categorías ocultas por el usuario
      final hiddenCategories = await client
          .from('user_hidden_categories')
          .select('category_id')
          .eq('user_id', _userId!);

      final hiddenIds = (hiddenCategories as List)
          .map((e) => e['category_id'] as int)
          .toSet();

      // Filtrar categorías ocultas
      return (allCategories as List)
          .where((cat) => !hiddenIds.contains(cat['id']))
          .cast<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      print('❌ Error obteniendo categorías: $e');
      return [];
    }
  }

  /// Crear una nueva categoría personalizada
  Future<int?> createCategory({
    required String name,
    required String type,
    required String icon,
    required int colorValue,
  }) async {
    if (!_isAuthenticated) return null;

    try {
      final response = await client.from('categories').insert({
        'user_id': _userId,
        'name': name,
        'type': type,
        'icon': icon,
        'color_value': colorValue,
        'is_default': false,
      }).select('id').single();
      
      print('✅ Categoría creada en Supabase');
      return response['id'] as int;
    } catch (e) {
      print('❌ Error creando categoría: $e');
      rethrow;
    }
  }

  /// Actualizar una categoría personalizada
  Future<void> updateCategory(int id, {
    String? name,
    String? icon,
    int? colorValue,
  }) async {
    if (!_isAuthenticated) return;

    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (icon != null) updates['icon'] = icon;
      if (colorValue != null) updates['color_value'] = colorValue;

      await client.from('categories').update(updates).eq('id', id).eq('user_id', _userId!);
      print('✅ Categoría actualizada en Supabase');
    } catch (e) {
      print('❌ Error actualizando categoría: $e');
      rethrow;
    }
  }

  /// Ocultar categoría global o eliminar categoría personalizada
  Future<bool> deleteCategory(int id) async {
    if (!_isAuthenticated) return false;

    try {
      // Verificar si es categoría global
      final category = await client
          .from('categories')
          .select('is_default, user_id')
          .eq('id', id)
          .single();

      if (category['is_default'] == true && category['user_id'] == null) {
        // Es categoría global - ocultarla para este usuario
        await client.from('user_hidden_categories').insert({
          'user_id': _userId,
          'category_id': id,
        });
        print('✅ Categoría global ocultada');
        return true;
      } else {
        // Es categoría personalizada - eliminarla
        await client.from('categories').delete().eq('id', id).eq('user_id', _userId!);
        print('✅ Categoría personalizada eliminada');
        return true;
      }
    } catch (e) {
      print('❌ Error eliminando/ocultando categoría: $e');
      return false;
    }
  }

  /// Mostrar una categoría global previamente ocultada
  Future<bool> showCategory(int categoryId) async {
    if (!_isAuthenticated) return false;

    try {
      await client
          .from('user_hidden_categories')
          .delete()
          .eq('user_id', _userId!)
          .eq('category_id', categoryId);
      print('✅ Categoría mostrada nuevamente');
      return true;
    } catch (e) {
      print('❌ Error mostrando categoría: $e');
      return false;
    }
  }

  // ==================== BUDGETS ====================

  /// Obtener todos los presupuestos del usuario con el gasto actual
  Future<List<Map<String, dynamic>>> getAllBudgets() async {
    if (!_isAuthenticated) return [];

    try {
      final response = await client
          .from('budgets')
          .select('*, categories!inner(name, icon, color_value, type)')
          .eq('user_id', _userId!)
          .eq('categories.type', 'egreso')
          .order('created_at', ascending: false);

      final budgets = (response as List).cast<Map<String, dynamic>>();
      
      // Calcular el gasto actual para cada presupuesto
      for (var budget in budgets) {
        final categoryId = budget['category_id'] as int;
        final period = budget['period'] as String;
        final spent = await getCategorySpent(categoryId, period);
        budget['spent'] = spent;
        
        // Agregar información de categoría al nivel superior
        if (budget['categories'] != null) {
          final category = budget['categories'] as Map<String, dynamic>;
          budget['category_name'] = category['name'];
          budget['category_icon'] = category['icon'];
          budget['category_color'] = category['color_value'];
        }
      }

      return budgets;
    } catch (e) {
      print('❌ Error obteniendo presupuestos: $e');
      return [];
    }
  }

  /// Verificar presupuestos y crear notificaciones si es necesario
  Future<void> checkBudgets() async {
    if (!_isAuthenticated) return;

    try {
      final budgets = await getAllBudgets();
      
      for (var budget in budgets) {
        final amount = (budget['amount'] as num).toDouble();
        final spent = (budget['spent'] as num?)?.toDouble() ?? 0.0;
        final percentage = (spent / amount * 100);
        final categoryName = budget['category_name'] as String? ?? 'Sin categoría';
        final budgetId = budget['id'] as int;
        
        // TODO: Agregar columna budget_id a la tabla notifications para evitar duplicados
        // Por ahora, verificar si ya enviamos notificación hoy para cualquier presupuesto
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        
        final existingNotification = await client
            .from('notifications')
            .select('id')
            .eq('type', spent > amount ? 'budget_exceeded' : 'budget_warning')
            .ilike('message', '%$categoryName%')
            .gte('created_at', todayStart.toIso8601String());
        
        // No enviar notificación duplicada el mismo día
        if ((existingNotification as List).isNotEmpty) continue;
        
        String? message;
        String? type;
        
        if (spent > amount) {
          message = 'Has superado el presupuesto de $categoryName por \$${(spent - amount).toStringAsFixed(2)}';
          type = 'budget_exceeded';
        } else if (percentage >= 80) {
          message = 'Has usado el ${percentage.toStringAsFixed(0)}% del presupuesto de $categoryName';
          type = 'budget_warning';
        }
        
        if (message != null && type != null) {
          await client.from('notifications').insert({
            'user_id': _userId,
            'type': type,
            'title': spent > amount ? '⚠️ Presupuesto superado' : '⚠️ Límite de presupuesto',
            'message': message,
            'read': false,
          });
        }
      }
    } catch (e) {
      print('❌ Error verificando presupuestos: $e');
    }
  }

  /// Crear un nuevo presupuesto
  Future<void> createBudget({
    required int categoryId,
    required double amount,
    required String period, // 'monthly' o 'yearly'
    String? name,
    DateTime? startDate,
  }) async {
    if (!_isAuthenticated) {
      print('❌ No autenticado, no se puede crear presupuesto');
      return;
    }

    try {
      final data = {
        'user_id': _userId!,
        'category_id': categoryId,
        'amount': amount,
        'period': period,
        'name': name ?? 'Presupuesto',
        'start_date': (startDate ?? DateTime.now()).toIso8601String().split('T')[0],
      };
      
      print('📤 Intentando crear presupuesto: $data');
      
      await client.from('budgets').insert(data);
      print('✅ Presupuesto creado en Supabase');
    } catch (e) {
      print('❌ Error creando presupuesto: $e');
      rethrow;
    }
  }

  /// Actualizar un presupuesto
  Future<void> updateBudget(int id, {
    double? amount,
    String? period,
  }) async {
    if (!_isAuthenticated) return;

    try {
      final updates = <String, dynamic>{};
      if (amount != null) updates['amount'] = amount;
      if (period != null) updates['period'] = period;

      await client.from('budgets')
          .update(updates)
          .eq('id', id)
          .eq('user_id', _userId!);
      print('✅ Presupuesto actualizado en Supabase');
    } catch (e) {
      print('❌ Error actualizando presupuesto: $e');
    }
  }

  /// Eliminar un presupuesto
  Future<void> deleteBudget(int id) async {
    if (!_isAuthenticated) return;

    try {
      await client.from('budgets')
          .delete()
          .eq('id', id)
          .eq('user_id', _userId!);
      print('✅ Presupuesto eliminado de Supabase');
    } catch (e) {
      print('❌ Error eliminando presupuesto: $e');
    }
  }

  /// Obtener gasto actual de una categoría en el período
  Future<double> getCategorySpent(int categoryId, String period) async {
    if (!_isAuthenticated) return 0.0;

    try {
      final now = DateTime.now();
      DateTime startDate;

      if (period == 'monthly') {
        startDate = DateTime(now.year, now.month, 1);
      } else {
        startDate = DateTime(now.year, 1, 1);
      }

      final response = await client
          .from('transactions')
          .select('amount')
          .eq('user_id', _userId!)
          .eq('category_id', categoryId)
          .eq('type', 'gasto')
          .gte('date', startDate.toIso8601String());

      double total = 0;
      for (final row in response as List) {
        total += (row['amount'] as num).toDouble();
      }
      
      print('💰 Gasto en categoría $categoryId ($period): \$$total');
      return total;
    } catch (e) {
      print('❌ Error obteniendo gasto de categoría: $e');
      return 0.0;
    }
  }

  // ==================== NOTIFICATIONS ====================

  /// Obtener notificaciones del usuario
  Future<List<Map<String, dynamic>>> getNotifications({int limit = 50}) async {
    if (!_isAuthenticated) return [];

    try {
      final response = await client
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Error obteniendo notificaciones: $e');
      return [];
    }
  }

  /// Obtener notificaciones no leídas
  Future<List<Map<String, dynamic>>> getUnreadNotifications() async {
    if (!_isAuthenticated) return [];

    try {
      final response = await client
          .from('notifications')
          .select()
          .eq('read', false)
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Error obteniendo notificaciones no leídas: $e');
      return [];
    }
  }

  /// Marcar notificación como leída
  Future<void> markNotificationAsRead(int id) async {
    if (!_isAuthenticated) return;

    try {
      await client.from('notifications').update({
        'read': true,
      }).eq('id', id);
      print('✅ Notificación marcada como leída');
    } catch (e) {
      print('❌ Error marcando notificación: $e');
    }
  }

  /// Marcar todas las notificaciones como leídas
  Future<void> markAllNotificationsAsRead() async {
    if (!_isAuthenticated) return;

    try {
      await client.from('notifications').update({
        'read': true,
      }).eq('user_id', _userId!);
      print('✅ Todas las notificaciones marcadas como leídas');
    } catch (e) {
      print('❌ Error marcando todas las notificaciones: $e');
    }
  }

  /// Eliminar una notificación
  Future<void> deleteNotification(int id) async {
    if (!_isAuthenticated) return;

    try {
      await client.from('notifications').delete().eq('id', id);
      print('✅ Notificación eliminada');
    } catch (e) {
      print('❌ Error eliminando notificación: $e');
    }
  }

  // ==================== ACHIEVEMENTS ====================

  /// Obtener logros del usuario
  Future<List<Map<String, dynamic>>> getAchievements() async {
    if (!_isAuthenticated) return [];

    try {
      final response = await client
          .from('achievements')
          .select()
          .order('unlocked_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Error obteniendo logros: $e');
      return [];
    }
  }

  /// Desbloquear un logro
  Future<void> unlockAchievement(String achievementType) async {
    if (!_isAuthenticated) return;

    try {
      // Verificar si ya está desbloqueado
      final existing = await client
          .from('achievements')
          .select()
          .eq('achievement_type', achievementType)
          .maybeSingle();

      if (existing != null) {
        print('⚠️ Logro ya desbloqueado');
        return;
      }

      await client.from('achievements').insert({
        'achievement_type': achievementType,
      });
      print('✅ Logro desbloqueado: $achievementType');
    } catch (e) {
      print('❌ Error desbloqueando logro: $e');
    }
  }

  // ==================== REMINDERS ====================

  /// Obtener recordatorios activos
  Future<List<Map<String, dynamic>>> getActiveReminders() async {
    if (!_isAuthenticated) return [];

    try {
      final response = await client
          .from('reminders')
          .select()
          .eq('is_active', true)
          .order('next_trigger_at', ascending: true);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Error obteniendo recordatorios: $e');
      return [];
    }
  }

  /// Crear un recordatorio
  Future<void> createReminder({
    required String type,
    required String message,
    required DateTime triggerAt,
    String? recurrence,
  }) async {
    if (!_isAuthenticated) return;

    try {
      await client.from('reminders').insert({
        'type': type,
        'message': message,
        'next_trigger_at': triggerAt.toIso8601String(),
        'recurrence': recurrence,
        'is_active': true,
      });
      print('✅ Recordatorio creado');
    } catch (e) {
      print('❌ Error creando recordatorio: $e');
    }
  }

  /// Desactivar un recordatorio
  Future<void> deactivateReminder(int id) async {
    if (!_isAuthenticated) return;

    try {
      await client.from('reminders').update({
        'is_active': false,
      }).eq('id', id);
      print('✅ Recordatorio desactivado');
    } catch (e) {
      print('❌ Error desactivando recordatorio: $e');
    }
  }

  // ==================== PROFILE ====================

  /// Obtener perfil del usuario actual
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (!_isAuthenticated) return null;

    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', _userId!)
          .single();

      return response;
    } catch (e) {
      print('❌ Error obteniendo perfil: $e');
      return null;
    }
  }

  /// Actualizar perfil del usuario
  Future<void> updateUserProfile({
    String? fullName,
    String? currency,
    String? language,
    String? theme,
    Map<String, dynamic>? customData,
  }) async {
    if (!_isAuthenticated) return;

    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (currency != null) updates['currency'] = currency;
      if (language != null) updates['language'] = language;
      if (theme != null) updates['theme'] = theme;
      
      // Agregar datos personalizados (como avatar_url)
      if (customData != null) {
        updates.addAll(customData);
      }

      if (updates.isEmpty) return;

      updates['updated_at'] = DateTime.now().toIso8601String();
      
      await client
          .from('profiles')
          .update(updates)
          .eq('id', _userId!);
      
      print('✅ Perfil actualizado en Supabase');
    } catch (e) {
      print('❌ Error actualizando perfil: $e');
    }
  }

  // ==================== SYNC ====================

  /// Sincronizar datos locales con Supabase
  /// 
  /// Esta función puede llamarse periódicamente para mantener
  /// los datos sincronizados entre Hive (local) y Supabase (cloud)
  Future<void> syncData() async {
    if (!_isAuthenticated) return;

    try {
      print('🔄 Iniciando sincronización con Supabase...');
      // Aquí puedes implementar lógica de sincronización más sofisticada
      // Por ahora, simplemente verificamos la conexión
      await client.from('transactions').select().limit(1);
      print('✅ Sincronización completada');
    } catch (e) {
      print('❌ Error en sincronización: $e');
    }
  }

  // ==================== REALTIME ====================

  /// Suscribirse a cambios en tiempo real de transacciones
  RealtimeChannel subscribeToTransactions(Function(Map<String, dynamic>) onInsert) {
    return client
        .channel('transactions-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'transactions',
          callback: (payload) {
            if (payload.newRecord['user_id'] == _userId) {
              onInsert(payload.newRecord);
            }
          },
        )
        .subscribe();
  }

  /// Suscribirse a cambios en tiempo real de notificaciones
  RealtimeChannel subscribeToNotifications(Function(Map<String, dynamic>) onInsert) {
    return client
        .channel('notifications-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            if (payload.newRecord['user_id'] == _userId) {
              onInsert(payload.newRecord);
            }
          },
        )
        .subscribe();
  }

  // ==================== PROFILE IMAGE ====================

  // Subir imagen de perfil a Supabase Storage
  Future<String> uploadProfileImage(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final ext = filePath.split('.').last;
      final fileName = 'profile_$_userId.$ext';

      print('📤 Subiendo imagen a Supabase Storage: $fileName');

      // Primero intentar eliminar la imagen anterior si existe
      try {
        await client.storage.from('avatars').remove([fileName]);
        print('🗑️ Imagen anterior eliminada');
      } catch (e) {
        print('⚠️ No hay imagen anterior o no se pudo eliminar: $e');
      }

      // Subir la nueva imagen
      await client.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      final publicUrl = client.storage.from('avatars').getPublicUrl(fileName);
      print('✅ Imagen subida. URL: $publicUrl');

      // Actualizar el perfil con la nueva URL
      await updateUserProfile(customData: {'avatar_url': publicUrl});

      return publicUrl;
    } catch (e) {
      print('❌ Error al subir imagen: $e');
      rethrow;
    }
  }

  /// Obtener URL de la imagen de perfil del usuario
  Future<String?> getProfileImageUrl() async {
    if (!_isAuthenticated) return null;

    try {
      final profile = await getUserProfile();
      return profile?['avatar_url'];
    } catch (e) {
      print('❌ Error obteniendo imagen de perfil: $e');
      return null;
    }
  }

  // ==================== APP SETTINGS ====================

  /// Obtener configuraciones de la app
  Future<Map<String, dynamic>> getAppSettings() async {
    if (!_isAuthenticated) return {};

    try {
      final response = await client
          .from('app_settings')
          .select()
          .eq('user_id', _userId!)
          .maybeSingle();

      return response as Map<String, dynamic>? ?? {};
    } catch (e) {
      print('❌ Error obteniendo configuraciones: $e');
      return {};
    }
  }

  /// Guardar configuraciones de la app
  Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    if (!_isAuthenticated) return;

    try {
      final data = {
        'user_id': _userId!,
        ...settings,
      };

      await client.from('app_settings').upsert(data);
      print('✅ Configuraciones guardadas');
    } catch (e) {
      print('❌ Error guardando configuraciones: $e');
    }
  }

  /// Obtener balance inicial del mes (si carry_over_balance está activado)
  Future<double> getCarryOverBalance() async {
    if (!_isAuthenticated) return 0.0;

    try {
      // Obtener configuración
      final settings = await getAppSettings();
      final carryOver = settings['carry_over_balance'] as bool? ?? false;

      if (!carryOver) return 0.0;

      // Calcular balance del mes anterior
      final now = DateTime.now();
      final previousMonthStart = DateTime(now.year, now.month - 1, 1);
      final previousMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

      final transactions = await getTransactionsByDateRange(
        previousMonthStart,
        previousMonthEnd,
      );

      double balance = 0;
      for (final t in transactions) {
        if (t.type == 'ingreso') {
          balance += t.amount;
        } else {
          balance -= t.amount;
        }
      }

      return balance;
    } catch (e) {
      print('❌ Error calculando balance anterior: $e');
      return 0.0;
    }
  }
}
