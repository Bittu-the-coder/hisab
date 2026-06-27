import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/group_provider.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameCtrl = TextEditingController();
  String _selectedIcon = 'group';
  bool _loading = false;

  final _icons = [
    ('group', Icons.group),
    ('people', Icons.people),
    ('trip', Icons.flight),
    ('home', Icons.home),
    ('work', Icons.work),
    ('school', Icons.school),
    ('travel', Icons.explore),
    ('food', Icons.restaurant),
    ('shopping', Icons.shopping_bag),
    ('sports', Icons.sports_esports),
    ('music', Icons.music_note),
    ('fitness', Icons.fitness_center),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a group name'), backgroundColor: AppColors.warning),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(groupRepositoryProvider).createGroup(name, _selectedIcon);
      if (mounted) {
        ref.invalidate(groupsProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.negative),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Group Name',
              hintText: 'Enter group name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.group),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Choose Icon', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _icons.length,
            itemBuilder: (_, i) {
              final (key, icon) = _icons[i];
              final selected = _selectedIcon == key;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = key),
                child: Container(
                  decoration: BoxDecoration(
                    color: selected ? AppColors.secondary : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? AppColors.secondary : AppColors.divider,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? Colors.white : AppColors.textPrimary,
                    size: 28,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _loading ? null : _create,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Create Group'),
          ),
        ],
      ),
    );
  }
}
