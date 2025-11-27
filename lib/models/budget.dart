class Budget {
  final int id;
  final int categoryId;
  final String categoryName;
  final int categoryColor;
  final String categoryIcon;
  final double amount;
  final double spent;
  final String period; // 'monthly' o 'yearly'
  final DateTime startDate;

  Budget({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
    required this.amount,
    required this.spent,
    required this.period,
    required this.startDate,
  });

  double get percentage => amount > 0 ? (spent / amount * 100).clamp(0, 100) : 0;
  double get remaining => (amount - spent).clamp(0, double.infinity);
  bool get isExceeded => spent > amount;
  bool get isNearLimit => spent >= amount * 0.8 && spent < amount;

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int,
      categoryId: map['category_id'] as int,
      categoryName: map['category_name'] as String? ?? 'Sin categoría',
      categoryColor: map['category_color'] as int? ?? 0xFF6B7280,
      categoryIcon: map['category_icon'] as String? ?? 'category',
      amount: (map['amount'] as num).toDouble(),
      spent: (map['spent'] as num?)?.toDouble() ?? 0.0,
      period: map['period'] as String? ?? 'monthly',
      startDate: DateTime.parse(map['start_date'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'amount': amount,
      'period': period,
      'start_date': startDate.toIso8601String(),
    };
  }
}
