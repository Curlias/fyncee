class AppSettings {
  final bool carryOverBalance; // Continuar con saldo del mes anterior
  final bool resetBudgetsMonthly; // Reiniciar presupuestos cada mes
  final String defaultPeriod; // 'current_month', 'previous_month', 'year', 'all'
  final bool showBudgetNotifications; // Mostrar notificaciones de presupuestos
  final bool groupTransactionsByDate; // Agrupar transacciones por fecha
  final String currency; // Moneda
  final String dateFormat; // Formato de fecha

  AppSettings({
    this.carryOverBalance = false,
    this.resetBudgetsMonthly = true,
    this.defaultPeriod = 'current_month',
    this.showBudgetNotifications = true,
    this.groupTransactionsByDate = true,
    this.currency = 'MXN',
    this.dateFormat = 'dd/MM/yyyy',
  });

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      carryOverBalance: map['carry_over_balance'] as bool? ?? false,
      resetBudgetsMonthly: map['reset_budgets_monthly'] as bool? ?? true,
      defaultPeriod: map['default_period'] as String? ?? 'current_month',
      showBudgetNotifications: map['show_budget_notifications'] as bool? ?? true,
      groupTransactionsByDate: map['group_transactions_by_date'] as bool? ?? true,
      currency: map['currency'] as String? ?? 'MXN',
      dateFormat: map['date_format'] as String? ?? 'dd/MM/yyyy',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'carry_over_balance': carryOverBalance,
      'reset_budgets_monthly': resetBudgetsMonthly,
      'default_period': defaultPeriod,
      'show_budget_notifications': showBudgetNotifications,
      'group_transactions_by_date': groupTransactionsByDate,
      'currency': currency,
      'date_format': dateFormat,
    };
  }

  AppSettings copyWith({
    bool? carryOverBalance,
    bool? resetBudgetsMonthly,
    String? defaultPeriod,
    bool? showBudgetNotifications,
    bool? groupTransactionsByDate,
    String? currency,
    String? dateFormat,
  }) {
    return AppSettings(
      carryOverBalance: carryOverBalance ?? this.carryOverBalance,
      resetBudgetsMonthly: resetBudgetsMonthly ?? this.resetBudgetsMonthly,
      defaultPeriod: defaultPeriod ?? this.defaultPeriod,
      showBudgetNotifications: showBudgetNotifications ?? this.showBudgetNotifications,
      groupTransactionsByDate: groupTransactionsByDate ?? this.groupTransactionsByDate,
      currency: currency ?? this.currency,
      dateFormat: dateFormat ?? this.dateFormat,
    );
  }
}
