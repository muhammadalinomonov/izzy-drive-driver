import 'package:flutter/material.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';

/// The dashed rule that fills the space between a route stop's badge and its
/// price, in the route overview sheet (docs/ui/8.png) and in the support
/// thread's route cards (docs/ui/8-2-2.png).
class DashedLeader extends StatelessWidget {
  const DashedLeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 1, child: CustomPaint(painter: _LeaderPainter()));
  }
}

class _LeaderPainter extends CustomPainter {
  static const double _dash = 4;
  static const double _space = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColor.grey2
      ..strokeWidth = 1;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += _dash + _space) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + _dash).clamp(0, size.width), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LeaderPainter oldDelegate) => false;
}
