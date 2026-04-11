import 'package:tunify/v2/core/utils/result.dart';
import 'package:tunify/v2/features/auth/domain/entities/user_entity.dart';

/// AuthRepository interface defining authentication operations
/// 
/// Per RULES.md Clean Architecture:
/// - Abstract repository in domain layer
/// - Implementation in data layer
/// - Returns typed results (Result pattern)
abstract class AuthRepository {
  /// Sign in with email and password
  Future<Result<UserEntity>> signInWithEmailPassword(
    String email,
    String password,
  );

  /// Sign up with email, password, and username
  Future<Result<UserEntity>> signUp(
    String email,
    String password,
    String username,
  );

  /// Send password reset email
  Future<Result<void>> sendPasswordResetEmail(String email);

  /// Sign in with Google
  Future<Result<UserEntity>> signInWithGoogle();

  /// Sign in with Apple
  Future<Result<UserEntity>> signInWithApple();

  /// Sign out current user
  Future<Result<void>> signOut();

  /// Get current logged in user
  Future<Result<UserEntity?>> getCurrentUser();
}
