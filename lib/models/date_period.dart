import 'package:intl/intl.dart';

class DatePeriod {
  final String id;
  final String label;
  final DateTime startDate;
  final DateTime endDate;

  DatePeriod({
    required this.id,
    required this.label,
    required this.startDate,
    required this.endDate,
  });

  static DatePeriod currentMonth() {
    final now = DateTime.now();
    return DatePeriod(
      id: 'current_month',
      label: 'Este mes',
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }

  static DatePeriod previousMonth() {
    final now = DateTime.now();
    final prevMonth = DateTime(now.year, now.month - 1, 1);
    return DatePeriod(
      id: 'previous_month',
      label: 'Mes anterior',
      startDate: DateTime(prevMonth.year, prevMonth.month, 1),
      endDate: DateTime(prevMonth.year, prevMonth.month + 1, 0, 23, 59, 59),
    );
  }

  static DatePeriod currentYear() {
    final now = DateTime.now();
    return DatePeriod(
      id: 'current_year',
      label: 'Este año',
      startDate: DateTime(now.year, 1, 1),
      endDate: DateTime(now.year, 12, 31, 23, 59, 59),
    );
  }

  static DatePeriod lastThreeMonths() {
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, 1);
    return DatePeriod(
      id: 'last_3_months',
      label: 'Últimos 3 meses',
      startDate: threeMonthsAgo,
      endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }

  static DatePeriod lastSixMonths() {
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 6, 1);
    return DatePeriod(
      id: 'last_6_months',
      label: 'Últimos 6 meses',
      startDate: sixMonthsAgo,
      endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }

  static DatePeriod allTime() {
    return DatePeriod(
      id: 'all_time',
      label: 'Todo el tiempo',
      startDate: DateTime(2020, 1, 1),
      endDate: DateTime.now().add(const Duration(days: 365)),
    );
  }

  static DatePeriod custom(DateTime start, DateTime end) {
    // Formatear label según el rango
    final dateFormat = DateFormat('d MMM', 'es');
    String label;
    
    // Si es el mismo mes
    if (start.year == end.year && start.month == end.month) {
      if (start.day == 1 && end.day == DateTime(end.year, end.month + 1, 0).day) {
        // Es un mes completo
        label = DateFormat('MMMM yyyy', 'es').format(start);
      } else {
        // Es un rango dentro del mismo mes
        label = '${dateFormat.format(start)} - ${dateFormat.format(end)}';
      }
    } else {
      // Rango entre diferentes meses
      label = '${dateFormat.format(start)} - ${dateFormat.format(end)}';
    }
    
    return DatePeriod(
      id: 'custom',
      label: label,
      startDate: start,
      endDate: end,
    );
  }

  static List<DatePeriod> defaultPeriods() {
    return [
      currentMonth(),
      previousMonth(),
      lastThreeMonths(),
      lastSixMonths(),
      currentYear(),
      allTime(),
    ];
  }

  static DatePeriod fromId(String id) {
    switch (id) {
      case 'current_month':
        return currentMonth();
      case 'previous_month':
        return previousMonth();
      case 'current_year':
        return currentYear();
      case 'last_3_months':
        return lastThreeMonths();
      case 'last_6_months':
        return lastSixMonths();
      case 'all_time':
        return allTime();
      default:
        return currentMonth();
    }
  }
}
