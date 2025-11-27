import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../services/supabase_service.dart';
import '../theme.dart';

class TransactionItem extends StatefulWidget {
  const TransactionItem({
    super.key,
    required this.transaction,
    this.onEdit,
    this.onDelete,
  });

  final Transaction transaction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  State<TransactionItem> createState() => _TransactionItemState();
}

class _TransactionItemState extends State<TransactionItem> {
  Map<String, dynamic>? _category;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategory();
  }

  Future<void> _loadCategory() async {
    try {
      final categories = await SupabaseService().getAllCategories();
      final category = categories.firstWhere(
        (c) => c['id'] == widget.transaction.categoryId,
        orElse: () => {
          'id': widget.transaction.categoryId,
          'name': 'Sin categoría',
          'icon': 'category',
          'color_value': 0xFF6B7280,
        },
      );
      if (mounted) {
        setState(() {
          _category = category;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando categoría: $e');
      if (mounted) {
        setState(() {
          _category = {
            'id': widget.transaction.categoryId,
            'name': 'Sin categoría',
            'icon': 'category',
            'color_value': 0xFF6B7280,
          };
          _isLoading = false;
        });
      }
    }
  }

  IconData _getIconData(String iconName) {
    final iconMap = {
      'restaurant': Icons.restaurant,
      'shopping_bag': Icons.shopping_bag,
      'home': Icons.home,
      'directions_car': Icons.directions_car,
      'school': Icons.school,
      'favorite': Icons.favorite,
      'card_giftcard': Icons.card_giftcard,
      'sports_esports': Icons.sports_esports,
      'movie': Icons.movie,
      'flight': Icons.flight,
      'pets': Icons.pets,
      'sports_soccer': Icons.sports_soccer,
      'music_note': Icons.music_note,
      'fitness_center': Icons.fitness_center,
      'work': Icons.work,
      'attach_money': Icons.attach_money,
      'trending_up': Icons.trending_up,
      'card_travel': Icons.card_travel,
      'storefront': Icons.storefront,
      'phone_android': Icons.phone_android,
      'wallet': Icons.wallet,
      'savings': Icons.savings,
      'payments': Icons.payments,
      'receipt': Icons.receipt,
      'build': Icons.build,
      'celebration': Icons.celebration,
      'handshake': Icons.handshake,
      'credit_card': Icons.credit_card,
      'account_balance': Icons.account_balance,
      'volunteer_activism': Icons.volunteer_activism,
      'lightbulb': Icons.lightbulb,
      'local_hospital': Icons.local_hospital,
      'computer': Icons.computer,
      'currency_bitcoin': Icons.currency_bitcoin,
    };
    return iconMap[iconName] ?? Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _category == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        height: 80,
        decoration: BoxDecoration(
          color: FynceeColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final currencyFormatter = NumberFormat.currency(
      locale: Intl.getCurrentLocale(),
      symbol: '\$',
      decimalDigits: 2,
    );
    final dateFormatter = DateFormat('dd MMM', Intl.getCurrentLocale());
    final displayAmount = currencyFormatter.format(widget.transaction.amount);
    final displayNote = widget.transaction.note?.trim();

    final categoryName = _category!['name'] as String;
    final categoryIcon = _category!['icon'] as String;
    final categoryColor = Color(_category!['color_value'] as int);
    final amountColor = widget.transaction.isIncome
        ? FynceeColors.incomeGreen
        : FynceeColors.expenseRed;

    return Dismissible(
      key: Key(widget.transaction.id.toString()),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: FynceeColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: FynceeColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe derecha = Editar
          widget.onEdit?.call();
          return false;
        } else {
          // Swipe izquierda = Eliminar
          final shouldDelete = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: FynceeColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                '¿Eliminar movimiento?',
                style: TextStyle(
                  color: FynceeColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Text(
                'Esta acción no se puede deshacer.',
                style: TextStyle(
                  color: FynceeColors.textSecondary.withValues(alpha: 0.8),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: FynceeColors.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Eliminar',
                    style: TextStyle(color: FynceeColors.error),
                  ),
                ),
              ],
            ),
          );

          if (shouldDelete == true) {
            widget.onDelete?.call();
          }
          return shouldDelete ?? false;
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: FynceeColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getIconData(categoryIcon), color: categoryColor, size: 24),
          ),
          title: Text(
            categoryName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: FynceeColors.textPrimary,
            ),
          ),
          subtitle: displayNote?.isNotEmpty == true
              ? Text(
                  displayNote!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: FynceeColors.textSecondary,
                  ),
                )
              : Text(
                  dateFormatter.format(widget.transaction.date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: FynceeColors.textTertiary,
                  ),
                ),
          trailing: Text(
            '${widget.transaction.isIncome ? '+' : '-'} $displayAmount',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ),
      ),
    );
  }
}
