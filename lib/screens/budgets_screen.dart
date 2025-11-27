import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/supabase_service.dart';
import '../models/category.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _budgets = [];
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBudgets();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Recargar cuando la app vuelve a estar en primer plano
    if (state == AppLifecycleState.resumed) {
      _loadBudgets();
    }
  }
  
  Future<void> _loadBudgets() async {
    final budgets = await SupabaseService().getAllBudgets();
    if (mounted) {
      setState(() {
        _budgets = budgets;
        _loading = false;
      });
    }
  }
  
  Future<void> _deleteBudget(int id) async {
    await SupabaseService().deleteBudget(id);
    _loadBudgets();
  }
  
  void _showCreateBudgetDialog() async {
    final categories = await SupabaseService().getAllCategories();
    final expenseCategories = categories.where((c) => c['type'] == 'egreso').toList();
    
    if (!mounted) return;
    
    int? selectedCategoryId;
    String? selectedCategoryName;
    double? amount;
    String period = 'monthly';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: FynceeColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Nuevo Presupuesto',
            style: TextStyle(
              color: FynceeColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Categoría',
                  style: TextStyle(
                    color: FynceeColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: FynceeColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: selectedCategoryId,
                      hint: const Text(
                        'Selecciona una categoría',
                        style: TextStyle(color: FynceeColors.textSecondary),
                      ),
                      dropdownColor: FynceeColors.background,
                      items: expenseCategories.map((category) {
                        return DropdownMenuItem<int>(
                          value: category['id'] as int,
                          child: Row(
                            children: [
                              Text(
                                category['emoji'] as String,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                category['name'] as String,
                                style: const TextStyle(
                                  color: FynceeColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategoryId = value;
                          // Encontrar el nombre de la categoría seleccionada
                          final category = expenseCategories.firstWhere(
                            (cat) => cat['id'] == value,
                            orElse: () => {'name': 'Presupuesto'},
                          );
                          selectedCategoryName = category['name'] as String?;
                        });
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                const Text(
                  'Monto',
                  style: TextStyle(
                    color: FynceeColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: FynceeColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: const TextStyle(color: FynceeColors.textSecondary),
                    prefixText: '\$ ',
                    prefixStyle: const TextStyle(
                      color: FynceeColors.textPrimary,
                      fontSize: 16,
                    ),
                    filled: true,
                    fillColor: FynceeColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    amount = double.tryParse(value);
                  },
                ),
                
                const SizedBox(height: 16),
                
                const Text(
                  'Período',
                  style: TextStyle(
                    color: FynceeColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: FynceeColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: period,
                      dropdownColor: FynceeColors.background,
                      items: const [
                        DropdownMenuItem(
                          value: 'monthly',
                          child: Text(
                            'Mensual',
                            style: TextStyle(color: FynceeColors.textPrimary),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'yearly',
                          child: Text(
                            'Anual',
                            style: TextStyle(color: FynceeColors.textPrimary),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => period = value);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: FynceeColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedCategoryId != null && amount != null && amount! > 0) {
                  await SupabaseService().createBudget(
                    categoryId: selectedCategoryId!,
                    amount: amount!,
                    period: period,
                    name: selectedCategoryName ?? 'Presupuesto',
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    _loadBudgets();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: FynceeColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FynceeColors.background,
      appBar: AppBar(
        backgroundColor: FynceeColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: FynceeColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Presupuestos',
          style: TextStyle(
            color: FynceeColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: FynceeColors.primary),
            onPressed: _showCreateBudgetDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _budgets.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadBudgets,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _budgets.length,
                    itemBuilder: (context, index) {
                      final budget = _budgets[index];
                      return _buildBudgetCard(budget);
                    },
                  ),
                ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: FynceeColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pie_chart_outline_rounded,
              size: 40,
              color: FynceeColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay presupuestos',
            style: TextStyle(
              color: FynceeColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea presupuestos para controlar tus gastos',
            style: TextStyle(
              color: FynceeColors.textSecondary.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateBudgetDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Crear presupuesto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: FynceeColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBudgetCard(Map<String, dynamic> budget) {
    final category = budget['categories'] as Map<String, dynamic>?;
    final categoryName = category?['name'] as String? ?? 'Sin categoría';
    final categoryEmoji = category?['emoji'] as String? ?? '📁';
    final amount = (budget['amount'] as num).toDouble();
    final period = budget['period'] as String;
    
    // Obtener gasto actual (esto debería venir de la BD con una consulta join)
    return FutureBuilder<double>(
      future: SupabaseService().getCategorySpent(budget['category_id'] as int, period),
      builder: (context, snapshot) {
        final spent = snapshot.data ?? 0.0;
        final percentage = amount > 0 ? (spent / amount).clamp(0.0, 1.0) : 0.0;
        final isOverBudget = spent > amount;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FynceeColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: isOverBudget
                ? Border.all(color: Colors.red.withValues(alpha: 0.5))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: FynceeColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(categoryEmoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName,
                          style: const TextStyle(
                            color: FynceeColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          period == 'monthly' ? 'Mensual' : 'Anual',
                          style: TextStyle(
                            color: FynceeColors.textSecondary.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded, color: Colors.red),
                    onPressed: () => _deleteBudget(budget['id'] as int),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Barra de progreso
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 8,
                  backgroundColor: FynceeColors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverBudget ? Colors.red : FynceeColors.primary,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gastado',
                        style: TextStyle(
                          color: FynceeColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '\$${spent.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isOverBudget ? Colors.red : FynceeColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Presupuesto',
                        style: TextStyle(
                          color: FynceeColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '\$${amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: FynceeColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              if (isOverBudget)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_rounded, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Presupuesto excedido por \$${(spent - amount).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
