import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_button_styles.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/features/auth/presentation/widgets/auth_input_field.dart';
import 'package:tunify/v2/features/settings/presentation/providers/settings_provider.dart';

/// Settings Screen
///
/// Configure app settings including backend URL
/// Uses Riverpod for state management per RULES.md:
/// - No business logic in UI
/// - State management through providers
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _urlController = TextEditingController();
  bool _didLoad = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      if (!mounted || _didLoad) return;
      _didLoad = true;
      await ref.read(settingsProvider.notifier).loadRemoteBackendStatus();
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    if (_urlController.text != settingsState.backendUrl) {
      _urlController.value = TextEditingValue(
        text: settingsState.backendUrl,
        selection:
            TextSelection.collapsed(offset: settingsState.backendUrl.length),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.nearBlack,
      appBar: AppBar(
        backgroundColor: AppColors.nearBlack,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: AppIcon(icon: AppIcons.back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: AppTextStyles.featureHeading.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl),

                // Section title
                Text(
                  'Backend Configuration',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Description
                Text(
                  'Set a hosted backend URL. Leave empty to stay fully local.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.silver,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                if (settingsState.isLoading) ...[
                  const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Backend URL input
                // Validation logic moved to provider per RULES.md
                AuthInputField(
                  label: 'Backend URL',
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  onChanged: settingsNotifier.setBackendUrl,
                ),

                const SizedBox(height: AppSpacing.sm),
                Text(
                  settingsState.hasRemoteBackend
                      ? 'Remote backend is active.'
                      : 'Remote backend is not configured.',
                  style: AppTextStyles.caption.copyWith(
                    color: settingsState.hasRemoteBackend
                        ? AppColors.brandGreen
                        : AppColors.silver,
                  ),
                ),

                if (settingsState.message != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    settingsState.message!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xxxl),

                // Save button
                // Disabled when URL is empty or invalid
                // Validation state comes from provider per RULES.md
                AppButtonStyles.brandGreenLargePill(
                  label: settingsState.isSaving ? 'Saving...' : 'Save',
                  width: double.infinity,
                  onPressed: settingsState.isUrlValid && !settingsState.isSaving
                      ? () async {
                          final navigator = Navigator.of(context);
                          final ok = await settingsNotifier.saveBackendUrl();
                          if (!mounted) return;
                          if (ok) {
                            navigator.pop();
                          }
                        }
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButtonStyles.darkPill(
                  label: settingsState.isSaving
                      ? 'Please wait...'
                      : 'Clear Remote',
                  width: double.infinity,
                  onPressed:
                      settingsState.isSaving || !settingsState.hasRemoteBackend
                          ? null
                          : () async {
                              final navigator = Navigator.of(context);
                              await settingsNotifier.clearBackendUrl();
                              if (!mounted) return;
                              navigator.pop();
                            },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
