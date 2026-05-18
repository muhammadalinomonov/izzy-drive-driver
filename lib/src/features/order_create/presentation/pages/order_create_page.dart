import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter, TextInputFormatter;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:taxi_app/src/core/components/app_snack_bar.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/features/order_create/data/model/question_template_model.dart';
import 'package:taxi_app/src/features/order_create/presentation/bloc/order_create_bloc.dart';
import 'package:taxi_app/src/features/order_create/presentation/widgets/address_chip.dart';
import 'package:taxi_app/src/features/order_create/presentation/widgets/order_review_sheet.dart';
import 'package:taxi_app/src/features/order_create/presentation/widgets/photo_grid.dart';
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

  final _recorder = AudioRecorder();
  final _picker = ImagePicker();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _recordingTimer;
  StreamSubscription? _amplitudeSub;
  String? _activeRecordingPath;

  // Telegram-style hold-to-record:
  //  - drag LEFT past [_cancelDragThreshold] then release → cancel
  //  - drag UP past [_lockDragThreshold] → recording locks (hand can release,
  //    recording continues; user then taps "Send" or "Cancel" buttons)
  static const double _cancelDragThreshold = 80.0;
  static const double _lockDragThreshold = 70.0;
  bool _willCancelRecord = false;
  bool _isLockedRecord = false;
  double _recordDragOffset = 0.0;
  double _recordDragOffsetY = 0.0;

  @override
  void initState() {
    super.initState();
    // Fire-and-forget — bloc handles loading state and falls back gracefully.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OrderCreateBloc>().add(const QuestionsFetchRequested());
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _amplitudeSub?.cancel();
    _recorder.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------- audio (Telegram-style hold-to-record) ----------

  /// Long-press start on the mic button — request permission, start recording.
  Future<void> _onMicLongPressStart(LongPressStartDetails _) async {
    final bloc = context.read<OrderCreateBloc>();
    if (bloc.state.isRecording) return;
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Microphone permission denied');
      return;
    }
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
      path: path,
    );
    _activeRecordingPath = path;
    if (!mounted) return;
    setState(() {
      _willCancelRecord = false;
      _isLockedRecord = false;
      _recordDragOffset = 0.0;
      _recordDragOffsetY = 0.0;
    });
    bloc.add(const AudioRecordingStarted());
    _startTicker();
    _startAmplitudeSampling();
  }

  void _startAmplitudeSampling() {
    _amplitudeSub?.cancel();
    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 200))
        .listen((amp) {
      if (!mounted) return;
      // `current` is dBFS — silent ≈ -60, max ≈ 0. Clamp to a friendly range.
      final db = amp.current;
      double normalized;
      if (db.isNaN || db.isInfinite) {
        normalized = 0.0;
      } else {
        normalized = ((db + 50) / 50).clamp(0.0, 1.0);
      }
      context.read<OrderCreateBloc>().add(AudioPeakCaptured(normalized));
    });
  }

  Future<void> _stopAmplitudeSampling() async {
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
  }

  /// Tracks the drag while the user is still holding the mic.
  ///   • LEFT past [_cancelDragThreshold] → marks "release to cancel"
  ///   • UP past [_lockDragThreshold]     → locks the recording so the user
  ///     can release the finger and tap Send / Cancel explicitly
  void _onMicLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (_isLockedRecord) return; // ignore further drag once locked
    if (!context.read<OrderCreateBloc>().state.isRecording) return;
    final dx = details.offsetFromOrigin.dx;
    final dy = details.offsetFromOrigin.dy;
    final clampedX = dx > 0 ? 0.0 : dx;
    final clampedY = dy > 0 ? 0.0 : dy;

    if (-clampedY >= _lockDragThreshold) {
      setState(() {
        _isLockedRecord = true;
        _willCancelRecord = false;
        _recordDragOffset = 0.0;
        _recordDragOffsetY = 0.0;
      });
      return;
    }

    final willCancel = -clampedX >= _cancelDragThreshold;
    if (clampedX != _recordDragOffset ||
        clampedY != _recordDragOffsetY ||
        willCancel != _willCancelRecord) {
      setState(() {
        _recordDragOffset = clampedX;
        _recordDragOffsetY = clampedY;
        _willCancelRecord = willCancel;
      });
    }
  }

  /// Release: if the user locked the recording, leave it running. Otherwise
  /// stop & save unless the drag flagged cancellation.
  Future<void> _onMicLongPressEnd(LongPressEndDetails _) async {
    if (_isLockedRecord) return; // recording stays active
    if (!context.read<OrderCreateBloc>().state.isRecording) return;
    final shouldCancel = _willCancelRecord;
    setState(() {
      _willCancelRecord = false;
      _recordDragOffset = 0.0;
      _recordDragOffsetY = 0.0;
    });
    if (shouldCancel) {
      await _cancelRecording();
    } else {
      await _stopRecording();
    }
  }

  /// Locked-mode tap: save & send the recording.
  Future<void> _onLockedSend() async {
    setState(() => _isLockedRecord = false);
    await _stopRecording();
  }

  /// Locked-mode tap: discard the recording.
  Future<void> _onLockedCancel() async {
    setState(() => _isLockedRecord = false);
    await _cancelRecording();
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
    await _stopAmplitudeSampling();
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
      AppSnackBar.showError(context, 'Recording too short');
      return;
    }
    bloc.add(AudioRecordingStopped(path));
    _activeRecordingPath = null;
    _scrollToBottom();
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    await _stopAmplitudeSampling();
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
      AppSnackBar.showError(context, 'Maximum $_maxPhotos photos');
      return;
    }
    final picked = await _picker.pickMultiImage(imageQuality: 85, maxWidth: 1920);
    if (picked.isEmpty || !mounted) return;
    final files = picked.take(remaining).map((x) => File(x.path)).toList(growable: false);
    context.read<OrderCreateBloc>().add(PhotosAdded(files));
    _scrollToBottom();
  }

  // ---------- input routing ----------

  /// Returns the active question for the chat flow, or `null` once every
  /// question is answered.
  QuestionTemplate? _activeQuestion(OrderCreateState state) {
    final idx = state.currentQuestionIndex;
    if (idx >= state.questions.length) return null;
    return state.questions[idx];
  }

  bool _isPriceStep(OrderCreateState state) {
    final q = _activeQuestion(state);
    return q?.type == QuestionType.price;
  }

  /// Send button — commits whatever is in the input field to bloc state.
  /// Price step → fires [PriceChanged]; otherwise → [DescriptionChanged].
  /// The chat bubble only appears after this commit, never on each
  /// keystroke (so typing one letter no longer "jumps" the flow forward).
  void _onSendDraft() {
    final state = context.read<OrderCreateBloc>().state;
    final raw = _inputController.text.trim();
    if (raw.isEmpty) return;
    final bloc = context.read<OrderCreateBloc>();
    if (_isPriceStep(state)) {
      bloc.add(PriceChanged(raw));
      // Price is the last question — open the review sheet immediately so
      // the user doesn't need a second tap on a separate Yuborish button.
      bloc.add(const ReviewRequested());
      FocusScope.of(context).unfocus();
    } else {
      bloc.add(DescriptionChanged(raw));
    }
    _inputController.clear();
    _scrollToBottom();
  }

  void _onReviewRequested() {
    final bloc = context.read<OrderCreateBloc>();
    if (!bloc.state.canSubmit) {
      AppSnackBar.showError(context, 'Please answer every question');
      return;
    }
    FocusScope.of(context).unfocus();
    bloc.add(const ReviewRequested());
  }

  void _onConfirmSubmit() {
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderCreateBloc, OrderCreateState>(
      listenWhen: (p, c) =>
          (p.status != c.status && c.status == OrderCreateStatus.failure) ||
          p.currentQuestionIndex != c.currentQuestionIndex,
      listener: (context, state) {
        if (state.status == OrderCreateStatus.failure &&
            state.errorMessage.isNotEmpty) {
          AppSnackBar.showError(context, state.errorMessage);
        }
        // When the flow advances into the price step, drop any leftover
        // draft text so the digits-only keyboard starts on a clean slate.
        if (_isPriceStep(state) && _inputController.text.isNotEmpty) {
          _inputController.clear();
        }
      },
      builder: (context, state) {
        return KeyboardDismisser(
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Column(
                children: [
                  _Header(address: state.address, onBack: () => context.pop()),
                  Expanded(
                    child: _ChatTranscript(
                      state: state,
                      scrollController: _scrollController,
                      onPhotoRemoved: (i) =>
                          context.read<OrderCreateBloc>().add(PhotoRemoved(i)),
                      onAudioCleared: () => context
                          .read<OrderCreateBloc>()
                          .add(const AudioCleared()),
                      onSubmit: _onReviewRequested,
                      onAddPhotos: _pickPhotos,
                      onDismissReview: () => context
                          .read<OrderCreateBloc>()
                          .add(const ReviewDismissed()),
                      onConfirmSubmit: _onConfirmSubmit,
                    ),
                  ),
                  if (!state.showReview)
                    _BottomInputBar(
                      controller: _inputController,
                      isPriceStep: _isPriceStep(state),
                      isRecording: state.isRecording,
                      isLocked: _isLockedRecord,
                      recordingElapsed: state.currentRecordingElapsed,
                      willCancel: _willCancelRecord,
                      dragOffset: _recordDragOffset,
                      dragOffsetY: _recordDragOffsetY,
                      onSend: _onSendDraft,
                      onAttachPressed: _pickPhotos,
                      onMicLongPressStart: _onMicLongPressStart,
                      onMicLongPressMoveUpdate: _onMicLongPressMoveUpdate,
                      onMicLongPressEnd: _onMicLongPressEnd,
                      onLockedSend: _onLockedSend,
                      onLockedCancel: _onLockedCancel,
                    ),
                ],
              ),
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
          IconButton(
            onPressed: onBack,
            icon: SvgPicture.asset(AppIcons.back, width: 20, height: 20),
          ),
          Expanded(child: Center(child: AddressChip(address: address))),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _ChatTranscript extends StatelessWidget {
  const _ChatTranscript({
    required this.state,
    required this.scrollController,
    required this.onPhotoRemoved,
    required this.onAudioCleared,
    required this.onSubmit,
    required this.onAddPhotos,
    required this.onDismissReview,
    required this.onConfirmSubmit,
  });

  final OrderCreateState state;
  final ScrollController scrollController;
  final ValueChanged<int> onPhotoRemoved;
  final VoidCallback onAudioCleared;
  final VoidCallback onSubmit;
  final VoidCallback onAddPhotos;
  final VoidCallback onDismissReview;
  final VoidCallback onConfirmSubmit;

  @override
  Widget build(BuildContext context) {
    if (state.questionsStatus == QuestionsLoadStatus.loading &&
        state.questions.isEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    final children = <Widget>[
      const SizedBox(height: 4),
      Text(
        'What is your problem?',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.3,
        ),
      ),
      const SizedBox(height: 16),
    ];

    final lastVisible = state.currentQuestionIndex.clamp(0, state.questions.length);
    for (var i = 0; i <= lastVisible && i < state.questions.length; i++) {
      final q = state.questions[i];
      children.add(_BotBubble(text: q.body));
      children.add(const SizedBox(height: 12));
      if (state.hasAnswerFor(q.type)) {
        children.add(_UserAnswerBubble(
          question: q,
          state: state,
          onPhotoRemoved: onPhotoRemoved,
          onAudioCleared: onAudioCleared,
          onAddPhotos: onAddPhotos,
        ));
        children.add(const SizedBox(height: 12));
      }
    }

    if (state.showReview) {
      children.add(OrderReviewSheet(
        state: state,
        onDismiss: onDismissReview,
        onConfirm: onConfirmSubmit,
      ));
    } else if (state.allQuestionsAnswered && state.canSubmit) {
      children.add(const SizedBox(height: 8));
      children.add(_SubmitButton(
        loading: state.status == OrderCreateStatus.submitting,
        onPressed: onSubmit,
      ));
      children.add(const SizedBox(height: 8));
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: children,
    );
  }
}

class _BotBubble extends StatelessWidget {
  const _BotBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            color: Color(0xFFEFF3F6),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              height: 1.4,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _UserAnswerBubble extends StatelessWidget {
  const _UserAnswerBubble({
    required this.question,
    required this.state,
    required this.onPhotoRemoved,
    required this.onAudioCleared,
    required this.onAddPhotos,
  });

  final QuestionTemplate question;
  final OrderCreateState state;
  final ValueChanged<int> onPhotoRemoved;
  final VoidCallback onAudioCleared;
  final VoidCallback onAddPhotos;

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (content == null) return const SizedBox.shrink();
    return Align(alignment: Alignment.centerRight, child: content);
  }

  Widget? _buildContent(BuildContext context) {
    switch (question.type) {
      case QuestionType.textOrAudio:
      case QuestionType.text:
        final pieces = <Widget>[];
        if (state.audioPath != null) {
          pieces.add(_AudioReply(
            path: state.audioPath!,
            duration: state.audioDuration,
            peaks: state.audioPeaks,
            onClear: onAudioCleared,
          ));
        }
        if (state.description.trim().isNotEmpty) {
          if (pieces.isNotEmpty) pieces.add(const SizedBox(height: 8));
          pieces.add(_TextReply(text: state.description.trim()));
        }
        if (pieces.isEmpty) return null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: pieces,
        );
      case QuestionType.photos:
        return _PhotosReply(
          photos: state.photos,
          maxCount: 5,
          onRemove: onPhotoRemoved,
          onAdd: onAddPhotos,
        );
      case QuestionType.price:
        return _PriceReply(price: state.price);
      case QuestionType.unknown:
        return null;
    }
  }
}

/// Playable audio bubble — taps the circle to play/pause via `just_audio`.
/// The waveform fills in as playback progresses (Telegram-style).
class _AudioReply extends StatefulWidget {
  const _AudioReply({
    required this.path,
    required this.duration,
    required this.peaks,
    required this.onClear,
  });

  final String path;
  final Duration duration;
  final List<double> peaks;
  final VoidCallback onClear;

  @override
  State<_AudioReply> createState() => _AudioReplyState();
}

class _AudioReplyState extends State<_AudioReply> {
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

  @override
  void didUpdateWidget(covariant _AudioReply old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) {
      _initialised = false;
      _position = Duration.zero;
    }
  }

  Future<void> _togglePlay() async {
    if (!_initialised) {
      try {
        await _player.setFilePath(widget.path);
        _initialised = true;
      } catch (_) {
        if (mounted) AppSnackBar.showError(context, 'Could not load audio');
        return;
      }
    }
    if (_player.playing) {
      await _player.pause();
    } else {
      // Restart from the beginning if we finished previously.
      if (_position >= (_player.duration ?? widget.duration)) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    }
  }

  String _format(Duration d) {
    final mm = d.inMinutes.toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  double get _progress {
    final total = _player.duration ?? widget.duration;
    if (total.inMilliseconds <= 0) return 0.0;
    return (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final displayedTime = _isPlaying || _position > Duration.zero
        ? _position
        : widget.duration;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.66,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF3F6),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _togglePlay,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColor.kPrimaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 130,
              height: 22,
              child: _Waveform(peaks: widget.peaks, progress: _progress),
            ),
            const SizedBox(width: 10),
            Text(
              _format(displayedTime),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7073),
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: widget.onClear,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SvgPicture.asset(AppIcons.x, width: 12, height: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Real-amplitude waveform. [peaks] is a list of 0..1 floats captured
/// while recording; if empty, a generic decorative pattern is shown.
/// [progress] (0..1) tints bars up to the current playback position in
/// the primary color (already played) vs a lighter shade (remaining).
class _Waveform extends StatelessWidget {
  const _Waveform({required this.peaks, this.progress = 0.0});

  final List<double> peaks;
  final double progress;

  // Fallback shape when no recording-time amplitudes are available
  // (e.g., audio coming from another client without `voice_peaks`).
  static const List<double> _fallback = [
    0.3, 0.6, 0.9, 0.5, 0.8, 0.4, 0.7, 1.0,
    0.5, 0.8, 0.3, 0.6, 0.9, 0.5, 0.7, 0.4,
    0.8, 0.6, 0.5, 1.0, 0.4, 0.7, 0.3, 0.6,
    0.9, 0.5, 0.8, 0.4, 0.7, 0.6,
  ];

  /// Downsamples [peaks] to roughly [target] bars by bucket-averaging.
  /// Tiny lists are returned as-is.
  List<double> _resample(List<double> source, int target) {
    if (source.isEmpty) return _fallback;
    if (source.length <= target) return source;
    final out = <double>[];
    final bucket = source.length / target;
    for (var i = 0; i < target; i++) {
      final start = (i * bucket).floor();
      final end = ((i + 1) * bucket).floor().clamp(start + 1, source.length);
      var sum = 0.0;
      for (var j = start; j < end; j++) {
        sum += source[j];
      }
      out.add(sum / (end - start));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final bars = _resample(peaks, 30);
    final activePaint = AppColor.kPrimaryColor;
    final inactivePaint = AppColor.kPrimaryColor.withValues(alpha: 0.35);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(bars.length, (i) {
        final active = (i / bars.length) <= progress;
        final h = (bars[i] * 18).clamp(2.0, 18.0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Container(
            width: 2,
            height: h,
            decoration: BoxDecoration(
              color: active ? activePaint : inactivePaint,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _TextReply extends StatelessWidget {
  const _TextReply({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.72,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          color: Color(0xFFEFF3F6),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            height: 1.35,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}

class _PhotosReply extends StatelessWidget {
  const _PhotosReply({
    required this.photos,
    required this.maxCount,
    required this.onRemove,
    required this.onAdd,
  });

  final List<File> photos;
  final int maxCount;
  final ValueChanged<int> onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.82,
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF3F6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: PhotoGrid(
          photos: photos,
          maxCount: maxCount,
          onAdd: onAdd,
          onRemove: onRemove,
        ),
      ),
    );
  }
}

class _PriceReply extends StatelessWidget {
  const _PriceReply({required this.price});

  final String price;

  String get _formatted {
    if (price.isEmpty) return '\$0';
    final n = int.tryParse(price) ?? 0;
    return '\$$n';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3F6),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        _formatted,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.onPressed, required this.loading});

  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.kPrimaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColor.kPrimaryColor.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Send',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

class _BottomInputBar extends StatelessWidget {
  const _BottomInputBar({
    required this.controller,
    required this.isPriceStep,
    required this.isRecording,
    required this.isLocked,
    required this.recordingElapsed,
    required this.willCancel,
    required this.dragOffset,
    required this.dragOffsetY,
    required this.onSend,
    required this.onAttachPressed,
    required this.onMicLongPressStart,
    required this.onMicLongPressMoveUpdate,
    required this.onMicLongPressEnd,
    required this.onLockedSend,
    required this.onLockedCancel,
  });

  final TextEditingController controller;
  final bool isPriceStep;
  final bool isRecording;
  final bool isLocked;
  final Duration recordingElapsed;
  final bool willCancel;
  final double dragOffset;
  final double dragOffsetY;
  final VoidCallback onSend;
  final VoidCallback onAttachPressed;
  final GestureLongPressStartCallback onMicLongPressStart;
  final GestureLongPressMoveUpdateCallback onMicLongPressMoveUpdate;
  final GestureLongPressEndCallback onMicLongPressEnd;
  final VoidCallback onLockedSend;
  final VoidCallback onLockedCancel;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottom + 12),
      // clipBehavior: none so the floating lock hint can overflow upward.
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          _buildRow(context),
          if (isRecording && !isLocked)
            Positioned(
              right: 10,
              bottom: 60 + (-dragOffsetY).clamp(0.0, 120.0),
              child: _LockHintBadge(
                active: -dragOffsetY >= 60.0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context) {
    if (isLocked) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _CancelPill(onTap: onLockedCancel),
          const SizedBox(width: 8),
          Expanded(
            child: _RecordingInfoPill(
              elapsed: recordingElapsed,
              willCancel: false,
              showLockedHint: true,
            ),
          ),
          const SizedBox(width: 8),
          _SquareIconButton(
            onPressed: onLockedSend,
            icon: const Icon(
              Icons.send_rounded,
              color: Colors.white,
              size: 22,
            ),
            background: AppColor.kPrimaryColor,
            iconColor: Colors.white,
          ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Paperclip slides out while recording so the pill spans full width.
        AnimatedSize(
          duration: const Duration(milliseconds: 150),
          child: isRecording
              ? const SizedBox.shrink()
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SquareIconButton(
                      onPressed: onAttachPressed,
                      icon: SvgPicture.asset(
                        AppIcons.paperclip,
                        width: 22,
                        height: 22,
                      ),
                      background: const Color(0xFFEFF3F6),
                      iconColor: AppColor.kPrimaryColor,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
        ),
        Expanded(
          child: isRecording
              ? _RecordingInfoPill(
                  elapsed: recordingElapsed,
                  willCancel: willCancel,
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF3F6),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: controller,
                    keyboardType: isPriceStep
                        ? TextInputType.number
                        : TextInputType.multiline,
                    textInputAction: isPriceStep
                        ? TextInputAction.done
                        : TextInputAction.newline,
                    inputFormatters: isPriceStep
                        ? <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ]
                        : null,
                    onSubmitted: (_) => onSend(),
                    maxLines: isPriceStep ? 1 : 4,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: isPriceStep
                          ? 'Enter price'
                          : 'Text or voice message',
                      border: InputBorder.none,
                      hintStyle: const TextStyle(color: Color(0xFFC5CACD)),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 15, letterSpacing: -0.3),
                  ),
                ),
        ),
        const SizedBox(width: 8),
        // Mic ↔ Send swap. Rebuilds via ValueListenable so the rest of the
        // bar (notably the TextField) doesn't lose focus on every keystroke.
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final hasText = value.text.trim().isNotEmpty;
            final showSend = hasText || (isPriceStep && !isRecording);
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: showSend
                  ? _SendMicSlot(
                      key: const ValueKey('send'),
                      onTap: hasText ? onSend : null,
                      icon: Icons.send_rounded,
                      background: AppColor.kPrimaryColor,
                    )
                  : GestureDetector(
                      key: const ValueKey('mic'),
                      behavior: HitTestBehavior.opaque,
                      onLongPressStart: onMicLongPressStart,
                      onLongPressMoveUpdate: onMicLongPressMoveUpdate,
                      onLongPressEnd: onMicLongPressEnd,
                      onTap: () => AppSnackBar.showError(
                        context,
                        'Hold the mic to record',
                      ),
                      child: Transform.translate(
                        offset:
                            isRecording ? Offset(dragOffset, 0) : Offset.zero,
                        child: AnimatedScale(
                          scale: isRecording ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          child: _SendMicSlot(
                            onTap: null,
                            icon: Icons.mic_none_rounded,
                            background: isRecording && willCancel
                                ? Colors.red
                                : AppColor.kPrimaryColor,
                          ),
                        ),
                      ),
                    ),
            );
          },
        ),
      ],
    );
  }
}

/// Square pill button used for both the mic and send icons so they share
/// identical dimensions and the AnimatedSwitcher swap looks like a
/// continuous transformation.
class _SendMicSlot extends StatelessWidget {
  const _SendMicSlot({
    super.key,
    required this.onTap,
    required this.icon,
    required this.background,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: Icon(icon, color: Colors.white, size: 22)),
        ),
      ),
    );
  }
}

class _LockHintBadge extends StatelessWidget {
  const _LockHintBadge({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final bg = active ? AppColor.kPrimaryColor : Colors.white;
    final iconColor = active ? Colors.white : AppColor.kPrimaryColor;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(Icons.lock_outline_rounded, size: 18, color: iconColor),
    );
  }
}

class _CancelPill extends StatelessWidget {
  const _CancelPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF3F6),
          borderRadius: BorderRadius.circular(50),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Cancel',
          style: TextStyle(
            color: Colors.red,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}

class _RecordingInfoPill extends StatelessWidget {
  const _RecordingInfoPill({
    required this.elapsed,
    required this.willCancel,
    this.showLockedHint = false,
  });

  final Duration elapsed;
  final bool willCancel;
  final bool showLockedHint;

  String get _label {
    final mm = elapsed.inMinutes.toString().padLeft(2, '0');
    final ss = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  String get _hintText {
    if (showLockedHint) return 'Recording — tap send';
    return willCancel ? 'Release to cancel' : '← Slide to cancel · ↑ Lock';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3F6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
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
              letterSpacing: -0.3,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _hintText,
              style: TextStyle(
                color: willCancel ? Colors.red : const Color(0xFF6B7073),
                fontSize: 12,
                fontWeight: willCancel ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: -0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.onPressed,
    required this.icon,
    required this.background,
    required this.iconColor,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final Color background;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      child: InkWell(
        onTap: onPressed,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: icon),
        ),
      ),
    );
  }
}
