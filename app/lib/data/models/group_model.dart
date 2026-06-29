class GroupModel {
  final String id;
  final String name;
  final String icon;
  final List<dynamic> members;
  final List<dynamic> admins;
  final String createdBy;
  final String inviteCode;
  final DateTime createdAt;

  GroupModel({
    required this.id,
    required this.name,
    this.icon = 'group',
    this.members = const [],
    this.admins = const [],
    required this.createdBy,
    this.inviteCode = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'icon': icon,
    'members': members,
    'admins': admins,
    'createdBy': createdBy,
    'inviteCode': inviteCode,
    'createdAt': createdAt.toIso8601String(),
  };

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? 'group',
      members: json['members'] ?? [],
      admins: json['admins'] ?? [],
      createdBy: json['createdBy'] ?? '',
      inviteCode: json['inviteCode'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
