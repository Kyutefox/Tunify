import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility utilities for consistent semantic labeling
class AccessibilityUtils {
  AccessibilityUtils._();

  /// Wraps an icon button with proper semantics
  static Widget iconButton({
    required Widget icon,
    required VoidCallback? onPressed,
    required String label,
    String? hint,
    BoxConstraints? constraints,
    EdgeInsetsGeometry? padding,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: onPressed != null,
      child: IconButton(
        icon: icon,
        onPressed: onPressed,
        constraints: constraints ?? const BoxConstraints(minWidth: 48, minHeight: 48),
        padding: padding ?? EdgeInsets.zero,
      ),
    );
  }

  /// Wraps an image with semantic label
  static Widget image({
    required Widget image,
    required String label,
    bool isDecorative = false,
  }) {
    if (isDecorative) {
      return ExcludeSemantics(child: image);
    }
    return Semantics(
      label: label,
      image: true,
      child: image,
    );
  }

  /// Creates a semantic label for track/song items
  static String trackLabel({
    required String title,
    required String artist,
    String? duration,
  }) {
    final parts = [title, 'by', artist];
    if (duration != null && duration.isNotEmpty) {
      parts.addAll(['duration', duration]);
    }
    return parts.join(' ');
  }

  /// Creates a semantic label for playlist/album items
  static String collectionLabel({
    required String title,
    required String type,
    String? creator,
    int? itemCount,
  }) {
    final parts = [title, type];
    if (creator != null && creator.isNotEmpty) {
      parts.addAll(['by', creator]);
    }
    if (itemCount != null) {
      parts.addAll(['$itemCount items']);
    }
    return parts.join(' ');
  }

  /// Announces a message to screen readers
  static void announce(BuildContext context, String message) {
    SemanticsService.tooltip(message);
  }
}
