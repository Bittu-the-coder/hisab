import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';

class CategoryChip extends StatelessWidget {
  final String category;
  final int? amount;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryChip({super.key, required this.category, this.amount, this.isSelected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColors[category] ?? AppColors.categoryColors['other']!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Theme.of(context).dividerColor),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(_catIcon(category), size: 16, color: color),
          const SizedBox(width: 6),
          Text(category[0].toUpperCase() + category.substring(1).replaceAll('_', ' '), style: Theme.of(context).textTheme.labelSmall),
          if (amount != null) ...[const SizedBox(width: 6), Text(CurrencyFormatter.format(amount!), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color))],
        ]),
      ),
    );
  }

  IconData _catIcon(String cat) {
    const icons = {'food': Icons.restaurant, 'transport': Icons.directions_car, 'shopping': Icons.shopping_bag, 'entertainment': Icons.movie, 'health': Icons.local_hospital, 'education': Icons.school, 'utilities': Icons.bolt, 'rent': Icons.home, 'groceries': Icons.local_grocery_store, 'personal_care': Icons.face, 'travel': Icons.flight, 'other': Icons.more_horiz};
    return icons[cat] ?? Icons.more_horiz;
  }
}
