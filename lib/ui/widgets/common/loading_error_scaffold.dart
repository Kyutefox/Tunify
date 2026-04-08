import 'package:flutter/material.dart';

import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/shell/shell_context.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'back_title_app_bar.dart';
import 'button.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

/// Scaffold with back button and centered loading indicator.
class LoadingScaffold extends StatelessWidget {
  const LoadingScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ShellContext.isDesktopOf(context);
    return Scaffold(
      backgroundColor: AppColorsScheme.of(context).background,
      appBar: isDesktop
          ? null
          : BackTitleAppBar(
              title: '',
              backgroundColor: AppColorsScheme.of(context).background,
            ),
      body: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

/// Scaffold with back button and error message + optional retry button.
class ErrorScaffold extends StatelessWidget {
  const ErrorScaffold({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ShellContext.isDesktopOf(context);
    return Scaffold(
      backgroundColor: AppColorsScheme.of(context).background,
      appBar: isDesktop
          ? null
          : BackTitleAppBar(
              title: '',
              backgroundColor: AppColorsScheme.of(context).background,
            ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: TextStyle(color: AppColorsScheme.of(context).textMuted),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Retry',
                variant: AppButtonVariant.text,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
