import 'package:flutter/material.dart';

import 'package:tunify/ui/theme/design_tokens.dart';
import 'package:tunify/ui/theme/app_colors_scheme.dart';

class SheetDragHandle extends StatelessWidget {
  const SheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColorsScheme.of(context).textMuted.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      ),
    );
  }
}
