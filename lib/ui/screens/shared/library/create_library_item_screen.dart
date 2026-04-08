import 'package:flutter/material.dart';

import 'package:tunify/ui/widgets/common/back_title_app_bar.dart';
import 'package:tunify/ui/widgets/common/button.dart';
import 'package:tunify/ui/widgets/common/input_field.dart';
import 'package:tunify/ui/widgets/common/page_foundation.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

enum CreateLibraryItemMode {
  createPlaylist,
  createFolder,
  renamePlaylist,
  renameFolder,
}

extension CreateLibraryItemModeX on CreateLibraryItemMode {
  String get title {
    switch (this) {
      case CreateLibraryItemMode.createPlaylist:
        return 'Create Playlist';
      case CreateLibraryItemMode.createFolder:
        return 'Create Folder';
      case CreateLibraryItemMode.renamePlaylist:
        return 'Rename Playlist';
      case CreateLibraryItemMode.renameFolder:
        return 'Rename Folder';
    }
  }

  String get hintText {
    switch (this) {
      case CreateLibraryItemMode.createPlaylist:
      case CreateLibraryItemMode.renamePlaylist:
        return 'Playlist name';
      case CreateLibraryItemMode.createFolder:
      case CreateLibraryItemMode.renameFolder:
        return 'Folder name';
    }
  }

  String get saveLabel {
    switch (this) {
      case CreateLibraryItemMode.createPlaylist:
      case CreateLibraryItemMode.createFolder:
        return 'Create';
      case CreateLibraryItemMode.renamePlaylist:
      case CreateLibraryItemMode.renameFolder:
        return 'Save';
    }
  }
}

/// Full-screen screen for creating or renaming a playlist/folder.
/// Pops with [String] name on save, or null on cancel.
class CreateLibraryItemScreen extends StatefulWidget {
  const CreateLibraryItemScreen({
    super.key,
    required this.mode,
    this.initialName = '',
  });

  final CreateLibraryItemMode mode;
  final String initialName;

  @override
  State<CreateLibraryItemScreen> createState() =>
      _CreateLibraryItemScreenState();
}

class _CreateLibraryItemScreenState extends State<CreateLibraryItemScreen>
    with WidgetsBindingObserver {
  late TextEditingController _controller;
  double _keyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final view = View.of(context);
    final height = view.viewInsets.bottom / view.devicePixelRatio;
    if (height != _keyboardHeight) {
      setState(() => _keyboardHeight = height);
    }
  }

  Future<void> _closeScreen([String? result]) async {
    FocusManager.instance.primaryFocus?.unfocus();
    // Let IME dismiss first to avoid a "screen closes before form" feel.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  void _save() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      _closeScreen(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    final isCreateMode = mode == CreateLibraryItemMode.createPlaylist ||
        mode == CreateLibraryItemMode.createFolder;

    if (!isCreateMode) {
      return _buildLegacyRenameScaffold(mode);
    }

    final title = mode == CreateLibraryItemMode.createPlaylist
        ? 'Give your playlist a name'
        : 'Give your folder a name';
    final keyboardInset = _keyboardHeight;
    final keyboardOpen = keyboardInset > 0;
    final adaptiveBottomShift = (keyboardInset * 0.35).clamp(60.0, 150.0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _closeScreen();
      },
      child: AppPageScaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: UIOpacity.medium),
                      Colors.white.withValues(alpha: UIOpacity.faint),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.40, 1.0],
                  ),
                ),
              ),
            ),
            AppCenteredFormBody(
              keyboardOpen: keyboardOpen,
              keyboardShift: adaptiveBottomShift,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColorsScheme.of(context).textPrimary,
                      fontSize: AppFontSize.display2,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColorsScheme.of(context).textPrimary,
                      fontSize: AppFontSize.display3,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: mode.hintText,
                      filled: false,
                      fillColor: Colors.transparent,
                      hintStyle: TextStyle(
                        color: AppColorsScheme.of(context)
                            .textPrimary
                            .withValues(alpha: UIOpacity.emphasis),
                        fontSize: AppFontSize.display3,
                        fontWeight: FontWeight.w500,
                      ),
                      enabledBorder: BorderSide(
                        color: Colors.white.withValues(alpha: UIOpacity.high),
                        width: UIStroke.base,
                      ).toUnderlineInputBorder(),
                      focusedBorder: BorderSide(
                        color: Colors.white,
                        width: UIStroke.focus,
                      ).toUnderlineInputBorder(),
                      border: BorderSide(
                        color: Colors.white.withValues(alpha: UIOpacity.high),
                        width: UIStroke.base,
                      ).toUnderlineInputBorder(),
                    ),
                    onSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _FormActionsRow(
                    onCancel: () => _closeScreen(),
                    onConfirm: _save,
                    confirmLabel: mode.saveLabel,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegacyRenameScaffold(CreateLibraryItemMode mode) {
    return AppPageScaffold(
      resizeToAvoidBottomInset: true,
      appBar: BackTitleAppBar(
        title: mode.title,
        backgroundColor: AppColorsScheme.of(context).background,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton(
              onPressed: _save,
              child: Text(
                mode.saveLabel,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: AppFontSize.xl,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.lg,
          ),
          child: AppInputField(
            controller: _controller,
            hintText: mode.hintText,
            style: InputFieldStyle.filled,
            autofocus: true,
            onSubmitted: (_) => _save(),
          ),
        ),
      ),
    );
  }
}

class _FormActionsRow extends StatelessWidget {
  const _FormActionsRow({
    required this.onCancel,
    required this.onConfirm,
    required this.confirmLabel,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            onPressed: onCancel,
            label: 'Cancel',
            height: UISize.buttonHeightMd,
            variant: AppButtonVariant.outlined,
            foregroundColor: AppColorsScheme.of(context).textPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppButton(
            onPressed: onConfirm,
            label: confirmLabel,
            height: UISize.buttonHeightMd,
            variant: AppButtonVariant.filled,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
          ),
        ),
      ],
    );
  }
}

extension on BorderSide {
  UnderlineInputBorder toUnderlineInputBorder() {
    return UnderlineInputBorder(borderSide: this);
  }
}
