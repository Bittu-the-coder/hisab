import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/expense_model.dart';
import '../../../providers/group_provider.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const GroupDetailScreen({super.key, required this.id});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GroupModel? _group;
  List<ExpenseModel> _expenses = [];
  List<_BalanceEntry> _balances = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGroup();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroup() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(groupRepositoryProvider).getGroup(widget.id);
      final groupJson = data['group'] as Map<String, dynamic>;
      final group = GroupModel.fromJson(groupJson);
      final expenses = (data['expenses'] as List?)
          ?.map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
          .toList() ?? [];
      final rawBalances = (data['balances'] as List?) ?? [];
      final balances = rawBalances.map((b) {
        final bMap = b as Map<String, dynamic>;
        return _BalanceEntry(
          from: bMap['from'] ?? '',
          to: bMap['to'] ?? '',
          amount: bMap['amount'] ?? 0,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _group = group;
          _expenses = expenses;
          _balances = balances;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.negative),
        );
      }
    }
  }

  Future<void> _editGroup() async {
    final nameCtrl = TextEditingController(text: _group?.name ?? '');
    String selectedIcon = _group?.icon ?? 'group';
    final icons = [
      ('group', Icons.group), ('people', Icons.people), ('trip', Icons.flight),
      ('home', Icons.home), ('work', Icons.work), ('school', Icons.school),
      ('travel', Icons.explore), ('food', Icons.restaurant), ('shopping', Icons.shopping_bag),
      ('sports', Icons.sports_esports), ('music', Icons.music_note), ('fitness', Icons.fitness_center),
    ];
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Group Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const Text('Icon', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                width: 280,
                child: Wrap(
                  spacing: 8, runSpacing: 8,
                  children: icons.map((entry) {
                    final (key, icon) = entry;
                    final sel = selectedIcon == key;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = key),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: sel ? AppColors.secondary : Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: sel ? Colors.white : AppColors.textPrimary, size: 22),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => nameCtrl.text.trim().isNotEmpty ? Navigator.pop(ctx, true) : null, child: const Text('Save')),
          ],
        ),
      ),
    );
    if (saved == true) {
      try {
        await ref.read(groupRepositoryProvider).updateGroup(widget.id, nameCtrl.text.trim(), selectedIcon);
        _loadGroup();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.negative),
        );
      }
    }
    nameCtrl.dispose();
  }

  Future<void> _deleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text('Are you sure? This action cannot be undone.'),
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
      try {
        await ref.read(groupRepositoryProvider).deleteGroup(widget.id);
        ref.invalidate(groupsProvider);
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.negative),
        );
      }
    }
  }

  void _copyInviteCode() {
    if (_group != null) {
      Clipboard.setData(ClipboardData(text: _group!.inviteCode));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite code copied!')),
      );
    }
  }

  IconData _groupIcon() {
    if (_group == null) return Icons.group;
    switch (_group!.icon) {
      case 'people': return Icons.people;
      case 'trip': return Icons.flight;
      case 'home': return Icons.home;
      case 'work': return Icons.work;
      default: return Icons.group;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group')),
        body: const Center(child: Text('Group not found')),
      );
    }

    final group = _group!;

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _editGroup),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _deleteGroup),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.onSurface,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            indicatorColor: Theme.of(context).colorScheme.secondary,
            tabs: const [
              Tab(text: 'Expenses'),
              Tab(text: 'Balances'),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          _header(group),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _expensesTab(),
                _balancesTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/home/expenses/add', extra: {'groupId': widget.id});
          _loadGroup();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _header(GroupModel group) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
            child: Icon(_groupIcon(), color: theme.colorScheme.secondary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(group.name, style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...group.members.take(5).map((m) {
                final member = m as Map<String, dynamic>;
                final name = member['name'] as String? ?? 'U';
                return Align(
                  widthFactor: 0.7,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.secondary,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                );
              }),
              if (group.members.length > 5)
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.dividerColor,
                  child: Text(
                    '+${group.members.length - 5}',
                    style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${group.members.length} members', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 8),
          InkWell(
            onTap: _copyInviteCode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.content_copy, size: 16, color: theme.colorScheme.secondary),
                  const SizedBox(width: 6),
                  Text(
                    'Code: ${group.inviteCode}',
                    style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _expensesTab() {
    final theme = Theme.of(context);
    if (_expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 48, color: theme.colorScheme.onSurface.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text('No shared expenses yet', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/home/expenses/add', extra: {'groupId': widget.id}),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Expense'),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _expenses.length,
      itemBuilder: (_, i) {
        final e = _expenses[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            onTap: e.expenseRef != null && e.expenseRef!.isNotEmpty
                ? () async {
                    await context.push('/home/expenses/${e.expenseRef}');
                    _loadGroup();
                  }
                : null,
            leading: CircleAvatar(
              backgroundColor: AppColors.categoryColors[e.category]?.withOpacity(0.2) ?? theme.dividerColor,
              child: Icon(Icons.receipt, color: AppColors.categoryColors[e.category]),
            ),
            title: Text(e.title),
            subtitle: Text(
              '${e.category.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ')}  •  ${e.date.day}/${e.date.month}/${e.date.year}',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
            trailing: Text(
              CurrencyFormatter.format(e.amount),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Widget _balancesTab() {
    final theme = Theme.of(context);
    if (_balances.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.balance, size: 48, color: theme.colorScheme.onSurface.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text('All settled up!', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _balances.length,
      itemBuilder: (_, i) {
        final b = _balances[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.warning.withOpacity(0.2),
              child: const Icon(Icons.swap_horiz, color: AppColors.warning),
            ),
            title: Text('${b.from} owes ${b.to}'),
            trailing: Text(
              CurrencyFormatter.format(b.amount),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning),
            ),
          ),
        );
      },
    );
  }
}

class _BalanceEntry {
  final String from;
  final String to;
  final int amount;

  _BalanceEntry({
    required this.from,
    required this.to,
    required this.amount,
  });
}
