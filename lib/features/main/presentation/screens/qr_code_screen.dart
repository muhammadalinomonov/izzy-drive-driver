import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/assets/constants/icons.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/features/main/presentation/screens/qr_code_overlay.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class QrCodeScreen extends StatefulWidget {
  const QrCodeScreen({super.key});

  @override
  State<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen> with WidgetsBindingObserver {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final MobileScannerController controller = MobileScannerController(
    autoStart: false, // Manual boshlaymiz
  );

  bool _isPermissionGranted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App lifecycle o'zgarishlarini kuzatish
    if (state == AppLifecycleState.resumed) {
      _checkAndRequestPermission();
    }
  }

  Future<void> _initializeCamera() async {
    await _checkAndRequestPermission();

    if (_isPermissionGranted) {
      try {
        await controller.start();
      } catch (e) {
        print('Kamera ishga tushirishda xatolik: $e');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _checkAndRequestPermission() async {
    try {
      final status = await Permission.camera.status;

      if (status == PermissionStatus.granted) {
        setState(() {
          _isPermissionGranted = true;
        });
        return;
      }

      if (status == PermissionStatus.denied) {
        final result = await Permission.camera.request();

        if (result == PermissionStatus.granted) {
          setState(() {
            _isPermissionGranted = true;
          });
          // Ruxsat berilganidan keyin kamerani ishga tushirish
          if (!controller.value.isRunning) {
            await controller.start();
          }
        } else {
          _handlePermissionDenied(result);
        }
      } else if (status == PermissionStatus.permanentlyDenied) {
        _showSettingsDialog();
      }
    } catch (e) {
      print('Permission tekshirishda xatolik: $e');
      Navigator.pop(context);
    }
  }

  void _handlePermissionDenied(PermissionStatus status) {
    if (status == PermissionStatus.permanentlyDenied) {
      _showSettingsDialog();
    } else {
      // Oddiy rad etish
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR kod skanerlash uchun kamera ruxsati kerak'),
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kamera ruxsati'),
          content: const Text(
            'QR kod skanerlash uchun kamera ruxsati kerak. '
                'Sozlamalardan ruxsat bering.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context);
              },
              child: const Text('Bekor qilish'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text('Sozlamalar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isPermissionGranted) {
      return Scaffold(
        appBar: AppBar(title: const Text('QR Scanner')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Kamera ruxsati kerak',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'QR kodlarni skanerlash uchun kameraga ruxsat bering',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkAndRequestPermission,
                child: const Text('Ruxsat berish'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (result) {
              if (result.barcodes.isNotEmpty) {
                final barcode = result.barcodes.first;
                if (barcode.rawValue != null) {
                  print('QR Code: ${barcode.rawValue}');
                  // Bu yerda QR kod bilan nima qilishni belgilang
                }
              }
            },
          ),
          const QrScannerCornerOverlay(
            windowSize: 260,
            cornerLen: 40,
            cornerRadius: 24,
            strokeWidth: 6,
          ),
          Positioned(
            right: 0,
            left: 0,
            bottom: context.padding.bottom + 150,
            child: GestureDetector(
              onTap: () async {
                try {
                  await controller.toggleTorch();
                  setState(() {});
                } catch (e) {
                  print('Torch toggle xatoligi: $e');
                }
              },
              child: Center(
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: white.withValues(alpha: .2), width: 2),
                  ),
                  child: SvgPicture.asset(
                    AppIcons.lightning,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(white, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}