import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/core/constants/color/app_icons.dart';
import 'package:taxi_app/features/order_create/data/model/order_message.dart';
import 'package:taxi_app/features/order_create/presentation/bloc/order_create_bloc.dart';
import 'package:taxi_app/features/order_create/presentation/widgets/photo_preview.dart';

/// Inline summary card shown at the bottom of the chat when the user
/// taps "Yuborish". Matches Figma `1818:25684` - title, three sections
/// (audio/photos/price), edit shortcuts, and the final submit button.
class OrderReviewSheet extends StatelessWidget {
  const OrderReviewSheet({
    super.key,
    required this.state,
    required this.onDismiss,
    required this.onConfirm,
    required this.onAddPhoto,
    required this.onAddDetails,
    required this.onChangePrice,
  });

  final OrderCreateState state;
  final VoidCallback onDismiss;
  final VoidCallback onConfirm;
  // Har bir tahrir tugmasi alohida handler - preview yopiladi va kerakli
  // input/picker darhol ochiladi, foydalanuvchi nima qilishi mumkinligi
  // aniq bo'ladi (keyboard, focus, pre-filled value).
  final VoidCallback onAddPhoto;
  final VoidCallback onAddDetails;
  final VoidCallback onChangePrice;

  String get _formattedPrice {
    if (state.price.isEmpty) return '\$0';
    final n = int.tryParse(state.price) ?? 0;
    return '\$$n';
  }

  static String _formatDuration(Duration d) {
    final mm = d.inMinutes.toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Let's review..",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: Colors.black,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onDismiss,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: SvgPicture.asset(AppIcons.x, width: 14, height: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.messages.isNotEmpty)
            _ReviewSection(
              label: 'Description or audio',
              child: _AudioOrTextSummary(state: state),
            ),
          if (state.photos.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ReviewSection(
              label: 'Photo or video',
              child: _PhotosSummary(photos: state.photos),
            ),
          ],
          const SizedBox(height: 16),
          _ReviewSection(
            label: 'How much do you want to pay?',
            child: Text(
              _formattedPrice,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'If everything looks right, tap "Send" - or type "send" in the chat.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7073),
              fontStyle: FontStyle.italic,
              height: 1.4,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'I want to add:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          _EditAction(label: 'Add another photo', onTap: onAddPhoto),
          const SizedBox(height: 8),
          _EditAction(label: 'Add more details', onTap: onAddDetails),
          const SizedBox(height: 8),
          _EditAction(label: 'Change the price', onTap: onChangePrice),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.status == OrderCreateStatus.submitting
                  ? null
                  : onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.kPrimaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColor.kPrimaryColor.withValues(alpha: 0.5),
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                elevation: 0,
              ),
              child: state.status == OrderCreateStatus.submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Send',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7073),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _AudioOrTextSummary extends StatelessWidget {
  const _AudioOrTextSummary({required this.state});

  final OrderCreateState state;

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    for (final m in state.messages) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 8));
      switch (m) {
        case OrderTextMessage():
          widgets.add(Text(
            m.text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.black,
            ),
          ));
        case OrderAudioMessage():
          widgets.add(_MiniAudio(
            path: m.path,
            peaks: m.peaks,
            duration: m.duration,
            label: OrderReviewSheet._formatDuration(m.duration),
          ));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

class _MiniAudio extends StatefulWidget {
  const _MiniAudio({
    required this.path,
    required this.peaks,
    required this.duration,
    required this.label,
  });

  final String path;
  final List<double> peaks;
  final Duration duration;
  final String label;

  @override
  State<_MiniAudio> createState() => _MiniAudioState();
}

class _MiniAudioState extends State<_MiniAudio> {
  final _player = AudioPlayer();
  bool _initialised = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((s) {
      if (!mounted) return;
      setState(() => _isPlaying = s.playing);
      if (s.processingState == ProcessingState.completed) {
        _player.pause();
        _player.seek(Duration.zero);
      }
    });
    _player.positionStream.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (!_initialised) {
      try {
        await _player.setFilePath(widget.path);
        _initialised = true;
      } catch (_) {
        return;
      }
    }
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  double get _progress {
    final total = _player.duration ?? widget.duration;
    if (total.inMilliseconds <= 0) return 0.0;
    return (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
  }

  /// Same Telegram-style interpolation as the chat bubble waveform — short
  /// clips are stretched so the bar still feels full instead of looking
  /// like a handful of stubs at the start.
  List<double> _resample(List<double> src, int target) {
    if (src.isEmpty) {
      return List<double>.generate(target, (i) => (i % 4 + 1) / 5);
    }
    if (src.length == target) return src;
    if (src.length < target) {
      final out = <double>[];
      for (var i = 0; i < target; i++) {
        if (target == 1) {
          out.add(src[0]);
          continue;
        }
        final pos = i * (src.length - 1) / (target - 1);
        final lo = pos.floor();
        final hi = pos.ceil().clamp(0, src.length - 1);
        if (lo == hi) {
          out.add(src[lo]);
        } else {
          final t = pos - lo;
          out.add(src[lo] * (1 - t) + src[hi] * t);
        }
      }
      return out;
    }
    final out = <double>[];
    final bucket = src.length / target;
    for (var i = 0; i < target; i++) {
      final start = (i * bucket).floor();
      final end = ((i + 1) * bucket).floor().clamp(start + 1, src.length);
      var sum = 0.0;
      for (var j = start; j < end; j++) {
        sum += src[j];
      }
      out.add(sum / (end - start));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    const int barCount = 38;
    final bars = _resample(widget.peaks, barCount);
    final activeColor = AppColor.kPrimaryColor;
    final inactiveColor = AppColor.kPrimaryColor.withValues(alpha: 0.35);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColor.kPrimaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 24,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxH = constraints.maxHeight;
                  final minH = (maxH * 0.18).clamp(3.0, 5.0);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(barCount, (i) {
                      final active = (i / barCount) <= _progress;
                      return Container(
                        width: 2.5,
                        height: (bars[i] * maxH).clamp(minH, maxH),
                        decoration: BoxDecoration(
                          color: active ? activeColor : inactiveColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7073),
              fontWeight: FontWeight.w500,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotosSummary extends StatelessWidget {
  const _PhotosSummary({required this.photos});

  final List<File> photos;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(photos.length, (i) {
        return GestureDetector(
          onTap: () => openPhotoPreview(
            context,
            photos: photos,
            initialIndex: i,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 72,
              height: 72,
              child: Image.file(photos[i], fit: BoxFit.cover),
            ),
          ),
        );
      }),
    );
  }
}

class _EditAction extends StatelessWidget {
  const _EditAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}
