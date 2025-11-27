import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String type;

  @HiveField(2)
  double amount;

  @HiveField(3)
  int categoryId;

  @HiveField(4)
  String? note;

  @HiveField(5)
  DateTime date;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    this.note,
    required this.date,
  });

  bool get isIncome => type == 'ingreso';
}
