/// User entity representing a user in the domain layer
/// 
/// Per RULES.md Clean Architecture:
/// - Domain entities are independent of external frameworks
/// - Contains core business data and logic
class UserEntity {
  final String id;
  final String email;
  final String username;
  final String? displayName;
  final String? photoUrl;

  const UserEntity({
    required this.id,
    required this.email,
    required this.username,
    this.displayName,
    this.photoUrl,
  });
}
