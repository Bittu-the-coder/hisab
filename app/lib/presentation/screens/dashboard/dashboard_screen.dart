import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/expense_model.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/insights_provider.dart';
import '../../../data/models/insight_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
  }

  void _refresh() {
    setState(() {});
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  IconData _catIcon(String cat) {
    const icons = {
      'food': Icons.restaurant,
      'transport': Icons.directions_car,
      'shopping': Icons.shopping_bag,
      'entertainment': Icons.movie,
      'health': Icons.local_hospital,
      'education': Icons.school,
      'utilities': Icons.bolt,
      'rent': Icons.home,
      'groceries': Icons.local_grocery_store,
      'personal_care': Icons.face,
      'travel': Icons.flight,
      'other': Icons.more_horiz,
    };
    return icons[cat] ?? Icons.more_horiz;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;
    final themeMode = ref.watch(themeModeProvider);
    final insightAsync = ref.watch(insightSummaryProvider((month: _month, year: _year)));
    final budgetAsync = ref.watch(budgetStatusProvider((month: _month, year: _year)));
    final expensesAsync = ref.watch(expenseListProvider((month: _month, year: _year)));

    final insight = insightAsync.valueOrNull;
    final budgetStatus = budgetAsync.valueOrNull;
    final expenses = expensesAsync.valueOrNull ?? [];

    final recentExpenses = expenses.take(5).toList();
    final categories = <String>{};
    for (final e in expenses) {
      categories.add(e.category);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_greeting()}, ${user?.name ?? 'there'}'),
        actions: [
          IconButton(
            icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (insightAsync.isLoading || budgetAsync.isLoading || expensesAsync.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (insightAsync.hasError || budgetAsync.hasError || expensesAsync.hasError) ...[
              if (expenses.isEmpty) _offlineBanner(context) else const SizedBox.shrink(),
              _summaryCard(context, insight ?? InsightSummary(totalSpent: 0, totalLastMonth: 0, percentageChange: 0, topCategory: 'other', expenseCount: 0, avgPerDay: 0), _month, _year),
              if (budgetStatus != null && budgetStatus.isAlertTriggered)
                _budgetAlertCard(context, budgetStatus),
            ] else ...[
              _summaryCard(context, insight!, _month, _year),
              if (budgetStatus != null && budgetStatus.isAlertTriggered)
                _budgetAlertCard(context, budgetStatus),
            ],
            const SizedBox(height: 16),
            _sectionHeader(context, 'Categories', null),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: categories.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: Icon(_catIcon(cat), size: 16, color: AppColors.categoryColors[cat]),
                    label: Text(cat.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' '), style: const TextStyle(fontSize: 12)),
                    onPressed: () {},
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),
            _sectionHeader(context, 'Recent Expenses', 'See All'),
            const SizedBox(height: 8),
            ...recentExpenses.map((e) => _expenseCard(context, e)),
            if (recentExpenses.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text(insightAsync.hasError ? 'Start adding expenses to see them here' : 'No expenses this month', style: Theme.of(context).textTheme.bodyMedium)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _offlineBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: AppColors.warning.withOpacity(0.12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.cloud_off, size: 18, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(child: Text('Could not reach server. Showing cached data.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.warning))),
              TextButton(onPressed: _refresh, child: const Text('Retry', style: TextStyle(fontSize: 12))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(BuildContext context, InsightSummary? insight, int month, int year) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${months[month - 1]} $year', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text('${insight?.expenseCount ?? 0} transactions', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(insight?.totalSpent ?? 0),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (insight != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    insight.percentageChange >= 0 ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: insight.percentageChange >= 0 ? AppColors.negative : AppColors.accent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${insight.percentageChange >= 0 ? '+' : ''}${insight.percentageChange.toStringAsFixed(1)}% vs last month',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: insight.percentageChange >= 0 ? AppColors.negative : AppColors.accent,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _budgetAlertCard(BuildContext context, BudgetStatus budgetStatus) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: AppColors.warning.withOpacity(0.15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Text('Budget Alert', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${budgetStatus.percentUsed.toStringAsFixed(0)}% of your budget used',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (budgetStatus.percentUsed / 100).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation(AppColors.warning),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${CurrencyFormatter.format(budgetStatus.remaining)} remaining',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, String? action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        if (action != null)
          GestureDetector(
            onTap: () => context.go('/home/expenses'),
            child: Text(action, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.secondary)),
          ),
      ],
    );
  }

  Widget _expenseCard(BuildContext context, ExpenseModel expense) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.categoryColors[expense.category]?.withOpacity(0.15),
          child: Icon(_catIcon(expense.category), color: AppColors.categoryColors[expense.category], size: 20),
        ),
        title: Text(expense.title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        subtitle: Text(
          '${DateHelpers.format(expense.date)}  ·  ${expense.paymentMode.toUpperCase()}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Text(
          CurrencyFormatter.format(expense.amount),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        onTap: () => context.push('/home/expenses/${expense.id}'),
      ),
    );
  }
}
