import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/group_repository.dart';
import '../data/models/group_model.dart';
import 'service_providers.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(ref.watch(apiServiceProvider));
});

final groupsProvider = FutureProvider<List<GroupModel>>((ref) {
  return ref.watch(groupRepositoryProvider).getGroups();
});
