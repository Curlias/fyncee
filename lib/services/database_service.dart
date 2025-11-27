import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import 'supabase_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String _transactionsBox = 'transactions';
  static const String _goalsBox = 'goals';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    
    await Hive.initFlutter();
    
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(GoalAdapter());
    }
    
    await Hive.openBox<Transaction>(_transactionsBox);
    await Hive.openBox<Goal>(_goalsBox);
    
    _initialized = true;
  }

  Box<Transaction> get _transactions => Hive.box<Transaction>(_transactionsBox);

  Future<void> saveTransaction(Transaction transaction) async {
    await _transactions.put(transaction.id, transaction);
  }

  Future<List<Transaction>> getAllTransactions() async {
    return _transactions.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final transactions = await getAllTransactions();
    return transactions.where((t) {
      return t.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
          t.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  Future<List<Transaction>> getTransactionsByCategory(int categoryId) async {
    final transactions = await getAllTransactions();
    return transactions.where((t) => t.categoryId == categoryId).toList();
  }

  Future<void> deleteTransaction(int id) async {
    await _transactions.delete(id);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _transactions.put(transaction.id, transaction);
  }

  Box<Goal> get _goals => Hive.box<Goal>(_goalsBox);

  Future<void> saveGoal(Goal goal) async {
    // Guardar localmente en Hive
    await _goals.put(goal.id, goal);
    
    // Guardar en Supabase (cloud)
    try {
      await SupabaseService().saveGoal(goal);
      print('✅ Meta guardada en Supabase');
    } catch (e) {
      print('❌ Error guardando meta en Supabase: $e');
    }
  }

  Future<List<Goal>> getAllGoals() async {
    // Primero intentar cargar de Supabase
    try {
      final cloudGoals = await SupabaseService().getAllGoals();
      
      // Limpiar Hive completamente antes de sincronizar
      // Esto evita que se mezclen metas de diferentes usuarios
      await _goals.clear();
      
      // Sincronizar las metas del usuario actual desde Supabase
      for (final goal in cloudGoals) {
        await _goals.put(goal.id, goal);
      }
      
      return cloudGoals..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('⚠️ No se pudieron cargar metas de Supabase: $e');
      // Si falla Supabase, NO usar Hive porque podría tener datos de otro usuario
      // Retornar lista vacía para evitar mostrar datos incorrectos
      return [];
    }
  }

  Future<Goal?> getGoal(int id) async {
    return _goals.get(id);
  }

  Future<void> updateGoal(Goal goal) async {
    // Actualizar localmente
    await _goals.put(goal.id, goal);
    
    // Actualizar en Supabase
    try {
      await SupabaseService().saveGoal(goal);
      print('✅ Meta actualizada en Supabase');
    } catch (e) {
      print('❌ Error actualizando meta en Supabase: $e');
    }
  }

  Future<void> deleteGoal(int id) async {
    await _goals.delete(id);
    
    // También eliminar de Supabase
    try {
      await SupabaseService().deleteGoal(id);
      print('✅ Meta eliminada de Supabase');
    } catch (e) {
      print('❌ Error eliminando meta de Supabase: $e');
    }
  }

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

  Future<double> getMonthlyIncome(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);
    final transactions = await getTransactionsByDateRange(start, end);
    
    double total = 0.0;
    for (final t in transactions) {
      if (t.isIncome) total += t.amount;
    }
    return total;
  }

  Future<double> getMonthlyExpense(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);
    final transactions = await getTransactionsByDateRange(start, end);
    
    double total = 0.0;
    for (final t in transactions) {
      if (!t.isIncome) total += t.amount;
    }
    return total;
  }

  Future<Map<int, double>> getCategoryTotals(
    DateTime start,
    DateTime end,
    bool isIncome,
  ) async {
    final transactions = await getTransactionsByDateRange(start, end);
    final filtered = transactions.where((t) => t.isIncome == isIncome);
    
    final Map<int, double> totals = {};
    for (final transaction in filtered) {
      totals[transaction.categoryId] =
          (totals[transaction.categoryId] ?? 0) + transaction.amount;
    }
    
    return totals;
  }

  Future<void> clearAllData() async {
    await _transactions.clear();
    await _goals.clear();
  }

  Future<void> close() async {
    await Hive.close();
    _initialized = false;
  }
}
