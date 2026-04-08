import 'package:flutter/material.dart';

class DesktopSettingsScreen extends StatelessWidget {
  const DesktopSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const SizedBox.shrink(),
    );
  }
}
