import 'package:flutter/material.dart';

class DesktopAuthLayout extends StatelessWidget {
  const DesktopAuthLayout({
    super.key,
    required this.rightContent,
  });

  final Widget rightContent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: rightContent,
          ),
        ),
      ),
    );
  }
}
