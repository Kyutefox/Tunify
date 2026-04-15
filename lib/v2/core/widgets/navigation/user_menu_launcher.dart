import 'package:flutter/material.dart';
import 'package:tunify/v2/features/home/presentation/widgets/home_user_menu_panel.dart';

/// App-level user menu launcher — thin core facade so feature screens
/// (library, search, etc.) don't import from the home feature directly.
///
/// RULES.md: Avoid cross-feature dependencies unless through domain layer.
Future<void> launchUserMenu(BuildContext context) => showHomeUserMenu(context);
