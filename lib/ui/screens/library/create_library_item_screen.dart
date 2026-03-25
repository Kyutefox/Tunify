import 'package:flutter/material.dart';

import 'package:tunify/ui/widgets/common/back_title_app_bar.dart';
import 'package:tunify/ui/widgets/common/input_field.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';

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

class _CreateLibraryItemScreenState extends State<CreateLibraryItemScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      Navigator.of(context).pop(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackTitleAppBar(
        title: mode.title,
        backgroundColor: AppColors.background,
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
