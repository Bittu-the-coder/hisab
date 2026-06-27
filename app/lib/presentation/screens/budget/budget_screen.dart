import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/insights_provider.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/expense_model.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});
  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  double _alertAt = 80;
  final _catCtrls = <String, TextEditingController>{};
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBudget());
  }

  void _loadBudget() {
    final budget = ref.watch(budgetProvider((month: _month, year: _year))).valueOrNull;
    if (budget != null) {
      _alertAt = budget.alertAt.toDouble();
      for (final c in budget.categories) {
        _catCtrls[c.category] = TextEditingController(text: (c.limit / 100).toStringAsFixed(0));
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    for (final c in _catCtrls.values) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final categories = ExpenseModel.categories
      .where((c) => _catCtrls[c]?.text.isNotEmpty == true)
      .map((c) => CategoryBudget(category: c, limit: ((double.tryParse(_catCtrls[c]!.text) ?? 0) * 100).toInt()))
      .toList();
    final totalPaise = categories.fold<int>(0, (sum, c) => sum + c.limit);
    await ref.read(budgetProvider((month: _month, year: _year)).notifier).saveBudget(
      BudgetInput(month: _month, year: _year, totalBudget: totalPaise, categories: categories, alertAt: _alertAt.toInt()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(budgetStatusProvider((month: _month, year: _year)));
    return Scaffold(
      appBar: AppBar(title: const Text('Budget')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            IconButton(onPressed: () { setState(() { if (_month == 1) { _month = 12; _year--; } else { _month--; } }); _loadBudget(); }, icon: const Icon(Icons.chevron_left)),
            Text('${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][_month-1]} $_year', style: Theme.of(context).textTheme.titleMedium),
            IconButton(onPressed: () { setState(() { if (_month == 12) { _month = 1; _year++; } else { _month++; } }); _loadBudget(); }, icon: const Icon(Icons.chevron_right)),
          ], mainAxisAlignment: MainAxisAlignment.center),
          Text('Alert at ${_alertAt.toInt()}%', style: Theme.of(context).textTheme.bodyMedium),
          Slider(value: _alertAt, min: 0, max: 100, divisions: 20, label: '${_alertAt.toInt()}%', onChanged: (v) => setState(() => _alertAt = v)),
          const SizedBox(height: 16),
          Text('Category Budgets', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...ExpenseModel.categories.map((cat) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: _catCtrls.putIfAbsent(cat, () => TextEditingController()),
              decoration: InputDecoration(labelText: cat.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' '), prefixText: '₹ ', prefixIcon: Icon(_catIcon(cat), size: 20, color: AppColors.categoryColors[cat])),
              keyboardType: TextInputType.number,
            ),
          )),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: ElevatedButton(onPressed: _save, child: const Text('Save Budget'))),
              const SizedBox(width: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Budget'),
                        content: const Text('Are you sure? This cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.negative),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref.read(budgetProvider((month: _month, year: _year)).notifier).deleteBudget();
                      for (final c in _catCtrls.values) { c.clear(); }
                      setState(() => _alertAt = 80);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.negative,
                    side: const BorderSide(color: AppColors.negative),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
          if (statusAsync.valueOrNull != null) ...[
            const SizedBox(height: 24),
            Text('Current Status', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _statusBar(context, 'Overall', statusAsync.value!.totalBudget, statusAsync.value!.totalSpent, statusAsync.value!.percentUsed, statusAsync.value!.isAlertTriggered),
            ...statusAsync.value!.categories.map((c) => _statusBar(context, c.category, c.limit, c.spent, c.percentUsed, c.isOver)),
          ],
        ],
      ),
    );
  }

  Widget _statusBar(BuildContext context, String label, int limit, int spent, double percent, bool isOver) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label[0].toUpperCase() + label.substring(1).replaceAll('_', ' '), style: Theme.of(context).textTheme.bodyMedium),
          Text('${CurrencyFormatter.format(spent)} / ${CurrencyFormatter.format(limit)}', style: Theme.of(context).textTheme.bodySmall),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(isOver ? AppColors.negative : AppColors.secondary),
            minHeight: 8,
          ),
        ),
        Text('${percent.toStringAsFixed(0)}% used', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isOver ? AppColors.negative : null)),
      ]),
    );
  }

  IconData _catIcon(String cat) {
    const icons = {'food': Icons.restaurant, 'transport': Icons.directions_car, 'shopping': Icons.shopping_bag, 'entertainment': Icons.movie, 'health': Icons.local_hospital, 'education': Icons.school, 'utilities': Icons.bolt, 'rent': Icons.home, 'groceries': Icons.local_grocery_store, 'personal_care': Icons.face, 'travel': Icons.flight, 'other': Icons.more_horiz};
    return icons[cat] ?? Icons.more_horiz;
  }
}
