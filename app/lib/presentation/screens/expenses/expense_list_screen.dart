import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/expense_model.dart';
import '../../../providers/expense_provider.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});
  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  late int _month;
  late int _year;
  String? _selectedCategory;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }
      _selectedCategory = null;
      _searchQuery = '';
      _searchCtrl.clear();
    });
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
      _selectedCategory = null;
      _searchQuery = '';
      _searchCtrl.clear();
    });
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value.trim().toLowerCase());
  }

  void _onCategoryFilter(String? category) {
    setState(() {
      _selectedCategory = _selectedCategory == category ? null : category;
    });
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
    final expensesAsync = ref.watch(expenseListProvider((month: _month, year: _year)));
    final expenses = expensesAsync.valueOrNull ?? [];

    var filtered = expenses.where((e) {
      if (_selectedCategory != null && e.category != _selectedCategory) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery;
        if (!e.title.toLowerCase().contains(q) && !e.note.toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();

    final totalAmount = filtered.fold<int>(0, (sum, e) => sum + e.amount);

    final grouped = <String, List<ExpenseModel>>{};
    for (final e in filtered) {
      final label = DateHelpers.format(e.date);
      grouped.putIfAbsent(label, () => []).add(e);
    }

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/home/expenses/add'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left)),
                Text('${months[_month - 1]} $_year', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total', style: Theme.of(context).textTheme.bodySmall),
                        Text(CurrencyFormatter.format(totalAmount), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Transactions', style: Theme.of(context).textTheme.bodySmall),
                        Text('${filtered.length}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FilterChip(
                  label: const Text('All', style: TextStyle(fontSize: 12)),
                  selected: _selectedCategory == null,
                  onSelected: (_) => _onCategoryFilter(null),
                ),
                const SizedBox(width: 8),
                ...ExpenseModel.categories.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(_catIcon(cat), size: 14, color: AppColors.categoryColors[cat]),
                    label: Text(cat.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' '), style: const TextStyle(fontSize: 12)),
                    selected: _selectedCategory == cat,
                    onSelected: (_) => _onCategoryFilter(cat),
                  ),
                )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by title or note',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: expensesAsync.isLoading
                ? const Center(child: CircularProgressIndicator())
                : expensesAsync.hasError
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: AppColors.negative),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => ref.invalidate(expenseListProvider((month: _month, year: _year))),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Text(
                              _searchQuery.isNotEmpty || _selectedCategory != null ? 'No matching expenses' : 'No expenses this month',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async => ref.invalidate(expenseListProvider((month: _month, year: _year))),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: grouped.entries.length,
                              itemBuilder: (context, index) {
                                final entry = grouped.entries.elementAt(index);
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text(
                                        entry.key,
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                    ),
                                    ...entry.value.map((e) => _expenseItem(context, e)),
                                  ],
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _expenseItem(BuildContext context, ExpenseModel expense) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/home/expenses/${expense.id}'),
        child: Row(
          children: [
            Container(width: 4, color: AppColors.categoryColors[expense.category] ?? AppColors.categoryColors['other']),
            Expanded(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
