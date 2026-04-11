import 'package:flutter/material.dart';

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
  final String? subtitle;
  final LinearGradient gradient;

  const Mood({
    required this.id,
    required this.label,
    required this.query,
    this.browseId,
    this.browseParams,
    this.subtitle,
    required this.gradient,
  });
}
