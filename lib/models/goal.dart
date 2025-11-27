import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'goal.g.dart';

@HiveType(typeId: 1)
class Goal extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String emoji;

  @HiveField(3)
  double targetAmount;

  @HiveField(4)
  double currentAmount;

  @HiveField(5)
  int colorValue;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  String monthlyProgressJson;

  Goal({
    required this.id,
    required this.name,
    required this.emoji,
    required this.targetAmount,
    this.currentAmount = 0,
    required this.colorValue,
    required this.createdAt,
    Map<String, double>? monthlyProgress,
  }) : monthlyProgressJson = jsonEncode(monthlyProgress ?? {});

  double get progress => currentAmount / targetAmount;
  
  int get progressPercentage => (progress * 100).round();
  
  Color get color => Color(colorValue);
  
  bool get isCompleted => currentAmount >= targetAmount;
  
  double get remainingAmount => targetAmount - currentAmount;

  double get monthlyComparison {
    final now = DateTime.now();
    final currentKey = '${now.year}-${now.month}';
    final previousMonth = DateTime(now.year, now.month - 1, 1);
    final previousKey = '${previousMonth.year}-${previousMonth.month}';

    final progress = monthlyProgress;
    final currentValue = progress[currentKey] ?? 0;
    final previousValue = progress[previousKey] ?? 0;

    if (previousValue == 0) {
      return currentValue > 0 ? 100 : 0;
    }

    final difference = currentValue - previousValue;
    return (difference / previousValue) * 100;
  }

  Map<String, double> get monthlyProgress {
    try {
      final decoded = jsonDecode(monthlyProgressJson);
      return Map<String, double>.from(decoded);
    } catch (e) {
      return {};
    }
  }

  set monthlyProgress(Map<String, double> value) {
    monthlyProgressJson = jsonEncode(value);
  }
}
