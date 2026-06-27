import '../services/api_service.dart';
import '../models/group_model.dart';

class GroupRepository {
  final ApiService _api;

  GroupRepository(this._api);

  Future<List<GroupModel>> getGroups() async {
    final data = await _api.getGroups();
    return (data['groups'] as List).map((e) => GroupModel.fromJson(e)).toList();
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
    return await _api.getGroup(id);
  }

  Future<GroupModel> updateGroup(String id, String name, String icon) async {
    final data = await _api.updateGroup(id, {'name': name, 'icon': icon});
    return GroupModel.fromJson(data['group']);
  }

  Future<void> deleteGroup(String id) async {
    await _api.deleteGroup(id);
  }
}
