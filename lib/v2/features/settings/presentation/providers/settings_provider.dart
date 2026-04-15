import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings state for backend configuration
///
/// Immutable state per RULES.md - state management guidelines
class SettingsState {
  final String backendUrl;

  const SettingsState({
    this.backendUrl = '',
  });

  SettingsState copyWith({
    String? backendUrl,
  }) {
    return SettingsState(
      backendUrl: backendUrl ?? this.backendUrl,
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
    state = state.copyWith(backendUrl: url);
  }

  /// Saves backend URL to storage
  /// TODO: Implement secure storage integration
  Future<void> saveBackendUrl() async {
    if (!state.isUrlValid) return;
    // TODO: Save to secure storage
  }
}

/// Riverpod provider for settings state
///
/// Global provider for accessing settings throughout the app
final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
