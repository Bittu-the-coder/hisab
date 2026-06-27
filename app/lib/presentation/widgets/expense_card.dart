import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helpers.dart';
import '../../data/models/expense_model.dart';

class ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ExpenseCard({super.key, required this.expense, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColors[expense.category] ?? AppColors.categoryColors['other']!;
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete expense?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete?.call(),
      background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                Container(width: 4, color: color, height: 72),
                const SizedBox(width: 12),
                Icon(_catIcon(expense.category), color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.title, style: Theme.of(context).textTheme.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${DateHelpers.format(expense.date)} · ${expense.paymentMode}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                )),
                Padding(padding: const EdgeInsets.only(right: 12), child: Text(CurrencyFormatter.format(expense.amount), style: Theme.of(context).textTheme.titleMedium)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _catIcon(String cat) {
    const icons = {'food': Icons.restaurant, 'transport': Icons.directions_car, 'shopping': Icons.shopping_bag, 'entertainment': Icons.movie, 'health': Icons.local_hospital, 'education': Icons.school, 'utilities': Icons.bolt, 'rent': Icons.home, 'groceries': Icons.local_grocery_store, 'personal_care': Icons.face, 'travel': Icons.flight, 'other': Icons.more_horiz};
    return icons[cat] ?? Icons.more_horiz;
  }
}
