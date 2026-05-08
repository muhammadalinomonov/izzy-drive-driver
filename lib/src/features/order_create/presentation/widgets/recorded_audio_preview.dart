import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';

/// Compact preview of a recorded voice message: mic icon + duration + delete.
/// Tapping the audio doesn't play (kept as TODO — voice_message_player can
/// be wired in once the wizard flow is verified).
class RecordedAudioPreview extends StatelessWidget {
  const RecordedAudioPreview({
    super.key,
    required this.path,
    required this.duration,
    required this.onClear,
  });

  final String path;
  final Duration duration;
  final VoidCallback onClear;

  String get _label {
    final mm = duration.inMinutes.toString().padLeft(2, '0');
    final ss = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColor.lightBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SvgPicture.asset(AppIcons.microphone, width: 20, height: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Voice message — $_label',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: SvgPicture.asset(AppIcons.x, width: 16, height: 16),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}
