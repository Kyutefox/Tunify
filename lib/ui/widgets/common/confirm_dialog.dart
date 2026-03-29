import 'package:flutter/material.dart';

import 'package:tunify/ui/theme/app_colors.dart';
import 'button.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

/// Shows a confirmation dialog. Returns a [Future] that completes with `true`
/// when the user confirms, `false` when cancelled. Caller should perform the
/// action when result is `true`.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String cancelLabel = 'Cancel',
  required String confirmLabel,
  bool isDestructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColorsScheme.of(context).surface,
      title: Text(
        title,
        style: TextStyle(color: AppColorsScheme.of(context).textPrimary),
      ),
      content: Text(
        message,
        style: TextStyle(color: AppColorsScheme.of(context).textSecondary),
      ),
      actions: [
        AppButton(
          label: cancelLabel,
          variant: AppButtonVariant.text,
          foregroundColor: AppColorsScheme.of(context).textMuted,
          onPressed: () => Navigator.pop(ctx, false),
          height: 40,
        ),
        AppButton(
          label: confirmLabel,
          variant: AppButtonVariant.text,
          foregroundColor: isDestructive ? Colors.red : AppColors.primary,
          onPressed: () => Navigator.pop(ctx, true),
          height: 40,
        ),
      ],
    ),
  );
  return result ?? false;
}
