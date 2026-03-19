import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tunify_logger/tunify_logger.dart';

SupabaseClient get _supabase => Supabase.instance.client;

/// Transient UI state for sign-in / sign-up operations.
class AuthActionState {
  final bool isLoading;
  final bool emailConfirmationPending;
  final String? error;

  const AuthActionState({
    this.isLoading = false,
    this.emailConfirmationPending = false,
    this.error,
  });

  AuthActionState copyWith({
    bool? isLoading,
    bool? emailConfirmationPending,
    String? error,
  }) =>
      AuthActionState(
        isLoading: isLoading ?? this.isLoading,
        emailConfirmationPending:
            emailConfirmationPending ?? this.emailConfirmationPending,
        error: error,
      );
}

/// Streams Supabase [AuthChangeEvent]s (signIn, signOut, tokenRefreshed, etc.).
final authStateProvider = StreamProvider<AuthChangeEvent>((ref) {
  return _supabase.auth.onAuthStateChange.map((e) => e.event);
});

/// Streams the active Supabase [Session], or null when signed out.
final authSessionProvider = StreamProvider<Session?>((ref) {
  return _supabase.auth.onAuthStateChange.map((e) => e.session);
});

/// The currently authenticated [User], or null when signed out or in guest mode.
final currentUserProvider = Provider<User?>((ref) {
  final session = ref.watch(authSessionProvider).value;
  return session?.user ?? _supabase.auth.currentUser;
});

/// Handles sign-in, sign-up, and sign-out against Supabase Auth.
///
/// Exposes [AuthActionState] for the UI to drive loading indicators and error messages.
class AuthNotifier extends StateNotifier<AuthActionState> {
  AuthNotifier() : super(const AuthActionState());

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _supabase.auth
          .signInWithPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(const Duration(seconds: 10));
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      logWarning('Auth: signIn AuthException: ${e.message}', tag: 'Auth');
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } on TimeoutException {
      logWarning('Auth: signIn timeout after 10 seconds', tag: 'Auth');
      state = state.copyWith(
          isLoading: false, error: 'Connection timed out. Please check your internet.');
      return false;
    } catch (e, st) {
      logError('Auth: signIn unexpected error: $e\n$st', tag: 'Auth');
      state = state.copyWith(isLoading: false, error: 'Sign in failed. Please try again.');
      return false;
    }
  }

  Future<bool> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
        isLoading: true, error: null, emailConfirmationPending: false);
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'username': username.trim()},
      ).timeout(const Duration(seconds: 10));

      if (response.session == null) {
        state =
            state.copyWith(isLoading: false, emailConfirmationPending: true);
        logInfo('Auth: signUp completed, email confirmation required', tag: 'Auth');
      } else {
        state = state.copyWith(isLoading: false);
        logInfo('Auth: signUp completed, user logged in', tag: 'Auth');
      }
      return true;
    } on AuthException catch (e) {
      logWarning('Auth: signUp AuthException: ${e.message}', tag: 'Auth');
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } on TimeoutException {
      logWarning('Auth: signUp timeout after 10 seconds', tag: 'Auth');
      state = state.copyWith(
          isLoading: false,
          error: 'Connection timed out. Please check your internet and try again.');
      return false;
    } catch (e, st) {
      logError('Auth: signUp unexpected error: $e\n$st', tag: 'Auth');
      state = state.copyWith(isLoading: false, error: 'Sign up failed. Please try again.');
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      logWarning('Auth: signOut failed: $e', tag: 'Auth');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void clearError() =>
      state = state.copyWith(error: null, emailConfirmationPending: false);
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthActionState>(
  (_) => AuthNotifier(),
);

/// Manages guest-mode state, persisted to [SharedPreferences] across launches.
///
/// Guest mode allows access to the app without a Supabase account;
/// library features that require authentication are hidden.
class GuestModeNotifier extends StateNotifier<bool> {
  GuestModeNotifier() : super(false) {
    _restore();
  }

  static const String _guestModeKey = 'guest_mode_enabled';

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_guestModeKey) ?? false;
    } catch (e) {
      logWarning('Auth: GuestMode _restore failed: $e', tag: 'Auth');
    }
  }

  Future<void> _persist(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_guestModeKey, value);
    } catch (e) {
      logWarning('Auth: GuestMode _persist failed: $e', tag: 'Auth');
    }
  }

  Future<void> enterGuestMode() async {
    state = true;
    await _persist(true);
  }

  Future<void> exitGuestMode() async {
    state = false;
    await _persist(false);
  }
}

final guestModeProvider = StateNotifierProvider<GuestModeNotifier, bool>(
  (_) => GuestModeNotifier(),
);
