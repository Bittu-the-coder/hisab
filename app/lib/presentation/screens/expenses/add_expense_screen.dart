import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/expense_model.dart';
import '../../../providers/expense_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});
  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amountCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  String _selectedCategory = 'food';
  String _paymentMode = 'upi';
  String _transactionType = 'debit';
  late DateTime _selectedDate;
  bool _saving = false;
  String? _groupId;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final extra = GoRouterState.of(context).extra;
      if (extra is Map && extra.containsKey('groupId')) {
        setState(() => _groupId = extra['groupId'] as String);
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final amountText = _amountCtrl.text.trim();
    final title = _titleCtrl.text.trim();

    if (amountText.isEmpty) {
      _showSnackBar('Please enter an amount');
      return;
    }
    final rupees = double.tryParse(amountText);
    if (rupees == null || rupees <= 0) {
      _showSnackBar('Please enter a valid amount');
      return;
    }
    if (title.isEmpty) {
      _showSnackBar('Please enter a title');
      return;
    }

    setState(() => _saving = true);

    final tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final input = ExpenseInput(
      title: title,
      amount: (rupees * 100).round(),
      category: _selectedCategory,
      date: _selectedDate,
      note: _noteCtrl.text.trim(),
      paymentMode: _paymentMode,
      transactionType: _transactionType,
      tags: tags,
      groupId: _groupId,
    );

    try {
      await ref.read(expenseListProvider((month: _selectedDate.month, year: _selectedDate.year)).notifier).addExpense(input);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_transactionType == 'debit' ? 'Expense added ✓' : 'Income added ✓'), backgroundColor: AppColors.accent),
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar('Failed to add expense');
        setState(() => _saving = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _transactionType = 'debit'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _transactionType == 'debit'
                            ? AppColors.negative.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _transactionType == 'debit'
                              ? AppColors.negative
                              : AppColors.divider,
                          width: _transactionType == 'debit' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_upward, size: 18, color: _transactionType == 'debit' ? AppColors.negative : AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Debited',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _transactionType == 'debit' ? AppColors.negative : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _transactionType = 'credit'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _transactionType == 'credit'
                            ? AppColors.accent.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _transactionType == 'credit'
                              ? AppColors.accent
                              : AppColors.divider,
                          width: _transactionType == 'credit' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_downward, size: 18, color: _transactionType == 'credit' ? AppColors.accent : AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Credited',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _transactionType == 'credit' ? AppColors.accent : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '₹ 0',
                hintStyle: Theme.of(context).textTheme.headlineLarge?.copyWith(color: AppColors.textSecondary.withOpacity(0.4)),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: 'What was this for?',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            Text('Category', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
              children: ExpenseModel.categories.map((cat) => GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  decoration: BoxDecoration(
                    color: _selectedCategory == cat
                        ? (AppColors.categoryColors[cat] ?? AppColors.categoryColors['other']!).withOpacity(0.2)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: _selectedCategory == cat
                        ? Border.all(color: AppColors.categoryColors[cat] ?? AppColors.categoryColors['other']!, width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_catIcon(cat), color: AppColors.categoryColors[cat], size: 24),
                      const SizedBox(height: 4),
                      Text(
                        cat.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' '),
                        style: TextStyle(fontSize: 10, color: AppColors.categoryColors[cat]),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),
            Text('Payment Mode', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _modeChip('Cash', Icons.money, 'cash'),
                  const SizedBox(width: 8),
                  _modeChip('UPI', Icons.qr_code_scanner, 'upi'),
                  const SizedBox(width: 8),
                  _modeChip('Card', Icons.credit_card, 'card'),
                  const SizedBox(width: 8),
                  _modeChip('Net Banking', Icons.account_balance, 'net_banking'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Date', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                hintText: 'Note (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tagsCtrl,
              decoration: InputDecoration(
                hintText: 'Tags (comma separated)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_transactionType == 'debit' ? 'Save Expense' : 'Save Income', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeChip(String label, IconData icon, String value) {
    final isSelected = _paymentMode == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMode = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary.withOpacity(0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? AppColors.secondary : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.secondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
