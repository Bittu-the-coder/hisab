import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/group_model.dart';
import '../../../providers/group_provider.dart';

class GroupsListScreen extends ConsumerStatefulWidget {
  const GroupsListScreen({super.key});

  @override
  ConsumerState<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends ConsumerState<GroupsListScreen> {
  void _showJoinDialog() {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Group'),
        content: TextField(
          controller: codeCtrl,
          decoration: const InputDecoration(
            labelText: 'Invite Code',
            hintText: 'Enter invite code',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final code = codeCtrl.text.trim();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ref.read(groupRepositoryProvider).joinGroup(code);
                ref.invalidate(groupsProvider);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e'), backgroundColor: AppColors.negative),
                  );
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/home/profile/groups/create'),
          ),
          IconButton(
            icon: const Icon(Icons.login),
            tooltip: 'Join with Code',
            onPressed: _showJoinDialog,
          ),
        ],
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('No groups yet', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/home/profile/groups/create'),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Group'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _showJoinDialog,
                    icon: const Icon(Icons.login),
                    label: const Text('Join with Code'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (_, i) => _groupCard(groups[i]),
          );
        },
      ),
    );
  }

  Widget _groupCard(GroupModel group) {
    final theme = Theme.of(context);
    IconData iconData;
    switch (group.icon) {
      case 'people':
        iconData = Icons.people;
        break;
      case 'trip':
        iconData = Icons.flight;
        break;
      case 'home':
        iconData = Icons.home;
        break;
      case 'work':
        iconData = Icons.work;
        break;
      default:
        iconData = Icons.group;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
          child: Icon(iconData, color: theme.colorScheme.secondary),
        ),
        title: Text(group.name, style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
        subtitle: Text(
          '${group.members.length} members  •  Code: ${group.inviteCode}',
          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
        ),
        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.4)),
        onTap: () => context.push('/home/profile/groups/${group.id}'),
      ),
    );
  }
}
