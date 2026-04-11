import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';

/// White filled circle with a play arrow (shared hero / podcast pattern).
class TunifyPlayCircleButton extends StatelessWidget {
  const TunifyPlayCircleButton({
    super.key,
    required this.diameter,
    required this.iconSize,
    this.onPressed,
  });

  final double diameter;
  final double iconSize;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: Icon(
            Icons.play_arrow_rounded,
            color: AppColors.nearBlack,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}
