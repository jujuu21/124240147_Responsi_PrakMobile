class UserModel {
  final int? id;
  final String username;
  final String password;

  UserModel({
    this.id,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'password': password,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      username: map['username'] as String? ?? '',
      password: map['password'] as String? ?? '',
    );
  }
}
