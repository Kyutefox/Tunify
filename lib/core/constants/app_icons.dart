import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:tunify/ui/theme/app_colors.dart';

/// Centralized icon mappings from [HugeIcons] to semantic names used throughout the app.
///
/// All getters return [List<List<dynamic>>] as required by the HugeIcons API.
/// Use [AppIcon] to render any entry; use [FavouriteIcon] for like-state icons.
class AppIcons {
  AppIcons._();

  static List<List<dynamic>> get back => HugeIcons.strokeRoundedArrowLeft01;
  static List<List<dynamic>> get forward => HugeIcons.strokeRoundedArrowRight01;
  static List<List<dynamic>> get add => HugeIcons.strokeRoundedAdd01;
  static List<List<dynamic>> get addCircle => HugeIcons.strokeRoundedAddCircle;
  static List<List<dynamic>> get newFolder => HugeIcons.strokeRoundedFolderAdd;
  static List<List<dynamic>> get search => HugeIcons.strokeRoundedSearch01;
  static List<List<dynamic>> get clear => HugeIcons.strokeRoundedCancel01;
  static List<List<dynamic>> get close => HugeIcons.strokeRoundedCancel01;
  static List<List<dynamic>> get dropdown => HugeIcons.strokeRoundedArrowDown01;
  static List<List<dynamic>> get arrowUpLeft =>
      HugeIcons.strokeRoundedArrowUpLeft01;
  static List<List<dynamic>> get chevronRight =>
      HugeIcons.strokeRoundedArrowRight01;
  static List<List<dynamic>> get keyboardArrowDown =>
      HugeIcons.strokeRoundedArrowDown01;
  static List<List<dynamic>> get keyboardArrowRight =>
      HugeIcons.strokeRoundedArrowRight01;

  static List<List<dynamic>> get gridView => HugeIcons.strokeRoundedGridView;
  static List<List<dynamic>> get listView => HugeIcons.strokeRoundedListView;

  static List<List<dynamic>> get folder => HugeIcons.strokeRoundedFolder03;
  static List<List<dynamic>> get musicNote =>
      HugeIcons.strokeRoundedMusicNote01;
  static List<List<dynamic>> get playlist => HugeIcons.strokeRoundedPlaylist01;
  static List<List<dynamic>> get playlistAdd =>
      HugeIcons.strokeRoundedPlayListAdd;
  static List<List<dynamic>> get queueMusic => HugeIcons.strokeRoundedPlayList;
  static List<List<dynamic>> get library => HugeIcons.strokeRoundedLibrary;
  static List<List<dynamic>> get home => HugeIcons.strokeRoundedHome01;

  static List<List<dynamic>> get edit => HugeIcons.strokeRoundedEdit04;
  static List<List<dynamic>> get editNote => HugeIcons.strokeRoundedEdit02;
  static List<List<dynamic>> get delete => HugeIcons.strokeRoundedDelete01;
  static List<List<dynamic>> get deleteOutline =>
      HugeIcons.strokeRoundedDelete02;
  static List<List<dynamic>> get check =>
      HugeIcons.strokeRoundedCheckmarkCircle01;
  static List<List<dynamic>> get checkCircle =>
      HugeIcons.strokeRoundedCheckmarkCircle01;
  static List<List<dynamic>> get addCircleOutline =>
      HugeIcons.strokeRoundedAddCircle;
  static List<List<dynamic>> get removeCircle =>
      HugeIcons.strokeRoundedRemoveCircle;
  static List<List<dynamic>> get removeCircleOutline =>
      HugeIcons.strokeRoundedRemoveCircle;
  static List<List<dynamic>> get sort => HugeIcons.strokeRoundedSorting01;
  static List<List<dynamic>> get dragHandle => HugeIcons.strokeRoundedDrag01;
  static List<List<dynamic>> get download => HugeIcons.strokeRoundedDownload03;
  static List<List<dynamic>> get pin => HugeIcons.strokeRoundedPin;
  static List<List<dynamic>> get pinOff => HugeIcons.strokeRoundedPin02;

  static List<List<dynamic>> get play => HugeIcons.strokeRoundedPlay;
  static List<List<dynamic>> get pause => HugeIcons.strokeRoundedPause;
  static List<List<dynamic>> get playCircle =>
      HugeIcons.strokeRoundedPlayCircle;
  static List<List<dynamic>> get playCircleOutline =>
      HugeIcons.strokeRoundedPlayCircle02;
  static List<List<dynamic>> get playCircleFilled =>
      HugeIcons.strokeRoundedPlayCircle;
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

  /// Favourite icon (HugeIcons Stroke Rounded). Used when unliked in [FavouriteIcon].
  static List<List<dynamic>> get favourite => HugeIcons.strokeRoundedFavourite;

  /// Returns a love-theme gradient color deterministically derived from [id].
  /// Delegates to [AppColors.loveThemeColorFor]; provided as a convenience on [AppIcons].
  static Color favouriteColorFor(String? id) =>
      AppColors.loveThemeColorFor(id);

  static List<List<dynamic>> get moreVert => HugeIcons.strokeRoundedMoreVertical;
  static List<List<dynamic>> get moreHoriz => HugeIcons.strokeRoundedMoreHorizontal;

  static List<List<dynamic>> get artist => HugeIcons.strokeRoundedMic01;
  static List<List<dynamic>> get album => HugeIcons.strokeRoundedAlbum01;

  static List<List<dynamic>> get person => HugeIcons.strokeRoundedUser02;
  static List<List<dynamic>> get personOutline => HugeIcons.strokeRoundedUser02;
  static List<List<dynamic>> get logout => HugeIcons.strokeRoundedLogout01;
  static List<List<dynamic>> get mail => HugeIcons.strokeRoundedMail01;
  static List<List<dynamic>> get lock => HugeIcons.strokeRoundedLock;
  static List<List<dynamic>> get visibility => HugeIcons.strokeRoundedEye;
  static List<List<dynamic>> get visibilityOff =>
      HugeIcons.strokeRoundedViewOff;
  static List<List<dynamic>> get markEmailUnread =>
      HugeIcons.strokeRoundedMailOpen01;
  static List<List<dynamic>> get errorOutline =>
      HugeIcons.strokeRoundedAlertCircle;
  static List<List<dynamic>> get verified =>
      HugeIcons.strokeRoundedCheckmarkBadge01;
  static List<List<dynamic>> get notifications =>
      HugeIcons.strokeRoundedNotification01;

  static List<List<dynamic>> get devices => HugeIcons.strokeRoundedDownload03;
  static List<List<dynamic>> get smartphone =>
      HugeIcons.strokeRoundedSmartphoneWifi;
  static List<List<dynamic>> get bluetooth => HugeIcons.strokeRoundedBluetooth;
  static List<List<dynamic>> get bluetoothSearch =>
      HugeIcons.strokeRoundedBluetoothSearch;
  static List<List<dynamic>> get headphones =>
      HugeIcons.strokeRoundedHeadphones;
  static List<List<dynamic>> get cast => HugeIcons.strokeRoundedCastbox;
  static List<List<dynamic>> get tv => HugeIcons.strokeRoundedTv01;
  static List<List<dynamic>> get airplay => HugeIcons.strokeRoundedAirplayLine;
  static List<List<dynamic>> get speakerGroup =>
      HugeIcons.strokeRoundedSpeaker01;
  static List<List<dynamic>> get wifiFind =>
      HugeIcons.strokeRoundedWifiLocation;
  static List<List<dynamic>> get volumeHigh => HugeIcons.strokeRoundedVolumeHigh;
  static List<List<dynamic>> get volumeLow => HugeIcons.strokeRoundedVolumeLow;
  static List<List<dynamic>> get volumeOff => HugeIcons.strokeRoundedVolumeOff;
  static List<List<dynamic>> get refresh => HugeIcons.strokeRoundedRefresh;
  static List<List<dynamic>> get settings => HugeIcons.strokeRoundedSettings01;
  static List<List<dynamic>> get radar => HugeIcons.strokeRoundedRadar01;
  static List<List<dynamic>> get share => HugeIcons.strokeRoundedShare01;

  static List<List<dynamic>> get cloudOff =>
      HugeIcons.strokeRoundedWifiNoSignal;
  static List<List<dynamic>> get brokenImage => HugeIcons.strokeRoundedImageNotFound01;
  static List<List<dynamic>> get wifiOff => HugeIcons.strokeRoundedWifiOff01;

  static List<List<dynamic>> get psychology => HugeIcons.strokeRoundedBrain;
  static List<List<dynamic>> get spa => HugeIcons.strokeRoundedLeaf01;
  static List<List<dynamic>> get fitness => HugeIcons.strokeRoundedFire;
  static List<List<dynamic>> get nightlight => HugeIcons.strokeRoundedMoon01;
  static List<List<dynamic>> get celebration =>
      HugeIcons.strokeRoundedFireworks;
  static List<List<dynamic>> get bolt => HugeIcons.strokeRoundedFire02;
  static List<List<dynamic>> get bedtime => HugeIcons.strokeRoundedMoon02;
  static List<List<dynamic>> get playbackSpeed => HugeIcons.strokeRoundedTimer01;
  static List<List<dynamic>> get github => HugeIcons.strokeRoundedGithub;
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

/// Toggleable heart icon reflecting a liked/unliked state.
///
/// - Unliked: HugeIcons stroke heart outline at [emptyColor].
/// - Liked: Material filled heart at [fillColor] or painted with [gradient].
///
/// When [fillColor] is null, [AppColors.loveThemeColorFor] is called with [songId]
/// to produce a deterministic gradient color for the track.
class FavouriteIcon extends StatelessWidget {
  const FavouriteIcon({
    super.key,
    required this.isLiked,
    this.songId,
    this.size = 24.0,
    this.fillColor,
    this.gradient,
    this.emptyColor,
  });

  final bool isLiked;
  final String? songId;
  final double size;
  /// Solid fill color when liked. Defaults to [AppColors.loveThemeColorFor] derived from [songId].
  final Color? fillColor;
  /// Gradient fill when liked; takes precedence over [fillColor] when non-null.
  final Gradient? gradient;
  /// Outline color when not liked. Defaults to `Color(0xFFB3B3B3)`.
  final Color? emptyColor;

  @override
  Widget build(BuildContext context) {
    final effectiveEmpty = emptyColor ?? const Color(0xFFB3B3B3);
    if (!isLiked) {
      return AppIcon(
        icon: AppIcons.favourite,
        size: size,
        color: effectiveEmpty,
      );
    }
    final icon = Icon(Icons.favorite, size: size);
    if (gradient != null) {
      return ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => gradient!.createShader(bounds),
        child: icon,
      );
    }
    final effectiveFill = fillColor ?? AppColors.loveThemeColorFor(songId);
    return Icon(Icons.favorite, size: size, color: effectiveFill);
  }
}