import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class BookingSuccessDialog extends StatelessWidget {
  final String bookingCode;
  final String qrData;

  const BookingSuccessDialog({
    Key? key,
    required this.bookingCode,
    required this.qrData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.close,
                    color: Colors.grey,
                    size: 24,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Title
            const Text(
              'Enter this QR code\nto complete',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 24),

            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 180,
                backgroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // Booking code
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    bookingCode,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: bookingCode));

                    },
                    child: Icon(
                      Icons.copy,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Dialogni ko'rsatish uchun funksiya
void showBookingSuccessDialog(
    BuildContext context, {
      required String bookingCode,
      required String qrData,
    }) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return BookingSuccessDialog(
        bookingCode: bookingCode,
        qrData: qrData,
      );
    },
  );
}