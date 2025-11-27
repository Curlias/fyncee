import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';
import '../models/goal.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class GoalsPage extends StatefulWidget {
  final VoidCallback? onGoalChanged;
  
  const GoalsPage({super.key, this.onGoalChanged});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  List<Goal> _goals = [];
  Goal? _selectedGoal;
  bool _isLoading = true;

  // Método helper para obtener colores según el tema
  Color get backgroundColor => Theme.of(context).brightness == Brightness.dark 
      ? FynceeColors.background 
      : FynceeColors.lightBackground;
  
  Color get surfaceColor => Theme.of(context).brightness == Brightness.dark 
      ? FynceeColors.surface 
      : FynceeColors.lightSurface;
  
  Color get surfaceLightColor => Theme.of(context).brightness == Brightness.dark 
      ? FynceeColors.surfaceLight 
      : FynceeColors.lightSurfaceLight;
  
  Color get textPrimaryColor => Theme.of(context).brightness == Brightness.dark 
      ? FynceeColors.textPrimary 
      : FynceeColors.lightTextPrimary;
  
  Color get textSecondaryColor => Theme.of(context).brightness == Brightness.dark 
      ? FynceeColors.textSecondary 
      : FynceeColors.lightTextSecondary;
  
  Color get textTertiaryColor => Theme.of(context).brightness == Brightness.dark 
      ? FynceeColors.textTertiary 
      : FynceeColors.lightTextTertiary;
  
  bool get isDarkMode => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    final goals = await DatabaseService().getAllGoals();
    setState(() {
      _goals = goals;
      if (_goals.isNotEmpty && _selectedGoal == null) {
        _selectedGoal = _goals[0];
      }
      _isLoading = false;
    });
    
    // Notificar al HomePage que las metas cambiaron
    widget.onGoalChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    // El AppBar se maneja en HomePage, aquí solo retornamos el contenido
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: FynceeColors.primary,
        ),
      );
    }

    if (_goals.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grid de metas
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: _goals.length,
            itemBuilder: (context, index) {
              final goal = _goals[index];
              final isSelected = _selectedGoal?.id == goal.id;
              return _buildGoalCard(goal, isSelected);
            },
          ),

          const SizedBox(height: 20),

          // Botón agregar nueva meta
          InkWell(
            onTap: _showAddGoalDialog,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: FynceeColors.primary,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_rounded,
                    color: FynceeColors.primary,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Agregar nueva meta de ahorro',
                    style: TextStyle(
                      color: FynceeColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Detalle de la meta seleccionada
          if (_selectedGoal != null) _buildGoalDetail(_selectedGoal!),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 80,
              color: textSecondaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'No tienes metas de ahorro',
              style: TextStyle(
                color: textPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Agrega tu primera meta de ahorro para comenzar a alcanzar tus objetivos financieros',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSecondaryColor.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _showAddGoalDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: FynceeColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Crear meta de ahorro',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(Goal goal, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGoal = goal;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? goal.color : FynceeColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: FynceeColors.primary, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(goal.emoji, style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    goal.name,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : FynceeColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              NumberFormat.currency(
                locale: 'es_MX',
                symbol: '\$',
                decimalDigits: 0,
              ).format(goal.targetAmount),
              style: TextStyle(
                color: isSelected ? Colors.white : FynceeColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalDetail(Goal goal) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con emoji, nombre y progreso circular
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(goal.emoji, style: TextStyle(fontSize: 32)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  goal.name,
                  style: TextStyle(
                    color: textPrimaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Progreso circular
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: goal.progress,
                        backgroundColor: FynceeColors.background,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          FynceeColors.primary,
                        ),
                        strokeWidth: 6,
                      ),
                    ),
                    Text(
                      '${goal.progressPercentage}%',
                      style: TextStyle(
                        color: textPrimaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Ahorro actual y meta
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ahorro actual',
                      style: TextStyle(
                        color: textSecondaryColor.withValues(
                          alpha: 0.8,
                        ),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(
                        locale: 'es_MX',
                        symbol: '\$',
                        decimalDigits: 2,
                      ).format(goal.currentAmount),
                      style: TextStyle(
                        color: textPrimaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meta',
                      style: TextStyle(
                        color: FynceeColors.incomeGreen.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(
                        locale: 'es_MX',
                        symbol: '\$',
                        decimalDigits: 2,
                      ).format(goal.targetAmount),
                      style: TextStyle(
                        color: FynceeColors.incomeGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Gráfica de progreso mensual
          SizedBox(height: 180, child: _buildMonthlyChart(goal)),

          const SizedBox(height: 16),

          // Comparación con mes anterior
          if (goal.monthlyComparison != 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: goal.monthlyComparison > 0
                    ? FynceeColors.incomeGreen.withValues(alpha: 0.1)
                    : FynceeColors.expenseRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    goal.monthlyComparison > 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: goal.monthlyComparison > 0
                        ? FynceeColors.incomeGreen
                        : FynceeColors.expenseRed,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${goal.monthlyComparison.abs().toStringAsFixed(0)}% ${goal.monthlyComparison > 0 ? 'más' : 'menos'} que el mes pasado',
                    style: TextStyle(
                      color: goal.monthlyComparison > 0
                          ? FynceeColors.incomeGreen
                          : FynceeColors.expenseRed,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddMoneyDialog(goal),
                  icon: Icon(Icons.add_rounded),
                  label: Text('Añadir ahorro'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FynceeColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _showGoalOptions(goal),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FynceeColors.background,
                  foregroundColor: FynceeColors.textPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Icon(Icons.more_horiz_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(Goal goal) {
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul'];
    final now = DateTime.now();
    final barData = <BarChartGroupData>[];

    for (int i = 0; i < 7; i++) {
      final month = DateTime(now.year, now.month - 6 + i);
      final monthKey = '${month.year}-${month.month}';
      final amount = goal.monthlyProgress[monthKey] ?? 0;

      barData.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: amount,
              color: i == 6 ? FynceeColors.primary : Colors.grey.shade700,
              width: 24,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    final maxY = goal.monthlyProgress.values.isEmpty
        ? 3000.0
        : goal.monthlyProgress.values.reduce((a, b) => a > b ? a : b) * 1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < months.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      months[value.toInt()],
                      style: TextStyle(
                        color: textSecondaryColor.withValues(
                          alpha: 0.8,
                        ),
                        fontSize: 11,
                      ),
                    ),
                  );
                }
                return Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1000,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: backgroundColor, strokeWidth: 1);
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: barData,
      ),
    );
  }

  void _showAddGoalDialog() {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    String selectedEmoji = '🎯';
    Color selectedColor = Colors.blue;

    final emojis = ['🎯', '📱', '🏝️', '🏍️', '⌚', '🏠', '🚗', '💻', '🎮', '📚'];
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: surfaceColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Nueva Meta',
            style: TextStyle(
              color: textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(color: textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Nombre de la meta',
                    labelStyle:
                        TextStyle(color: textSecondaryColor),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color:
                            FynceeColors.textSecondary.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: FynceeColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: targetController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Cantidad objetivo',
                    labelStyle:
                        TextStyle(color: textSecondaryColor),
                    prefixText: '\$',
                    prefixStyle:
                        TextStyle(color: textPrimaryColor),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color:
                            FynceeColors.textSecondary.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: FynceeColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Emoji:',
                  style: TextStyle(
                    color: textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: emojis.map((emoji) {
                    final isSelected = selectedEmoji == emoji;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() => selectedEmoji = emoji);
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? FynceeColors.primary.withValues(alpha: 0.2)
                              : FynceeColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? FynceeColors.primary
                                : FynceeColors.textSecondary
                                    .withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Color:',
                  style: TextStyle(
                    color: textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors.map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() => selectedColor = color);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? FynceeColors.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: textSecondaryColor),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    targetController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor completa todos los campos'),
                      backgroundColor: FynceeColors.error,
                    ),
                  );
                  return;
                }

                final targetAmount = double.tryParse(targetController.text);
                if (targetAmount == null || targetAmount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingresa una cantidad válida'),
                      backgroundColor: FynceeColors.error,
                    ),
                  );
                  return;
                }

                // Generar un ID único pero más pequeño (Hive solo acepta hasta 0xFFFFFFFF)
                final goalId = DateTime.now().millisecondsSinceEpoch % 0xFFFFFFFF;
                
                final newGoal = Goal(
                  id: goalId,
                  name: nameController.text,
                  emoji: selectedEmoji,
                  targetAmount: targetAmount,
                  currentAmount: 0,
                  colorValue: selectedColor.value,
                  createdAt: DateTime.now(),
                  monthlyProgress: {},
                );

                await DatabaseService().saveGoal(newGoal);
                await _loadGoals();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Meta creada exitosamente'),
                      backgroundColor: FynceeColors.incomeGreen,
                    ),
                  );
                }
              },
              child: Text(
                'Crear',
                style: TextStyle(color: FynceeColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMoneyDialog(Goal goal) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Añadir ahorro',
          style: TextStyle(
            color: textPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(color: textPrimaryColor),
              decoration: InputDecoration(
                labelText: 'Cantidad',
                labelStyle: TextStyle(color: textSecondaryColor),
                prefixText: '\$',
                prefixStyle: TextStyle(color: textPrimaryColor),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: textSecondaryColor.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: FynceeColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ingresa una cantidad válida'),
                    backgroundColor: FynceeColors.error,
                  ),
                );
                return;
              }

              // Añadir dinero a la meta
              await DatabaseService().addMoneyToGoal(goal.id, amount);

              // Verificar progreso y enviar notificación si es necesario
              final updatedGoal = await DatabaseService().getGoal(goal.id);
              if (updatedGoal != null) {
                if (updatedGoal.isCompleted) {
                  await NotificationService()
                      .showGoalCompletedNotification(updatedGoal.name);
                } else if (updatedGoal.progressPercentage >= 90) {
                  await NotificationService()
                      .showGoalAlmostCompleteNotification(updatedGoal.name, updatedGoal.progressPercentage);
                }
              }

              await _loadGoals();

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Se agregaron \$${amount.toStringAsFixed(2)} a ${goal.name}'),
                    backgroundColor: FynceeColors.incomeGreen,
                  ),
                );
              }
            },
            child: Text(
              'Añadir',
              style: TextStyle(color: FynceeColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showGoalOptions(Goal goal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textSecondaryColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(
                Icons.edit_rounded,
                color: FynceeColors.primary,
              ),
              title: Text(
                'Editar meta',
                style: TextStyle(color: textPrimaryColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _showEditGoalDialog(goal);
              },
            ),
            if (!goal.isCompleted)
              ListTile(
                leading: Icon(
                  Icons.check_circle_rounded,
                  color: FynceeColors.incomeGreen,
                ),
                title: Text(
                  'Marcar como completada',
                  style: TextStyle(color: textPrimaryColor),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final remainingAmount = goal.remainingAmount;
                  if (remainingAmount > 0) {
                    await DatabaseService().addMoneyToGoal(goal.id, remainingAmount);
                  }
                  await _loadGoals();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Meta completada 🎉'),
                        backgroundColor: FynceeColors.incomeGreen,
                      ),
                    );
                    await NotificationService().showGoalCompletedNotification(goal.name);
                  }
                },
              ),
            ListTile(
              leading: Icon(
                Icons.delete_rounded,
                color: FynceeColors.error,
              ),
              title: Text(
                'Eliminar meta',
                style: TextStyle(color: FynceeColors.error),
              ),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: surfaceColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      '¿Eliminar meta?',
                      style: TextStyle(color: textPrimaryColor),
                    ),
                    content: Text(
                      'Esta acción no se puede deshacer',
                      style: TextStyle(color: textSecondaryColor),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(color: textSecondaryColor),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'Eliminar',
                          style: TextStyle(color: FynceeColors.error),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await DatabaseService().deleteGoal(goal.id);
                  await _loadGoals();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Meta eliminada'),
                        backgroundColor: FynceeColors.error,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGoalDialog(Goal goal) {
    final nameController = TextEditingController(text: goal.name);
    final targetController =
        TextEditingController(text: goal.targetAmount.toString());
    String selectedEmoji = goal.emoji;
    Color selectedColor = goal.color;

    final emojis = ['🎯', '📱', '🏝️', '🏍️', '⌚', '🏠', '🚗', '💻', '🎮', '📚'];
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: surfaceColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Editar Meta',
            style: TextStyle(
              color: textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(color: textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Nombre de la meta',
                    labelStyle:
                        TextStyle(color: textSecondaryColor),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color:
                            FynceeColors.textSecondary.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: FynceeColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: targetController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Cantidad objetivo',
                    labelStyle:
                        TextStyle(color: textSecondaryColor),
                    prefixText: '\$',
                    prefixStyle:
                        TextStyle(color: textPrimaryColor),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color:
                            FynceeColors.textSecondary.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: FynceeColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Emoji:',
                  style: TextStyle(
                    color: textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: emojis.map((emoji) {
                    final isSelected = selectedEmoji == emoji;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() => selectedEmoji = emoji);
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? FynceeColors.primary.withValues(alpha: 0.2)
                              : FynceeColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? FynceeColors.primary
                                : FynceeColors.textSecondary
                                    .withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Color:',
                  style: TextStyle(
                    color: textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors.map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() => selectedColor = color);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? FynceeColors.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: textSecondaryColor),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    targetController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor completa todos los campos'),
                      backgroundColor: FynceeColors.error,
                    ),
                  );
                  return;
                }

                final targetAmount = double.tryParse(targetController.text);
                if (targetAmount == null || targetAmount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingresa una cantidad válida'),
                      backgroundColor: FynceeColors.error,
                    ),
                  );
                  return;
                }

                final updatedGoal = Goal(
                  id: goal.id,
                  name: nameController.text,
                  emoji: selectedEmoji,
                  targetAmount: targetAmount,
                  currentAmount: goal.currentAmount,
                  colorValue: selectedColor.value,
                  createdAt: goal.createdAt,
                  monthlyProgress: goal.monthlyProgress,
                );

                await DatabaseService().updateGoal(updatedGoal);
                await _loadGoals();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Meta actualizada'),
                      backgroundColor: FynceeColors.incomeGreen,
                    ),
                  );
                }
              },
              child: Text(
                'Guardar',
                style: TextStyle(color: FynceeColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
