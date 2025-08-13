import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BeautifulRadiationWidget extends StatefulWidget {
  final bool isVisible;
  final Offset position;

  const BeautifulRadiationWidget({
    Key? key,
    required this.isVisible,
    required this.position,
  }) : super(key: key);

  @override
  State<BeautifulRadiationWidget> createState() => _BeautifulRadiationWidgetState();
}

class _BeautifulRadiationWidgetState extends State<BeautifulRadiationWidget>
    with TickerProviderStateMixin {
  late AnimationController _radiationController;
  late Animation<double> _radiationAnimation;

  @override
  void initState() {
    super.initState();
    _radiationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) _radiationController.forward(from: 0.0);
    });
    _radiationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _radiationController,
      curve: Curves.easeOut,
    ));
    if (widget.isVisible) _radiationController.repeat();
  }

  @override
  void didUpdateWidget(BeautifulRadiationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) _radiationController.repeat();
    else if (!widget.isVisible && oldWidget.isVisible) _radiationController.stop();
  }

  @override
  void dispose() {
    _radiationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();
    return Positioned(
      left: widget.position.dx - 150,
      top: widget.position.dy - 150,
      child: AnimatedBuilder(
        animation: _radiationAnimation,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(300, 300),
            painter: RadiationPainter(_radiationAnimation.value),
          );
        },
      ),
    );
  }
}

class RadiationPainter extends CustomPainter {
  final double animationValue;
  RadiationPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 4; i++) {
      double waveOffset = i * 0.25;
      double currentWaveProgress = (animationValue + waveOffset) % 1.0;
      double minRadius = 20.0;
      double maxRadius = 120.0;
      double currentRadius = minRadius + (currentWaveProgress * (maxRadius - minRadius));
      double maxOpacity = 0.4 - (i * 0.08);
      double currentOpacity = maxOpacity * (1.0 - currentWaveProgress);
      if (currentOpacity > 0.02) {
        Paint wavePaint = Paint()
          ..color = const Color(0xFF4A90E2).withOpacity(currentOpacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, currentRadius, wavePaint);
        if (currentWaveProgress < 0.8) {
          Paint glowPaint = Paint()
            ..color = const Color(0xFF6BA3E8).withOpacity(currentOpacity * 1.5)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(center, currentRadius * 0.7, glowPaint);
        }
        Paint ringPaint = Paint()
          ..color = const Color(0xFF87CEEB).withOpacity(currentOpacity * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(center, currentRadius, ringPaint);
      }
    }
    Paint platformPaint = Paint()
      ..color = Colors.white.withOpacity(0.95)
      ..style = PaintingStyle.fill;
    Paint platformBorderPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, 18.0, platformPaint);
    canvas.drawCircle(center, 18.0, platformBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
