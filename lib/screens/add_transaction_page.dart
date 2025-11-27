import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import '../services/supabase_service.dart';
import '../theme.dart';

class AddTransactionPage extends StatefulWidget {
  final Transaction? transactionToEdit;
  
  const AddTransactionPage({super.key, this.transactionToEdit});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final List<String> _types = const ['Gasto', 'Ingreso'];

  String _selectedType = 'Gasto';
  int? _selectedCategoryId;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;
  
  bool get isEditing => widget.transactionToEdit != null;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (isEditing) {
      final transaction = widget.transactionToEdit!;
      _amountController.text = transaction.amount.abs().toString();
      _noteController.text = transaction.note ?? '';
      _selectedType = transaction.type == 'income' ? 'Ingreso' : 'Gasto';
      _selectedCategoryId = transaction.categoryId;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await SupabaseService().getAllCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
        // Si no hay categoría seleccionada O si la categoría actual no es del tipo correcto
        if (_selectedCategoryId == null || !_isCategoryOfCurrentType()) {
          final typeCategories = categories.where((c) => 
            c['type'] == (_selectedType == 'Gasto' ? 'egreso' : 'ingreso')
          ).toList();
          if (typeCategories.isNotEmpty) {
            _selectedCategoryId = typeCategories.first['id'] as int;
          }
        }
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando categorías: $e')),
        );
      }
    }
  }

  bool _isCategoryOfCurrentType() {
    if (_selectedCategoryId == null || _categories.isEmpty) return false;
    final category = _categories.firstWhere(
      (c) => c['id'] == _selectedCategoryId,
      orElse: () => <String, dynamic>{},
    );
    if (category.isEmpty) return false;
    final expectedType = _selectedType == 'Gasto' ? 'egreso' : 'ingreso';
    return category['type'] == expectedType;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FynceeColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Editar movimiento' : 'Añadir movimiento'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type selector
              Container(
                decoration: BoxDecoration(
                  color: FynceeColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: _types.map((type) {
                    final isSelected = _selectedType == type;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedType = type;
                            // Actualizar categoría seleccionada al primer elemento del nuevo tipo
                            final typeCategories = _categories.where((c) => 
                              c['type'] == (type == 'Gasto' ? 'egreso' : 'ingreso')
                            ).toList();
                            if (typeCategories.isNotEmpty) {
                              _selectedCategoryId = typeCategories.first['id'] as int;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? FynceeColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            type,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected
                                  ? FynceeColors.background
                                  : FynceeColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 28),

              // Amount input
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: FynceeColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$ ',
                  prefixStyle: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: FynceeColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
                validator: _validateAmount,
              ),
              const SizedBox(height: 32),

              // Category selector
              Text(
                'Categoría',
                style: TextStyle(
                  color: FynceeColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: _categories.where((c) => 
                        c['type'] == (_selectedType == 'Gasto' ? 'egreso' : 'ingreso')
                      ).length,
                      itemBuilder: (context, index) {
                        final filteredCategories = _categories.where((c) => 
                          c['type'] == (_selectedType == 'Gasto' ? 'egreso' : 'ingreso')
                        ).toList();
                        final category = filteredCategories[index];
                        final isSelected = _selectedCategoryId == category['id'];
                        final color = Color(category['color_value'] as int);
                        final icon = _getIconData(category['icon'] as String);
                        
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategoryId = category['id'] as int),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withValues(alpha: 0.2)
                                  : FynceeColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? color : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  icon,
                                  color: isSelected ? color : FynceeColors.textSecondary,
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  category['name'] as String,
                                  style: TextStyle(
                                    color: isSelected ? color : FynceeColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 28),

              // Note input
              TextFormField(
                controller: _noteController,
                minLines: 3,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: FynceeColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nota (opcional)',
                  hintText: 'Agrega un comentario...',
                  alignLabelWithHint: true,
                  suffixIcon: _noteController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _noteController.clear();
                            setState(() {});
                          },
                          icon: Icon(
                            Icons.clear_rounded,
                            color: FynceeColors.textSecondary,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),

              // Save button
              ElevatedButton(
                onPressed: _handleSave,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Guardar movimiento',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateAmount(String? value) {
    final cleaned = value?.replaceAll(',', '.').trim();
    if (cleaned == null || cleaned.isEmpty) {
      return 'Ingresa un monto válido';
    }

    final amount = double.tryParse(cleaned);
    if (amount == null || amount <= 0) {
      return 'El monto debe ser mayor a 0';
    }

    return null;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría')),
      );
      return;
    }

    final cleanedAmountText = _amountController.text
        .replaceAll(',', '.')
        .trim();
    final amount = double.parse(cleanedAmountText);
    final note = _noteController.text.trim();

    print('🔍 DEBUG - Guardando transacción:');
    print('  Tipo: $_selectedType');
    print('  Categoría ID seleccionada: $_selectedCategoryId');
    print('  Monto: $amount');
    final selectedCat = _categories.firstWhere((c) => c['id'] == _selectedCategoryId);
    print('  Categoría encontrada: ${selectedCat['name']} (ID: ${selectedCat['id']})');

    final transaction = Transaction(
      id: isEditing ? widget.transactionToEdit!.id : DateTime.now().millisecondsSinceEpoch,
      type: _selectedType.toLowerCase(),
      amount: amount,
      categoryId: _selectedCategoryId!,
      note: note.isEmpty ? null : note,
      date: isEditing ? widget.transactionToEdit!.date : DateTime.now(),
    );

    // Guardar en Supabase si estamos editando
    if (isEditing) {
      try {
        await SupabaseService().updateTransaction(transaction);
      } catch (e) {
        print('Error actualizando transacción: $e');
      }
    }

    final category = _categories.firstWhere((c) => c['id'] == _selectedCategoryId);
    final formattedAmount = NumberFormat.currency(
      locale: Intl.getCurrentLocale(),
      symbol: '\$',
      decimalDigits: 2,
    ).format(transaction.amount);
    final noteLine = transaction.note == null
        ? ''
        : '\nNota: ${transaction.note}';
    final snackMessage =
        '${isEditing ? 'ACTUALIZADO' : _selectedType.toUpperCase()} · $formattedAmount · ${category['name']}$noteLine';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: FynceeColors.surface,
        content: Text(
          snackMessage,
          style: TextStyle(color: FynceeColors.textPrimary),
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    Navigator.of(context).pop(isEditing ? true : transaction);
  }

  IconData _getIconData(String iconName) {
    final iconMap = {
      'restaurant': Icons.restaurant,
      'directions_car': Icons.directions_car,
      'movie': Icons.movie,
      'shopping_bag': Icons.shopping_bag,
      'local_hospital': Icons.local_hospital,
      'school': Icons.school,
      'build': Icons.build,
      'home': Icons.home,
      'more_horiz': Icons.more_horiz,
      'account_balance_wallet': Icons.account_balance_wallet,
      'trending_up': Icons.trending_up,
      'sell': Icons.sell,
      'computer': Icons.computer,
      'card_giftcard': Icons.card_giftcard,
      'attach_money': Icons.attach_money,
      'flight': Icons.flight,
      'sports_soccer': Icons.sports_soccer,
      'local_cafe': Icons.local_cafe,
      'pets': Icons.pets,
      'fitness_center': Icons.fitness_center,
      'phone_android': Icons.phone_android,
      'laptop': Icons.laptop,
      'games': Icons.games,
      'music_note': Icons.music_note,
      'brush': Icons.brush,
      'beach_access': Icons.beach_access,
      'spa': Icons.spa,
      'hotel': Icons.hotel,
      'local_gas_station': Icons.local_gas_station,
      'shopping_cart': Icons.shopping_cart,
      'fastfood': Icons.fastfood,
      'local_pizza': Icons.local_pizza,
      'cake': Icons.cake,
      'wine_bar': Icons.wine_bar,
    };
    return iconMap[iconName] ?? Icons.category;
  }
}
