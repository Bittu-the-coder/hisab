class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String currency;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.currency = 'INR',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      currency: json['currency'] ?? 'INR',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'avatar': avatar,
  };
}
