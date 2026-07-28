import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class BookingSuccessDialog extends StatefulWidget {
  final String bookingCode;
  final String qrData;

  const BookingSuccessDialog({
    super.key,
    required this.bookingCode,
    required this.qrData,
  });

  @override
  State<BookingSuccessDialog> createState() => _BookingSuccessDialogState();
}

class _BookingSuccessDialogState extends State<BookingSuccessDialog> {
  bool _copied = false;

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.bookingCode));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
                    size: 20,
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: QrImageView(
                data: widget.qrData,
                version: QrVersions.auto,
                size: 180,
                backgroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // Booking code + copy button
            GestureDetector(
              onTap: _copied ? null : _copyCode,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: _copied ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.bookingCode,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _copied ? Icons.check_circle_outline : Icons.copy,
                        key: ValueKey(_copied),
                        size: 20,
                        color: _copied ? Colors.green : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

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