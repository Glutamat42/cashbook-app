class User {
  final int id;
  final String username;
  final String? token;

  User({required this.id, required this.username, this.token});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'],
      username: json['username'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'username': username,
      'token': token,
    };
  }
}
