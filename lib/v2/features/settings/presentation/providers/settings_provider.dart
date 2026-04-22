import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/errors/exceptions.dart';
import 'package:tunify/v2/features/auth/presentation/providers/auth_providers.dart';

/// Settings state for backend configuration
///
/// Immutable state per RULES.md - state management guidelines
class SettingsState {
  final String backendUrl;
  final bool isSaving;
  final bool isLoading;
  final String? message;
  final bool hasRemoteBackend;

  const SettingsState({
    this.backendUrl = '',
    this.isSaving = false,
    this.isLoading = false,
    this.message,
    this.hasRemoteBackend = false,
  });

  SettingsState copyWith({
    String? backendUrl,
    bool? isSaving,
    bool? isLoading,
    String? message,
    bool clearMessage = false,
    bool? hasRemoteBackend,
  }) {
    return SettingsState(
      backendUrl: backendUrl ?? this.backendUrl,
      isSaving: isSaving ?? this.isSaving,
      isLoading: isLoading ?? this.isLoading,
      message: clearMessage ? null : (message ?? this.message),
      hasRemoteBackend: hasRemoteBackend ?? this.hasRemoteBackend,
    );
  }

  /// Validates URL format
  /// Business logic moved from UI to provider per RULES.md:
  /// "No business logic in UI"
  bool get isUrlValid {
    final url = backendUrl.trim();
    if (url.isEmpty) return false;
    // Basic URL validation - must start with http:// or https://
    final urlRegex = RegExp(
      r'^https?://[\w.-]+(:\d+)?(/[\w./?%&=-]*)?$',
      caseSensitive: false,
    );
    return urlRegex.hasMatch(url);
  }
}

/// Settings notifier using Riverpod
///
/// State management for settings configuration
/// Per RULES.md: Use Riverpod for state management
class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    return const SettingsState();
  }

  /// Updates backend URL
  void setBackendUrl(String url) {
    state = state.copyWith(backendUrl: url, clearMessage: true);
  }

  /// Loads current remote backend status from local backend.
  Future<void> loadRemoteBackendStatus() async {
    state = state.copyWith(isLoading: true, clearMessage: true);
    final api = ref.read(tunifyApiClientProvider);
    try {
      final body =
          await api.getJson('/v1/system/remote-backend', withAuth: false);
      final hasRemote = body['has_remote_backend'] == true;
      final remoteUrl = (body['remote_backend_url'] as String?)?.trim();
      state = state.copyWith(
        isLoading: false,
        hasRemoteBackend: hasRemote,
        backendUrl: remoteUrl ?? '',
      );
    } on ServerException catch (e) {
      state = state.copyWith(
        isLoading: false,
        message: e.message,
        hasRemoteBackend: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        message: 'Failed to load backend settings',
        hasRemoteBackend: false,
      );
    }
  }

  /// Saves and activates remote backend URL in the bundled local backend.
  Future<bool> saveBackendUrl() async {
    if (!state.isUrlValid || state.isSaving) return false;
    state = state.copyWith(isSaving: true, clearMessage: true);
    final api = ref.read(tunifyApiClientProvider);
    try {
      await api.postJson(
        '/v1/system/remote-backend',
        {'remote_backend_url': state.backendUrl.trim()},
        withAuth: false,
      );
      state = state.copyWith(
        isSaving: false,
        hasRemoteBackend: true,
        message: 'Remote backend saved',
      );
      return true;
    } on ServerException catch (e) {
      state = state.copyWith(isSaving: false, message: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
          isSaving: false, message: 'Failed to save backend URL');
      return false;
    }
  }

  /// Clears remote backend, returning local backend to local-only mode.
  Future<void> clearBackendUrl() async {
    if (state.isSaving) return;
    state = state.copyWith(isSaving: true, clearMessage: true);
    final api = ref.read(tunifyApiClientProvider);
    try {
      await api.deleteJson('/v1/system/remote-backend', withAuth: false);
      state = state.copyWith(
        isSaving: false,
        hasRemoteBackend: false,
        backendUrl: '',
        message: 'Remote backend cleared',
      );
    } on ServerException catch (e) {
      state = state.copyWith(isSaving: false, message: e.message);
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        message: 'Failed to clear backend URL',
      );
    }
  }
}

/// Riverpod provider for settings state
///
/// Global provider for accessing settings throughout the app
final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
