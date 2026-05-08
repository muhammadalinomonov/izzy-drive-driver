import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';

/// Bar shown while recording: red dot, mm:ss timer, cancel + stop CTAs.
class VoiceRecorderInProgress extends StatelessWidget {
  const VoiceRecorderInProgress({
    super.key,
    required this.elapsed,
    required this.onCancel,
    required this.onStop,
  });

  final Duration elapsed;
  final VoidCallback onCancel;
  final VoidCallback onStop;

  String get _label {
    final mm = elapsed.inMinutes.toString().padLeft(2, '0');
    final ss = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        MediaQuery.paddingOf(context).bottom + 12,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColor.lightBlue,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: onCancel,
              icon: SvgPicture.asset(AppIcons.x, width: 20, height: 20),
              tooltip: 'Cancel',
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: onStop,
              icon: SvgPicture.asset(
                AppIcons.microphone,
                width: 22,
                height: 22,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
              style: IconButton.styleFrom(
                backgroundColor: AppColor.kPrimaryColor,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(10),
              ),
              tooltip: 'Stop',
            ),
          ],
        ),
      ),
    );
  }
}
