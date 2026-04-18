import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Centralized icon mappings from [HugeIcons] to semantic names used throughout the app.
///
/// All getters return [List<List<dynamic>>] as required by the HugeIcons API.
/// Use [AppIcon] to render any entry.
class AppIcons {
  AppIcons._();

  // Navigation
  static List<List<dynamic>> get back => HugeIcons.strokeRoundedArrowLeft01;
  static List<List<dynamic>> get forward => HugeIcons.strokeRoundedArrowRight01;
  static List<List<dynamic>> get chevronRight =>
      HugeIcons.strokeRoundedArrowRight01;
  static List<List<dynamic>> get arrowDown => HugeIcons.strokeRoundedArrowDown01;
  static List<List<dynamic>> get arrowUpLeft =>
      HugeIcons.strokeRoundedArrowUpLeft01;
  static List<List<dynamic>> get swapVert => HugeIcons.strokeRoundedSorting01;
  static List<List<dynamic>> get sensors => HugeIcons.strokeRoundedRadar01;
  static List<List<dynamic>> get northWest => HugeIcons.strokeRoundedArrowUpLeft01;
  static List<List<dynamic>> get camera => HugeIcons.strokeRoundedCamera01;

  // Actions
  static List<List<dynamic>> get add => HugeIcons.strokeRoundedAdd01;
  static List<List<dynamic>> get addCircle => HugeIcons.strokeRoundedAddCircle;
  static List<List<dynamic>> get newFolder => HugeIcons.strokeRoundedFolderAdd;
  static List<List<dynamic>> get search => HugeIcons.strokeRoundedSearch01;
  static List<List<dynamic>> get clear => HugeIcons.strokeRoundedCancel01;
  static List<List<dynamic>> get close => HugeIcons.strokeRoundedCancel01;
  static List<List<dynamic>> get google => HugeIcons.strokeRoundedSearch01;
  static List<List<dynamic>> get apple => HugeIcons.strokeRoundedApple;
  static List<List<dynamic>> get email => HugeIcons.strokeRoundedMail01;
  static List<List<dynamic>> get check =>
      HugeIcons.strokeRoundedCheckmarkCircle01;
  static List<List<dynamic>> get checkCircle =>
      HugeIcons.strokeRoundedCheckmarkCircle01;
  static List<List<dynamic>> get delete => HugeIcons.strokeRoundedDelete01;
  static List<List<dynamic>> get edit => HugeIcons.strokeRoundedEdit04;
  static List<List<dynamic>> get share => HugeIcons.strokeRoundedShare01;
  static List<List<dynamic>> get download => HugeIcons.strokeRoundedDownloadCircle01;

  // View modes
  static List<List<dynamic>> get gridView => HugeIcons.strokeRoundedGridView;
  static List<List<dynamic>> get listView => HugeIcons.strokeRoundedListView;

  // Content types
  static List<List<dynamic>> get folder => HugeIcons.strokeRoundedFolder03;
  static List<List<dynamic>> get musicNote =>
      HugeIcons.strokeRoundedMusicNote01;
  static List<List<dynamic>> get playlist => HugeIcons.strokeRoundedPlaylist01;
  static List<List<dynamic>> get playlistAdd =>
      HugeIcons.strokeRoundedPlayListAdd;
  static List<List<dynamic>> get queueMusic => HugeIcons.strokeRoundedPlayList;
  static List<List<dynamic>> get library => HugeIcons.strokeRoundedLibrary;
  static List<List<dynamic>> get libraryMusic =>
      HugeIcons.strokeRoundedLibrary;
  static List<List<dynamic>> get home => HugeIcons.strokeRoundedHome01;
  static List<List<dynamic>> get artist => HugeIcons.strokeRoundedMic01;
  static List<List<dynamic>> get album => HugeIcons.strokeRoundedAlbum01;
  static List<List<dynamic>> get podcast => HugeIcons.strokeRoundedPodcast;

  // Playback
  static List<List<dynamic>> get play => HugeIcons.strokeRoundedPlay;
  static List<List<dynamic>> get playArrow => HugeIcons.strokeRoundedPlay;
  static List<List<dynamic>> get pause => HugeIcons.strokeRoundedPause;
  static List<List<dynamic>> get playCircle =>
      HugeIcons.strokeRoundedPlayCircle;
  static List<List<dynamic>> get playCircleOutline =>
      HugeIcons.strokeRoundedPlayCircle02;
  static List<List<dynamic>> get skipPrevious =>
      HugeIcons.strokeRoundedBackward01;
  static List<List<dynamic>> get skipNext => HugeIcons.strokeRoundedForward01;
  static List<List<dynamic>> get shuffle => HugeIcons.strokeRoundedShuffle;
  static List<List<dynamic>> get repeat => HugeIcons.strokeRoundedRepeat;
  static List<List<dynamic>> get repeatOne =>
      HugeIcons.strokeRoundedRepeatOne01;
  static List<List<dynamic>> get equalizer =>
      HugeIcons.strokeRoundedMusicNote02;
  static List<List<dynamic>> get lyrics => HugeIcons.strokeRoundedMusicNote03;

  // Organization
  static List<List<dynamic>> get sort => HugeIcons.strokeRoundedSorting01;
  static List<List<dynamic>> get dragHandle => HugeIcons.strokeRoundedDrag01;
  static List<List<dynamic>> get pin => HugeIcons.strokeRoundedPin;
  static List<List<dynamic>> get pushPin => HugeIcons.strokeRoundedPin;
  static List<List<dynamic>> get pinOff => HugeIcons.strokeRoundedPin02;
  static List<List<dynamic>> get bookmark => HugeIcons.strokeRoundedBookmark01;
  static List<List<dynamic>> get bookmarkOutline =>
      HugeIcons.strokeRoundedBookmark02;
  static List<List<dynamic>> get favorite => HugeIcons.strokeRoundedFavourite;
  static List<List<dynamic>> get playlistAddIcon =>
      HugeIcons.strokeRoundedPlayListAdd;

  // More options
  static List<List<dynamic>> get moreVert =>
      HugeIcons.strokeRoundedMoreVertical;
  static List<List<dynamic>> get moreHoriz =>
      HugeIcons.strokeRoundedMoreHorizontal;

  // User & account
  static List<List<dynamic>> get person => HugeIcons.strokeRoundedUser02;
  static List<List<dynamic>> get personOutline => HugeIcons.strokeRoundedUser02;
  static List<List<dynamic>> get logout => HugeIcons.strokeRoundedLogout01;
  static List<List<dynamic>> get settings => HugeIcons.strokeRoundedSettings01;

  // Status & notifications
  static List<List<dynamic>> get notifications =>
      HugeIcons.strokeRoundedNotification01;
  static List<List<dynamic>> get errorOutline =>
      HugeIcons.strokeRoundedAlertCircle;
  static List<List<dynamic>> get verified =>
      HugeIcons.strokeRoundedCheckmarkBadge01;

  // Devices & connectivity
  static List<List<dynamic>> get devices => HugeIcons.strokeRoundedDownload03;
  static List<List<dynamic>> get smartphone =>
      HugeIcons.strokeRoundedSmartphoneWifi;
  static List<List<dynamic>> get bluetooth => HugeIcons.strokeRoundedBluetooth;
  static List<List<dynamic>> get headphones =>
      HugeIcons.strokeRoundedHeadphones;
  static List<List<dynamic>> get cast => HugeIcons.strokeRoundedCastbox;
  static List<List<dynamic>> get speakerGroup =>
      HugeIcons.strokeRoundedSpeaker01;
  static List<List<dynamic>> get volumeHigh =>
      HugeIcons.strokeRoundedVolumeHigh;
  static List<List<dynamic>> get volumeLow => HugeIcons.strokeRoundedVolumeLow;
  static List<List<dynamic>> get volumeOff => HugeIcons.strokeRoundedVolumeOff;
  static List<List<dynamic>> get wifiOff => HugeIcons.strokeRoundedWifiOff01;

  // Miscellaneous
  static List<List<dynamic>> get refresh => HugeIcons.strokeRoundedRefresh;
  static List<List<dynamic>> get visibility => HugeIcons.strokeRoundedEye;
  static List<List<dynamic>> get visibilityOff =>
      HugeIcons.strokeRoundedViewOff;
  static List<List<dynamic>> get cloudOff =>
      HugeIcons.strokeRoundedWifiNoSignal;
  static List<List<dynamic>> get brokenImage =>
      HugeIcons.strokeRoundedImageNotFound01;
  static List<List<dynamic>> get history => HugeIcons.strokeRoundedClock01;
}

/// Renders a single [HugeIcons] icon at the given [size] and optional [color].
///
/// Wraps the icon in a [SizedBox] with [FittedBox] so rendering is consistent
/// regardless of the underlying HugeIcon's intrinsic dimensions.
class AppIcon extends StatelessWidget {
  const AppIcon({
    super.key,
    required this.icon,
    this.size = 24.0,
    this.color,
  });

  final List<List<dynamic>> icon;
  final double size;
  final Color? color;

  static const double _baseIconSize = 24.0;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? IconTheme.of(context).color;
    return SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.center,
        child: HugeIcon(
          icon: icon,
          size: _baseIconSize,
          color: effectiveColor,
        ),
      ),
    );
  }
}
