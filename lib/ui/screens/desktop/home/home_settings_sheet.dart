import 'package:flutter/material.dart';

class HomeSettingsSheet extends StatelessWidget {
  const HomeSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: SizedBox(
        height: 220,
        child: Center(child: Text('Settings')),
      ),
    );
  }
}
