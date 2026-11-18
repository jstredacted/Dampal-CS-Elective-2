// One row from the "profiles" table, joined with the name of its role.
class Profile {
  const Profile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.roleName,
    this.email,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String roleName;
  final String? email;

  bool get isAdmin => roleName == 'admin';

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? 'Customer' : name;
  }

  // The query selects "roles(role)", so Supabase nests the role as a map.
  factory Profile.fromMap(Map<String, dynamic> map) {
    final role = map['roles'] as Map<String, dynamic>?;
    return Profile(
      id: map['id'] as String,
      firstName: map['firstname'] as String? ?? '',
      lastName: map['lastname'] as String? ?? '',
      roleName: role?['role'] as String? ?? 'customer',
      email: map['email'] as String?,
    );
  }
}
