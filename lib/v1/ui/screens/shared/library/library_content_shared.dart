import 'package:flutter/material.dart';

import 'package:tunify/v1/core/constants/app_icons.dart';
import 'package:tunify/v1/ui/screens/shared/library/library_app_bar.dart';
import 'package:tunify/v1/ui/theme/design_tokens.dart';

class LibraryEmptyStateSpec {
  const LibraryEmptyStateSpec({
    required this.icon,
    required this.message,
  });

  final List<List<dynamic>> icon;
  final String message;
}

LibraryEmptyStateSpec libraryEmptyStateForFilter(LibraryFilter? filter) {
  switch (filter) {
    case LibraryFilter.folders:
      return LibraryEmptyStateSpec(
        icon: AppIcons.folder,
        message: 'Folders you create will appear here',
      );
    case LibraryFilter.podcasts:
      return LibraryEmptyStateSpec(
        icon: AppIcons.podcast,
        message: 'Podcasts you save will appear here',
      );
    case LibraryFilter.audiobooks:
      return LibraryEmptyStateSpec(
        icon: AppIcons.bookOpen,
        message: 'Audiobooks you save will appear here',
      );
    case LibraryFilter.albums:
      return LibraryEmptyStateSpec(
        icon: AppIcons.album,
        message: 'Albums you save will appear here',
      );
    case LibraryFilter.artists:
      return LibraryEmptyStateSpec(
        icon: AppIcons.artist,
        message: 'Artists you follow will appear here',
      );
    case LibraryFilter.all:
    case LibraryFilter.playlists:
    case null:
      return LibraryEmptyStateSpec(
        icon: AppIcons.playlist,
        message: 'Playlists you create will appear here',
      );
  }
}

/// Shared in-place content transition for library surfaces.
///
/// This mirrors route-style behavior used in mobile library:
/// swaps child immediately, then animates only the incoming content.
class LibraryContentSwitcher extends StatefulWidget {
  const LibraryContentSwitcher({
    super.key,
    required this.contentKey,
    required this.child,
  });

  final ValueKey<String> contentKey;
  final Widget child;

  @override
  State<LibraryContentSwitcher> createState() => _LibraryContentSwitcherState();
}

class _LibraryContentSwitcherState extends State<LibraryContentSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  late Widget _current;
  late ValueKey<String> _currentKey;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppDuration.normal,
      value: 1.0,
    );
    final curved = CurvedAnimation(parent: _ctrl, curve: AppCurves.decelerate);
    _fade = curved;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(curved);
    _current = widget.child;
    _currentKey = widget.contentKey;
  }

  @override
  void didUpdateWidget(covariant LibraryContentSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contentKey != _currentKey) {
      _current = widget.child;
      _currentKey = widget.contentKey;
      _ctrl.forward(from: 0);
      return;
    }
    _current = widget.child;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _current,
      ),
    );
  }
}
