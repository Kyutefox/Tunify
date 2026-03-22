import 'package:flutter/material.dart';

import 'package:tunify/ui/theme/app_colors.dart';
import 'package:tunify/ui/theme/design_tokens.dart';

/// Shows "No [emptyLabel] yet" when [query] is empty, otherwise
/// "No results for \"[query]\"". Use for filtered list empty states.
class EmptyListMessage extends StatelessWidget {
  const EmptyListMessage({
    super.key,
    required this.emptyLabel,
    required this.query,
    this.style,
  });

  final String emptyLabel;
  final String query;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final text = query.isEmpty ? 'No $emptyLabel yet' : 'No results for "$query"';
    return Center(
      child: Text(
        text,
        style: style ?? const TextStyle(color: AppColors.textMuted, fontSize: AppFontSize.base),
      ),
    );
  }
}
