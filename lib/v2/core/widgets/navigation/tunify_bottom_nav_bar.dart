import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
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

  static const _icons = <IconData>[
    Icons.home_outlined,
    Icons.search,
    Icons.library_music_outlined,
  ];

  static const _activeIcons = <IconData>[
    Icons.home_filled,
    Icons.search,
    Icons.library_music,
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
              child: _NavItem(
                icon: selected ? _activeIcons[i] : _icons[i],
                label: _labels[i],
                selected: selected,
                onTap: () => onTap(i),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.white : AppColors.silver;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.white.withValues(alpha: 0.08),
        highlightColor: AppColors.white.withValues(alpha: 0.04),
        child: SizedBox(
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: NavigationLayout.iconSize),
              const SizedBox(height: NavigationLayout.labelGap),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
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
    );
  }
}
