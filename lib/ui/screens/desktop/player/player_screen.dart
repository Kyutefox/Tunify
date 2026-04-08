import 'package:flutter/material.dart';
import 'package:tunify/ui/screens/mobile/player/player_screen.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) => const MobilePlayerScreen();
}

void showQueueSheet(BuildContext context) {}
void showLyricsSheet(BuildContext context, {Color? dominantColor}) {}
void showDevicesSheet(BuildContext context) {}
void showSleepTimerSheet(BuildContext context) {}
void showPlaybackSpeedSheet(BuildContext context) {}

class SpeedExtraButton extends StatelessWidget {
  const SpeedExtraButton({
    super.key,
    required this.isActive,
    required this.speed,
    required this.onTap,
  });

  final bool isActive;
  final double speed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Text(
        '${speed.toStringAsFixed(2)}x',
        style: TextStyle(
          color: isActive ? Theme.of(context).colorScheme.primary : null,
          fontSize: 12,
        ),
      ),
    );
  }
}
