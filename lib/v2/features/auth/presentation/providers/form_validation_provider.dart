import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Form validation state
class FormValidationState {
  final String email;
  final String password;
  final String username;
  final bool agreedToTerms;

  const FormValidationState({
    this.email = '',
    this.password = '',
    this.username = '',
    this.agreedToTerms = false,
  });

  FormValidationState copyWith({
    String? email,
    String? password,
    String? username,
    bool? agreedToTerms,
  }) {
    return FormValidationState(
      email: email ?? this.email,
      password: password ?? this.password,
      username: username ?? this.username,
      agreedToTerms: agreedToTerms ?? this.agreedToTerms,
    );
  }

  /// Validates email format using regex
  bool get isEmailValid {
    if (email.trim().isEmpty) return false;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email.trim());
  }

  /// Checks if password is not empty
  bool get isPasswordValid => password.trim().isNotEmpty;

  /// Checks if username is not empty
  bool get isUsernameValid => username.trim().isNotEmpty;

  /// Validates complete login form (email + password)
  bool get isLoginFormValid =>
      email.trim().isNotEmpty && password.trim().isNotEmpty;

  /// Validates username step (username + terms agreement)
  bool get isUsernameStepValid => isUsernameValid && agreedToTerms;
}

/// Notifier that manages form validation state using modern Riverpod
class FormValidationNotifier extends Notifier<FormValidationState> {
  @override
  FormValidationState build() {
    return const FormValidationState();
  }

  void setEmail(String email) {
    state = state.copyWith(email: email);
  }

  void setPassword(String password) {
    state = state.copyWith(password: password);
  }

  void setUsername(String username) {
    state = state.copyWith(username: username);
  }

  void setAgreedToTerms(bool agreed) {
    state = state.copyWith(agreedToTerms: agreed);
  }

  void toggleAgreedToTerms() {
    state = state.copyWith(agreedToTerms: !state.agreedToTerms);
  }

  void reset() {
    state = const FormValidationState();
  }
}

/// Provider for form validation state using modern Riverpod Notifier
final formValidationProvider =
    NotifierProvider<FormValidationNotifier, FormValidationState>(
  () => FormValidationNotifier(),
);
