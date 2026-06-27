import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BudgetProgressBar extends StatelessWidget {
  final double percent;
  final bool isOver;

  const BudgetProgressBar({super.key, required this.percent, this.isOver = false});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: (percent / 100).clamp(0.0, 1.0),
        backgroundColor: Colors.grey[300],
        valueColor: AlwaysStoppedAnimation(isOver ? AppColors.negative : AppColors.secondary),
        minHeight: 6,
      ),
    );
  }
}
