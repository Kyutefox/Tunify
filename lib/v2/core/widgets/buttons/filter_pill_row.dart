import 'package:flutter/widgets.dart';
import 'package:tunify/v2/core/constants/app_spacing.dart';

/// Shared horizontal container for filter pills used across screens.
///
/// This keeps spacing/alignment consistent anywhere filter pills appear.
class FilterPillRow extends StatelessWidget {
  const FilterPillRow({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(children: children),
    );
  }
}
