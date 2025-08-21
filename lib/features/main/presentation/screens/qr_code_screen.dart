import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mechanic/features/main/presentation/screens/qr_code_overlay.dart';
import 'package:mobile_scanner/mobile_scanner.dart';


class QrCodeScreen extends StatefulWidget {
  const QrCodeScreen({super.key});

  @override
  State<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen> {

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final MobileScannerController controller = MobileScannerController(
    autoStart: false,
  );


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
        MobileScanner(
        controller: controller,
        onDetect: (result) {
          print(result.barcodes.first.rawValue);
        },
      ),
          const QrScannerCornerOverlay(
            windowSize: 260,
            cornerLen: 40,
            cornerRadius: 24,
            strokeWidth: 6,
          ),
        ],
      ),
    );
  }

}


class _BorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}