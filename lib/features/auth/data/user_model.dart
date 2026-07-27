class UserModel {
  final String id;
  final String? name;
  final String? avatarUrl;
  final DateTime? updatedAt;

  UserModel({required this.id, this.name, this.avatarUrl, this.updatedAt});

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      avatarUrl: map['avatar_url'],
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'avatar_url': avatarUrl,
    'updated_at': DateTime.now().toIso8601String(),
  };
}
