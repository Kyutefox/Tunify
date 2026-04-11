import 'package:flutter/material.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/core/constants/filter_pill_layout.dart';

/// 30×30 circular close control (Figma “Ico close”).
class FilterClosePillButton extends StatelessWidget {
  const FilterClosePillButton({
    super.key,
    this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.filterPillCloseSurface,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: FilterPillLayout.closeOuterSize,
          height: FilterPillLayout.closeOuterSize,
          child: Center(
            child: CustomPaint(
              size: const Size.square(FilterPillLayout.closeIconBox),
              painter: _CloseCrossPainter(
                color: AppColors.white,
                strokeWidth: FilterPillLayout.closeStrokeWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseCrossPainter extends CustomPainter {
  _CloseCrossPainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final inset = strokeWidth / 2;
    canvas.drawLine(
      Offset(inset, inset),
      Offset(size.width - inset, size.height - inset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
