import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tunify/core/constants/app_icons.dart';
import 'package:tunify/data/models/audiobook.dart';
import 'package:tunify/data/models/podcast.dart';
import 'package:tunify/features/podcast/podcast_provider.dart';
import 'package:tunify/ui/shell/shell_context.dart';
import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/widgets/common/adaptive_menu.dart';
import 'package:tunify/ui/widgets/common/sheet.dart';

/// Shows options sheet for a podcast (reuses playlist options pattern)
void showPodcastOptionsSheet(
  BuildContext context, {
  required Podcast podcast,
  required WidgetRef ref,
  Rect? anchorRect,
}) {
  final isDesktop = ShellContext.isDesktopPlatform;
  final isSubscribed = ref.read(podcastProvider).isSubscribed(podcast.id);

  if (isDesktop) {
    showAdaptiveMenu(
      context,
      title: podcast.title,
      entries: [
        AppMenuEntry(
          icon: podcast.isPinned ? AppIcons.pinOff : AppIcons.pin,
          label: podcast.isPinned ? 'Unpin' : 'Pin to top',
          onTap: () =>
              ref.read(podcastProvider.notifier).togglePodcastPin(podcast.id),
        ),
        const AppMenuEntry.divider(),
        AppMenuEntry(
          icon: isSubscribed ? AppIcons.checkCircle : AppIcons.add,
          label: isSubscribed ? 'Remove from Library' : 'Add to Library',
          color: isSubscribed ? AppColors.secondary : null,
          onTap: () {
            ref.read(podcastProvider.notifier).toggleSubscription(podcast);
          },
        ),
      ],
      anchorRect: anchorRect,
      forceDesktop: true,
    );
    return;
  }

  showAppSheet(
    context,
    child: PodcastOptionsContent(
      podcast: podcast,
      isSubscribed: isSubscribed,
    ),
  );
}

class PodcastOptionsContent extends ConsumerWidget {
  const PodcastOptionsContent({
    super.key,
    required this.podcast,
    required this.isSubscribed,
  });

  final Podcast podcast;
  final bool isSubscribed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSheetHorizontalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetOptionTile(
            icon: podcast.isPinned ? AppIcons.pinOff : AppIcons.pin,
            label: podcast.isPinned ? 'Unpin' : 'Pin to top',
            showChevron: false,
            onTap: () {
              Navigator.pop(context);
              ref.read(podcastProvider.notifier).togglePodcastPin(podcast.id);
            },
          ),
          SheetOptionTile(
            icon: isSubscribed ? AppIcons.checkCircle : AppIcons.add,
            label: isSubscribed ? 'Remove from Library' : 'Add to Library',
            iconColor: isSubscribed ? AppColors.secondary : null,
            labelColor: isSubscribed ? AppColors.secondary : null,
            showChevron: false,
            onTap: () {
              Navigator.pop(context);
              ref.read(podcastProvider.notifier).toggleSubscription(podcast);
            },
          ),
        ],
      ),
    );
  }
}

/// Shows options sheet for an audiobook (reuses playlist options pattern)
void showAudiobookOptionsSheet(
  BuildContext context, {
  required Audiobook audiobook,
  required WidgetRef ref,
  Rect? anchorRect,
}) {
  final isDesktop = ShellContext.isDesktopPlatform;
  final isSaved = ref.read(podcastProvider).isAudiobookSaved(audiobook.id);

  if (isDesktop) {
    showAdaptiveMenu(
      context,
      title: audiobook.title,
      entries: [
        AppMenuEntry(
          icon: audiobook.isPinned ? AppIcons.pinOff : AppIcons.pin,
          label: audiobook.isPinned ? 'Unpin' : 'Pin to top',
          onTap: () => ref
              .read(podcastProvider.notifier)
              .toggleAudiobookPin(audiobook.id),
        ),
        const AppMenuEntry.divider(),
        AppMenuEntry(
          icon: isSaved ? AppIcons.checkCircle : AppIcons.add,
          label: isSaved ? 'Remove from Library' : 'Add to Library',
          color: isSaved ? AppColors.secondary : null,
          onTap: () {
            ref.read(podcastProvider.notifier).toggleSavedAudiobook(audiobook);
          },
        ),
      ],
      anchorRect: anchorRect,
      forceDesktop: true,
    );
    return;
  }

  showAppSheet(
    context,
    child: AudiobookOptionsContent(
      audiobook: audiobook,
      isSaved: isSaved,
    ),
  );
}

class AudiobookOptionsContent extends ConsumerWidget {
  const AudiobookOptionsContent({
    super.key,
    required this.audiobook,
    required this.isSaved,
  });

  final Audiobook audiobook;
  final bool isSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSheetHorizontalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetOptionTile(
            icon: audiobook.isPinned ? AppIcons.pinOff : AppIcons.pin,
            label: audiobook.isPinned ? 'Unpin' : 'Pin to top',
            showChevron: false,
            onTap: () {
              Navigator.pop(context);
              ref
                  .read(podcastProvider.notifier)
                  .toggleAudiobookPin(audiobook.id);
            },
          ),
          SheetOptionTile(
            icon: isSaved ? AppIcons.checkCircle : AppIcons.add,
            label: isSaved ? 'Remove from Library' : 'Add to Library',
            iconColor: isSaved ? AppColors.secondary : null,
            labelColor: isSaved ? AppColors.secondary : null,
            showChevron: false,
            onTap: () {
              Navigator.pop(context);
              ref.read(podcastProvider.notifier).toggleSavedAudiobook(audiobook);
            },
          ),
        ],
      ),
    );
  }
}
