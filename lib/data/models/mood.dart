import 'package:flutter/material.dart';

import 'package:tunify/core/constants/app_icons.dart';

/// A curated mood/genre category used in the mood browse and home feed sections.
///
/// Each [Mood] carries a search query used to fetch matching tracks, and a
/// [gradient] for visual differentiation in the mood tile grid.
class Mood {
  final String id;
  final String label;
  final String query;
  final String? browseId;
  final String? browseParams;
  final String emoji;
  final String? subtitle;
  final LinearGradient gradient;
  final List<List<dynamic>>? icon;

  const Mood({
    required this.id,
    required this.label,
    required this.query,
    this.browseId,
    this.browseParams,
    required this.emoji,
    this.subtitle,
    required this.gradient,
    this.icon,
  });

  /// Default curated mood list shown when the YouTube Music API returns no mood items.
  static final List<Mood> all = [
    Mood(
      id: 'focus',
      label: 'Focus',
      query: 'focus study music instrumental lo-fi',
      emoji: '🎯',
      subtitle: 'Concentrate',
      gradient: LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: AppIcons.psychology,
    ),
    Mood(
      id: 'chill',
      label: 'Chill',
      query: 'chill relaxing music vibes',
      emoji: '😌',
      subtitle: 'Unwind',
      gradient: LinearGradient(
        colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: AppIcons.spa,
    ),
    Mood(
      id: 'workout',
      label: 'Workout',
      query: 'workout gym motivation music',
      emoji: '💪',
      subtitle: 'Get moving',
      gradient: LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFF97316)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: AppIcons.fitness,
    ),
    Mood(
      id: 'night',
      label: 'Night Drive',
      query: 'night drive music synthwave',
      emoji: '🌙',
      subtitle: 'Late nights',
      gradient: LinearGradient(
        colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: AppIcons.nightlight,
    ),
    Mood(
      id: 'party',
      label: 'Party',
      query: 'party dance hits EDM',
      emoji: '🎉',
      subtitle: 'Turn up',
      gradient: LinearGradient(
        colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: AppIcons.celebration,
    ),
    Mood(
      id: 'romance',
      label: 'Romance',
      query: 'romantic love songs ballads',
      emoji: '💕',
      subtitle: 'Love songs',
      gradient: LinearGradient(
        colors: [Color(0xFFE11D48), Color(0xFFF43F5E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: AppIcons.favourite,
    ),
    Mood(
      id: 'energy',
      label: 'Energy',
      query: 'upbeat energetic music hype',
      emoji: '⚡',
      subtitle: 'Power up',
      gradient: LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: AppIcons.bolt,
    ),
    Mood(
      id: 'sleep',
      label: 'Sleep',
      query: 'sleep ambient relaxation music',
      emoji: '😴',
      subtitle: 'Rest well',
      gradient: LinearGradient(
        colors: [Color(0xFF1E293B), Color(0xFF334155)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: AppIcons.bedtime,
    ),
  ];
}
