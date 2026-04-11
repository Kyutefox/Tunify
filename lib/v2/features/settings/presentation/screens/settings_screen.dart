import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
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

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.nearBlack,
      appBar: AppBar(
        backgroundColor: AppColors.nearBlack,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
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
                  'Enter the URL of your Tunify backend server.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.silver,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Backend URL input
                // Validation logic moved to provider per RULES.md
                AuthInputField(
                  label: 'Backend URL',
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  onChanged: settingsNotifier.setBackendUrl,
                ),

                const SizedBox(height: AppSpacing.xxxl),

                // Save button
                // Disabled when URL is empty or invalid
                // Validation state comes from provider per RULES.md
                AppButtonStyles.brandGreenLargePill(
                  label: 'Save',
                  width: double.infinity,
                  onPressed: settingsState.isUrlValid
                      ? () {
                          // TODO: Save backend URL to secure storage
                          Navigator.of(context).pop();
                        }
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
