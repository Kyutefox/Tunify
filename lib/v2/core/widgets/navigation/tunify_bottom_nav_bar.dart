import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/app_icons.dart';
import 'package:tunify/v2/core/constants/navigation_layout.dart';

/// Bottom navigation bar — ported from v1 MobileShell._buildNavBar().
///
/// Solid #121212 background, subtle 0.5px top border, 64px bar,
/// InkWell tap feedback, 24px icons, 11px labels.
class TunifyBottomNavBar extends StatelessWidget {
  const TunifyBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static final _icons = <List<List<dynamic>>>[
    AppIcons.home,
    AppIcons.search,
    AppIcons.libraryMusic,
  ];

  static final _activeIcons = <List<List<dynamic>>>[
    AppIcons.home,
    AppIcons.search,
    AppIcons.libraryMusic,
  ];

  static const _labels = ['Home', 'Search', 'Library'];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: NavigationLayout.barHeight + bottomPadding,
      decoration: BoxDecoration(
        color: AppColors.nearBlack,
        border: const Border(
          top: BorderSide(
            color: AppColors.separator10,
            width: NavigationLayout.topBorderWidth,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding > 0 ? bottomPadding : 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(_labels.length, (i) {
            final selected = currentIndex == i;
            return Expanded(
              child: Material(
                color: AppColors.transparent,
                child: InkWell(
                  onTap: () => onTap(i),
                  splashColor: AppColors.white.withValues(alpha: 0.08),
                  highlightColor: AppColors.white.withValues(alpha: 0.04),
                  child: SizedBox(
                    height: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcon(
                          icon: selected ? _activeIcons[i] : _icons[i],
                          size: NavigationLayout.iconSize,
                          color: selected ? AppColors.white : AppColors.silver,
                        ),
                        const SizedBox(height: NavigationLayout.labelGap),
                        Text(
                          _labels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected ? AppColors.white : AppColors.silver,
                            fontSize: NavigationLayout.labelFontSize,
                            fontWeight: selected
                                ? NavigationLayout.selectedLabelWeight
                                : NavigationLayout.unselectedLabelWeight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
