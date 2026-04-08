import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tunify/ui/widgets/common/input_field.dart';
import 'package:tunify/ui/widgets/common/button.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/desktop_tokens.dart';
import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/ui/shell/shell_context.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

/// Centered empty state for [SharedSearchPage] with icon, heading and subheading.
/// Use when there is no query or no results so each page can customize the message.
class SearchPageEmptyState extends StatelessWidget {
  const SearchPageEmptyState({
    super.key,
    required this.icon,
    required this.heading,
    required this.subheading,
  });

  final Widget icon;
  final String heading;
  final String subheading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: AppSpacing.lg),
            Text(
              heading,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColorsScheme.of(context).textPrimary,
                fontSize: AppFontSize.h2,
                fontWeight: FontWeight.w700,
                letterSpacing: AppLetterSpacing.heading,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subheading,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColorsScheme.of(context).textSecondary,
                fontSize: AppFontSize.lg,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SharedSearchPage extends StatelessWidget {
  const SharedSearchPage({
    super.key,
    required this.controller,
    required this.onBack,
    required this.body,
    this.focusNode,
    this.onClear,
    this.hintText = 'Songs, artists, podcasts',
    this.autofocus = true,
  });

  final TextEditingController controller;
  final VoidCallback onBack;
  final Widget body;
  final FocusNode? focusNode;
  final VoidCallback? onClear;
  final String hintText;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ShellContext.isDesktopOf(context);
    final searchBarHPad = isDesktop ? DesktopSpacing.lg : AppSpacing.base;
    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light
            .copyWith(statusBarColor: Colors.transparent)
        : SystemUiOverlayStyle.dark
            .copyWith(statusBarColor: Colors.transparent);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: AppColorsScheme.of(context).background,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  searchBarHPad,
                  AppSpacing.sm,
                  searchBarHPad,
                  AppSpacing.sm,
                ),
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AppIconButton(
                          icon: AppIcon(
                            icon: AppIcons.back,
                            size: 24,
                            color: AppColorsScheme.of(context).textPrimary,
                          ),
                          onPressed: onBack,
                          size: 48,
                          iconSize: 24,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppInputField(
                            controller: controller,
                            focusNode: focusNode,
                            hintText: hintText,
                            textInputAction: TextInputAction.search,
                            style: InputFieldStyle.transparent,
                            autofocus: autofocus,
                          ),
                        ),
                        if (value.text.isNotEmpty)
                          AppIconButton(
                            icon: AppIcon(
                              icon: AppIcons.clear,
                              size: 20,
                              color: AppColorsScheme.of(context).textMuted,
                            ),
                            onPressed: () {
                              controller.clear();
                              focusNode?.unfocus();
                              onClear?.call();
                            },
                            size: 40,
                            iconSize: 20,
                            iconAlignment: Alignment.centerRight,
                          )
                        else
                          const SizedBox(width: AppSpacing.sm),
                      ],
                    );
                  },
                ),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}
