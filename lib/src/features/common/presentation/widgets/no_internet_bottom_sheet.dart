import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/services/connectivity_service.dart';

class NoInternetBottomSheet extends StatefulWidget {
  const NoInternetBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => const NoInternetBottomSheet(),
    );
  }

  @override
  State<NoInternetBottomSheet> createState() => _NoInternetBottomSheetState();
}

class _NoInternetBottomSheetState extends State<NoInternetBottomSheet> {
  bool _checking = false;
  StreamSubscription<bool>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ConnectivityService().onlineStream.listen((online) {
      if (online && mounted) {
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _onCheckPressed() async {
    if (_checking) return;
    setState(() => _checking = true);
    final online = await ConnectivityService().recheck();
    if (!mounted) return;
    if (online) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColor.lightGreyBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),
            Icon(Icons.wifi_off_rounded, size: 48, color: AppColor.red),
            const SizedBox(height: 18),
            const Text(
              'No internet connection',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your Wi-Fi or mobile data, then press the button below.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColor.grey, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _checking ? null : _onCheckPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.blueMain,
                  disabledBackgroundColor: AppColor.blueMain.withValues(alpha: 0.5),
                  foregroundColor: AppColor.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _checking
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColor.white,
                        ),
                      )
                    : const Text(
                        'Try again',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
