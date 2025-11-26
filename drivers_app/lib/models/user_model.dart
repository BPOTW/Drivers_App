class User {
  final String id;
  final String name;
  final String loginKey;
  final String routeId;
  final bool keyActive;

  User({
    required this.id,
    required this.name,
    required this.loginKey,
    required this.routeId,
    required this.keyActive,
  });

  factory User.fromMap(Map<String, dynamic> map, String id) {
    return User(
      id: id,
      name: map['name'] ?? '',
      loginKey: map['login_key'] ?? '',
      routeId: map['route_id'] ?? '',
      keyActive: map['key_active'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'login_key': loginKey,
      'route_id': routeId,
      'key_active': keyActive,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? loginKey,
    String? routeId,
    bool? keyActive,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      loginKey: loginKey ?? this.loginKey,
      routeId: routeId ?? this.routeId,
      keyActive: keyActive ?? this.keyActive,
    );
  }
}
