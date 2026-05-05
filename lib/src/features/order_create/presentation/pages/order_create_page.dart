import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:taxi_app/src/core/components/app_snack_bar.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/features/order_create/presentation/bloc/order_create_bloc.dart';
import 'package:taxi_app/src/features/order_create/presentation/widgets/address_chip.dart';
import 'package:taxi_app/src/features/order_create/presentation/widgets/photo_grid.dart';
import 'package:taxi_app/src/features/order_create/presentation/widgets/price_input.dart';
import 'package:taxi_app/src/features/order_create/presentation/widgets/recorded_audio_preview.dart';
import 'package:taxi_app/src/features/order_create/presentation/widgets/voice_recorder_in_progress.dart';
import 'package:taxi_app/src/routes/pages.dart';

class OrderCreatePage extends StatefulWidget {
  const OrderCreatePage({super.key});

  @override
  State<OrderCreatePage> createState() => _OrderCreatePageState();
}

class _OrderCreatePageState extends State<OrderCreatePage> {
  static const Duration _maxAudio = Duration(seconds: 120);
  static const Duration _minAudio = Duration(seconds: 1);
  static const int _maxPhotos = 5;

  final _recorder = Record();
  final _picker = ImagePicker();
  final _textController = TextEditingController();
  final _priceController = TextEditingController();
  Timer? _recordingTimer;
  String? _activeRecordingPath;

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recorder.dispose();
    _textController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // ---------- audio ----------

  Future<void> _toggleRecording() async {
    final state = context.read<OrderCreateBloc>().state;
    if (state.isRecording) {
      await _stopRecording();
      return;
    }
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Mikrofon ruxsat berilmadi');
      return;
    }
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(path: path, encoder: AudioEncoder.aacLc, bitRate: 128000, samplingRate: 44100);
    _activeRecordingPath = path;
    if (!mounted) return;
    context.read<OrderCreateBloc>().add(const AudioRecordingStarted());
    _startTicker();
  }

  void _startTicker() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final bloc = context.read<OrderCreateBloc>();
      final elapsed = bloc.state.currentRecordingElapsed + const Duration(seconds: 1);
      bloc.add(AudioRecordingTicked(elapsed));
      if (elapsed >= _maxAudio) {
        await _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    final path = await _recorder.stop();
    if (!mounted) return;
    final bloc = context.read<OrderCreateBloc>();
    final elapsed = bloc.state.currentRecordingElapsed;
    if (path == null || elapsed < _minAudio) {
      bloc.add(const AudioRecordingCancelled());
      if (path != null) {
        try {
          await File(path).delete();
        } catch (_) {}
      }
      if (!mounted) return;
      AppSnackBar.showError(context, 'Yozuv juda qisqa');
      return;
    }
    bloc.add(AudioRecordingStopped(path));
    _activeRecordingPath = null;
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    await _recorder.stop();
    if (_activeRecordingPath != null) {
      try {
        await File(_activeRecordingPath!).delete();
      } catch (_) {}
      _activeRecordingPath = null;
    }
    if (!mounted) return;
    context.read<OrderCreateBloc>().add(const AudioRecordingCancelled());
  }

  // ---------- photos ----------

  Future<void> _pickPhotos() async {
    final state = context.read<OrderCreateBloc>().state;
    final remaining = _maxPhotos - state.photos.length;
    if (remaining <= 0) {
      AppSnackBar.showError(context, 'Maksimum $_maxPhotos rasm');
      return;
    }
    final picked = await _picker.pickMultiImage(imageQuality: 85, maxWidth: 1920);
    if (picked.isEmpty || !mounted) return;
    final files = picked.take(remaining).map((x) => File(x.path)).toList(growable: false);
    context.read<OrderCreateBloc>().add(PhotosAdded(files));
  }

  // ---------- submit ----------

  void _onSubmit() {
    FocusScope.of(context).unfocus();
    context.read<OrderCreateBloc>().add(
      OrderSubmitted(
        onSuccess: (_) {
          if (!mounted) return;
          context.go(Pages.invatesPage);
        },
        onError: (msg) {
          if (!mounted) return;
          AppSnackBar.showError(context, msg);
        },
      ),
    );
  }

  void _showHelpSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Muammoni yozing yoki ovozli habar orqali tushuntirib bering. Rasm yoki video qo\'shsangiz, ish narxini ham kiriting.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderCreateBloc, OrderCreateState>(
      listenWhen: (p, c) => p.status != c.status && c.status == OrderCreateStatus.failure,
      listener: (context, state) {
        if (state.errorMessage.isNotEmpty) {
          AppSnackBar.showError(context, state.errorMessage);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                _Header(address: state.address, onBack: () => context.pop()),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sizda qanday muammo?',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _HintBubble(onTap: _showHelpSheet),
                        const SizedBox(height: 20),
                        if (state.audioPath != null)
                          RecordedAudioPreview(
                            path: state.audioPath!,
                            duration: state.audioDuration,
                            onClear: () => context.read<OrderCreateBloc>().add(const AudioCleared()),
                          ),
                        if (state.audioPath != null) const SizedBox(height: 12),
                        TextField(
                          controller: _textController,
                          maxLines: 4,
                          minLines: 3,
                          onChanged: (v) => context.read<OrderCreateBloc>().add(DescriptionChanged(v)),
                          decoration: InputDecoration(
                            hintText: 'Muammoni yozing...',
                            filled: true,
                            fillColor: AppColor.lightBlue,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColor.kPrimaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Rasm yoki video', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        PhotoGrid(
                          photos: state.photos,
                          maxCount: _maxPhotos,
                          onAdd: _pickPhotos,
                          onRemove: (i) => context.read<OrderCreateBloc>().add(PhotoRemoved(i)),
                        ),
                        const SizedBox(height: 20),
                        Text('Ushbu ish uchun nechpul bermoqchisiz?', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        PriceInput(
                          controller: _priceController,
                          onChanged: (raw) => context.read<OrderCreateBloc>().add(PriceChanged(raw)),
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.isRecording)
                  VoiceRecorderInProgress(
                    elapsed: state.currentRecordingElapsed,
                    onCancel: _cancelRecording,
                    onStop: _stopRecording,
                  )
                else
                  _BottomBar(
                    canSubmit: state.canSubmit,
                    isSubmitting: state.status == OrderCreateStatus.submitting,
                    onMicPressed: _toggleRecording,
                    onAttachPressed: _pickPhotos,
                    onSubmit: _onSubmit,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.address, required this.onBack});

  final String address;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(onPressed: onBack, icon: SvgPicture.asset(AppIcons.back, width: 20, height: 20)),
          Expanded(
            child: Center(child: AddressChip(address: address)),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _HintBubble extends StatelessWidget {
  const _HintBubble({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 312,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: Color(0xFFEFF3F6),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: const Text(
          'Muammoni yozing yoki ovozli habar orqali tushuntirib bering.',
          style: TextStyle(color: Colors.black, fontSize: 15, height: 1.4, letterSpacing: -0.3),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.canSubmit,
    required this.isSubmitting,
    required this.onMicPressed,
    required this.onAttachPressed,
    required this.onSubmit,
  });

  final bool canSubmit;
  final bool isSubmitting;
  final VoidCallback onMicPressed;
  final VoidCallback onAttachPressed;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.paddingOf(context).bottom + 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onAttachPressed,
            icon: SvgPicture.asset(AppIcons.paperclip, width: 24, height: 24),
            style: IconButton.styleFrom(
              backgroundColor: AppColor.lightBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: (canSubmit && !isSubmitting) ? onSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.kPrimaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColor.kPrimaryColor.withValues(alpha: 0.4),
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                elevation: 0,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Yuborish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onMicPressed,
            icon: SvgPicture.asset(
              AppIcons.microphone,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(AppColor.white, BlendMode.srcIn),
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColor.kPrimaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}
