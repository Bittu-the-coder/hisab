import 'dart:convert';
import '../services/api_service.dart';
import '../services/local_database.dart';
import '../models/group_model.dart';

class GroupRepository {
  final ApiService _api;

  GroupRepository(this._api);

  Future<List<GroupModel>> getGroups() async {
    try {
      final data = await _api.getGroups();
      final groups = (data['groups'] as List).map((e) => GroupModel.fromJson(e)).toList();
      await LocalDatabase.saveGroups(jsonEncode(groups.map((g) => g.toJson()).toList()));
      return groups;
    } catch (_) {
      final cached = await LocalDatabase.getCachedGroups();
      if (cached != null) {
        final list = jsonDecode(cached) as List;
        return list.map((e) => GroupModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      rethrow;
    }
  }

  Future<GroupModel> createGroup(String name, String icon) async {
    final data = await _api.createGroup(name, icon);
    return GroupModel.fromJson(data['group']);
  }

  Future<GroupModel> joinGroup(String inviteCode) async {
    final data = await _api.joinGroup(inviteCode);
    return GroupModel.fromJson(data['group']);
  }

  Future<Map<String, dynamic>> getGroup(String id) async {
    try {
      return await _api.getGroup(id);
    } catch (_) {
      final cached = await LocalDatabase.getCachedGroups();
      if (cached != null) {
        final list = jsonDecode(cached) as List;
        final match = list.cast<Map<String, dynamic>>().firstWhere(
          (g) => g['_id'] == id,
          orElse: () => throw Exception('Group not found'),
        );
        return {'group': match};
      }
      rethrow;
    }
  }

  Future<GroupModel> updateGroup(String id, String name, String icon) async {
    final data = await _api.updateGroup(id, {'name': name, 'icon': icon});
    return GroupModel.fromJson(data['group']);
  }

  Future<void> deleteGroup(String id) async {
    await _api.deleteGroup(id);
  }
}
