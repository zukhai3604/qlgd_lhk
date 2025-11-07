class UserProfile {
  final String id;
  final String name;
  final String email;
  final String role;
  UserProfile({required this.id, required this.name, required this.email, required this.role});

  factory UserProfile.fromMap(Map<String, dynamic> m) {
    final name = (m['name'] ?? m['full_name'] ?? m['ho_ten'] ?? m['hoten'] ?? '').toString();
    final role = (m['role'] ?? m['user']?['role'] ?? m['data']?['role'] ?? '').toString();
    final email = (m['email'] ?? m['user']?['email'] ?? m['data']?['email'] ?? '').toString();
    final id = (m['id'] ?? m['user']?['id'] ?? m['data']?['id'] ?? '').toString();
    return UserProfile(id: id, name: name, email: email, role: role);
  }
}
