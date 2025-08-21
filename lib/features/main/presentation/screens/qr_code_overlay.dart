import 'package:flutter/material.dart';

class QrScannerCornerOverlay extends StatelessWidget {
  const QrScannerCornerOverlay({
    super.key,
    this.windowSize = 260,
    this.cornerLen = 36,
    this.cornerRadius = 22,
    this.strokeWidth = 6,
    this.overlayColor = const Color(0x99000000),
    this.cornerColor = Colors.white,
  });

  /// Markazdagi “teshik” kvadratning o‘lchami
  final double windowSize;

  /// Har bir burchakdagi chiziq uzunligi (gorizontal/vertikal)
  final double cornerLen;

  /// Burchakning yumaloqlik radiusi
  final double cornerRadius;

  /// Burchak chiziqlari qalinligi
  final double strokeWidth;

  /// Atrofi qoraytiruvchi rang
  final Color overlayColor;

  /// Burchaklarning rangi
  final Color cornerColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Atrofni qoraytirish va markazda teshik ochish
        Positioned.fill(
          child: CustomPaint(
            painter: _HolePainter(
              windowSize: windowSize - 20,
              radius: cornerRadius,
              color: overlayColor,
            ),
          ),
        ),
        // Faqat burchaklarni chizish
        Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: windowSize,
            height: windowSize,
            child: CustomPaint(
              painter: _CornerPainter(
                cornerLen: cornerLen,
                radius: cornerRadius,
                strokeWidth: strokeWidth,
                color: cornerColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HolePainter extends CustomPainter {
  _HolePainter({
    required this.windowSize,
    required this.radius,
    required this.color,
  });

  final double windowSize;
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Path()..addRect(Offset.zero & size);
    final left = (size.width - windowSize) / 2;
    final top = (size.height - windowSize) / 2;

    final inner = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, windowSize, windowSize),
          Radius.circular(radius),
        ),
      );

    final diff = Path.combine(PathOperation.difference, outer, inner);
    final paint = Paint()..color = color;
    canvas.drawPath(diff, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({
    required this.cornerLen,
    required this.radius,
    required this.strokeWidth,
    required this.color,
  });

  final double cornerLen;
  final double radius;
  final double strokeWidth;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // ┏ top-left
    final tl = Path()
      ..moveTo(0, cornerLen)
      ..lineTo(0, radius)
      ..arcToPoint(Offset(radius, 0), radius: Radius.circular(radius), clockwise: true)
      ..lineTo(cornerLen, 0);

    // ┓ top-right
    final tr = Path()
      ..moveTo(size.width - cornerLen, 0)
      ..lineTo(size.width - radius, 0)
      ..arcToPoint(Offset(size.width, radius), radius: Radius.circular(radius), clockwise: true)
      ..lineTo(size.width, cornerLen);

    // ┗ bottom-left
    final bl = Path()
      ..moveTo(0, size.height - cornerLen)
      ..lineTo(0, size.height - radius)
      ..arcToPoint(Offset(radius, size.height), radius: Radius.circular(radius), clockwise: false)
      ..lineTo(cornerLen, size.height);

    // ┛ bottom-right
    final br = Path()
      ..moveTo(size.width, size.height - cornerLen)
      ..lineTo(size.width, size.height - radius)
      ..arcToPoint(Offset(size.width - radius, size.height), radius: Radius.circular(radius), clockwise: true)
      ..lineTo(size.width - cornerLen, size.height);

    canvas.drawPath(tl, p);
    canvas.drawPath(tr, p);
    canvas.drawPath(bl, p);
    canvas.drawPath(br, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
