import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/group_repository.dart';
import '../data/models/group_model.dart';
import 'auth_provider.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(ref.watch(apiServiceProvider));
});

final groupsProvider = FutureProvider<List<GroupModel>>((ref) {
  return ref.watch(groupRepositoryProvider).getGroups();
});
