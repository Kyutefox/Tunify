import 'package:flutter/material.dart';

class HomeUserMenuSheet extends StatelessWidget {
  const HomeUserMenuSheet({
    super.key,
    required this.username,
    this.email,
    required this.onSignOut,
    required this.onSettings,
    this.onEditProfile,
  });

  final String username;
  final String? email;
  final VoidCallback onSignOut;
  final VoidCallback onSettings;
  final VoidCallback? onEditProfile;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(title: Text(username), subtitle: email != null ? Text(email!) : null),
          if (onEditProfile != null)
            ListTile(title: const Text('Edit Profile'), onTap: onEditProfile),
          ListTile(title: const Text('Settings'), onTap: onSettings),
          ListTile(title: const Text('Sign Out'), onTap: onSignOut),
        ],
      ),
    );
  }
}
