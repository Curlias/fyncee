import 'package:flutter/material.dart';

class TransactionCategory {
  final int id;
  final String name;
  final IconData icon;
  final bool isIncome;
  final Color color;

  const TransactionCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.isIncome,
    required this.color,
  });

  static const List<TransactionCategory> incomeCategories = [
    TransactionCategory(id: 1, name: 'Salario', icon: Icons.account_balance_wallet, isIncome: true, color: Colors.tealAccent),
    TransactionCategory(id: 2, name: 'Inversiones', icon: Icons.trending_up, isIncome: true, color: Colors.lightBlueAccent),
    TransactionCategory(id: 3, name: 'Ventas', icon: Icons.sell, isIncome: true, color: Colors.greenAccent),
    TransactionCategory(id: 4, name: 'Freelance', icon: Icons.computer, isIncome: true, color: Colors.cyanAccent),
    TransactionCategory(id: 5, name: 'Bonos', icon: Icons.card_giftcard, isIncome: true, color: Colors.amberAccent),
    TransactionCategory(id: 6, name: 'Otros ingresos', icon: Icons.attach_money, isIncome: true, color: Colors.limeAccent),
  ];

  static const List<TransactionCategory> expenseCategories = [
    TransactionCategory(id: 101, name: 'Comida', icon: Icons.restaurant, isIncome: false, color: Colors.deepOrangeAccent),
    TransactionCategory(id: 102, name: 'Transporte', icon: Icons.directions_car, isIncome: false, color: Colors.blueGrey),
    TransactionCategory(id: 103, name: 'Entretenimiento', icon: Icons.movie, isIncome: false, color: Colors.purpleAccent),
    TransactionCategory(id: 104, name: 'Compras', icon: Icons.shopping_bag, isIncome: false, color: Colors.pinkAccent),
    TransactionCategory(id: 105, name: 'Salud', icon: Icons.local_hospital, isIncome: false, color: Colors.redAccent),
    TransactionCategory(id: 106, name: 'Educación', icon: Icons.school, isIncome: false, color: Colors.indigoAccent),
    TransactionCategory(id: 107, name: 'Servicios', icon: Icons.build, isIncome: false, color: Colors.lightGreen),
    TransactionCategory(id: 108, name: 'Vivienda', icon: Icons.home, isIncome: false, color: Colors.orangeAccent),
    TransactionCategory(id: 109, name: 'Otros gastos', icon: Icons.more_horiz, isIncome: false, color: Colors.blueAccent),
  ];

  static List<TransactionCategory> get all => [...incomeCategories, ...expenseCategories];

  static TransactionCategory getById(int id) {
    return all.firstWhere((cat) => cat.id == id, orElse: () => expenseCategories.first);
  }
}
