import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';
import 'package:tunify/v2/core/theme/app_text_styles.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_create_layout.dart';
import 'package:tunify/v2/features/library/presentation/providers/library_providers.dart';

/// Full-screen gradient form to create a playlist or folder (v1-style).
///
/// Pops with [LibraryItem] for new playlists, `true` for new folders, or null on cancel.
class LibraryCreateItemScreen extends ConsumerStatefulWidget {
  const LibraryCreateItemScreen({
    super.key,
    required this.isPlaylist,
    this.initialFolderId,
  });

  final bool isPlaylist;
  final String? initialFolderId;

  @override
  ConsumerState<LibraryCreateItemScreen> createState() => _LibraryCreateItemScreenState();
}

class _LibraryCreateItemScreenState extends ConsumerState<LibraryCreateItemScreen> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _title =>
      widget.isPlaylist ? 'Give your playlist a name' : 'Give your folder a name';

  String get _hint => widget.isPlaylist ? 'Playlist name' : 'Folder name';

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _busy) {
      return;
    }
    setState(() => _busy = true);
    final gw = ref.read(libraryWriteGatewayProvider);
    try {
      if (widget.isPlaylist) {
        final map = await gw.createUserPlaylist(
          name: name,
          folderId: widget.initialFolderId,
        );
        final item = gw.playlistItemFromCreateResponse(map);
        if (mounted) {
          Navigator.of(context).pop<LibraryItem>(item);
        }
      } else {
        await gw.createFolder(name: name);
        if (mounted) {
          Navigator.of(context).pop<bool>(true);
        }
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create (${e.toString()})')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: AppColors.nearBlack,
        resizeToAvoidBottomInset: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.gradientWhite14,
                    AppColors.gradientWhite06,
                    AppColors.transparent,
                  ],
                  stops: const [0.0, 0.35, 1.0],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: AppColors.white),
                        onPressed: _busy ? null : () => Navigator.of(context).pop(),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.sectionTitle.copyWith(
                        fontSize: LibraryCreateLayout.titleFontSize,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyBold.copyWith(
                        fontSize: LibraryCreateLayout.fieldFontSize,
                      ),
                      cursorColor: AppColors.white,
                      decoration: InputDecoration(
                        hintText: _hint,
                        hintStyle: AppTextStyles.bodyBold.copyWith(
                          fontSize: LibraryCreateLayout.fieldFontSize,
                          color: AppColors.silver.withValues(alpha: 0.65),
                        ),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.white),
                        ),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _busy ? null : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: FilledButton(
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Create'),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
