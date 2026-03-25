import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/core/utils/debouncer.dart';
import 'package:tunify/features/player/player_state_provider.dart';
import 'package:tunify/features/search/search_provider.dart';
import 'package:tunify/ui/screens/search/search_screen.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';

/// Floating dropdown search panel shown below the desktop top bar when the
/// search field is focused. Reuses [SearchResultsBody] and [RecentSearchSection]
/// from the mobile search screen for consistency.
class DesktopSearchDropdown extends ConsumerStatefulWidget {
  const DesktopSearchDropdown({
    super.key,
    required this.onResultTapped,
    required this.onQuerySelected,
  });

  /// Called after the user taps a song result (so the shell can close the overlay).
  final VoidCallback onResultTapped;

  /// Called when a recent-search chip or suggestion is tapped — shell updates
  /// the search bar text and triggers a new search with this query.
  final ValueChanged<String> onQuerySelected;

  @override
  ConsumerState<DesktopSearchDropdown> createState() =>
      _DesktopSearchDropdownState();
}

class _DesktopSearchDropdownState extends ConsumerState<DesktopSearchDropdown> {
  late final _suggestionsDebouncer =
      Debouncer(const Duration(milliseconds: 220));

  List<String> _suggestions = [];
  String _suggestionsForQuery = '';

  @override
  void initState() {
    super.initState();
    final initial = ref.read(searchProvider).query;
    if (initial.isNotEmpty) _fetchSuggestions(initial);
  }

  @override
  void dispose() {
    _suggestionsDebouncer.dispose();
    super.dispose();
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _suggestionsForQuery = '';
        });
      }
      return;
    }
    final forQuery = query;
    if (mounted) setState(() => _suggestionsForQuery = forQuery);
    try {
      final list =
          await ref.read(streamManagerProvider).getSearchSuggestions(forQuery);
      if (mounted && _suggestionsForQuery == forQuery) {
        setState(() => _suggestions = list);
      }
    } catch (_) {
      if (mounted && _suggestionsForQuery == forQuery) {
        setState(() => _suggestions = []);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(
      searchProvider.select((s) => s.query),
      (_, next) => _suggestionsDebouncer.run(() {
        if (mounted) _fetchSuggestions(next);
      }),
    );

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: SearchResultsBody(
              inlineSuggestions: _suggestions.take(4).toList(),
              inlineSuggestionsForQuery: _suggestionsForQuery,
              onSuggestionTap: widget.onQuerySelected,
              onRecentQueryTap: widget.onQuerySelected,
              onOpenPlayer: (song) {
                ref.read(playerProvider.notifier).playSong(
                      song,
                      queueSource: 'search',
                    );
                widget.onResultTapped();
              },
              emptyStateIcon: AppIcon(
                icon: AppIcons.search,
                color: AppColors.textMuted,
                size: 48,
              ),
              emptyStateHeading: 'Search Tunify',
              emptyStateSubheading: 'Find songs, artists, albums and more',
            ),
          ),
        ),
      ),
    );
  }
}
