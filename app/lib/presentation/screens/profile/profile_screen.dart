import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final themeMode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(radius: 40, child: Text(user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 24))),
          const SizedBox(height: 12),
          Text(user?.name ?? '', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          Text(user?.email ?? '', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.secondary)),
          const SizedBox(height: 24),
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat(context, 'This month', '₹0'),
                _stat(context, 'All time', '₹0'),
                _stat(context, 'Expenses', '0'),
              ]),
          )),
          const SizedBox(height: 16),
          Card(child: Column(children: [
            SwitchListTile(
              title: const Text('Dark Mode'),
              secondary: const Icon(Icons.dark_mode),
              value: themeMode == ThemeMode.dark,
              onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('My Groups'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/home/profile/groups'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Budget'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/home/profile/budget'),
            ),
          ])),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    return Column(children: [
      Text(value, style: Theme.of(context).textTheme.titleMedium),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}
