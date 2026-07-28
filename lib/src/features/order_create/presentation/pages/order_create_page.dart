import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter, HapticFeedback, TextInputFormatter;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:taxi_app/src/core/components/app_snack_bar.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';
import 'package:taxi_app/src/features/order_create/data/model/order_message.dart';
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
  final _inputFocusNode = FocusNode();
  final _scrollController = ScrollController();

  // Lets _stopRecording surface "Recording too short" inside the mic tooltip
  // bubble instead of the bottom snackbar.
  final _micButtonKey = GlobalKey<_MicHoldHintButtonState>();
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
    // Fire-and-forget - bloc handles loading state and falls back gracefully.
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
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------- audio (Telegram-style hold-to-record) ----------

  /// Long-press start on the mic button - request permission, start recording.
  Future<void> _onMicLongPressStart(LongPressStartDetails _) async {
    final bloc = context.read<OrderCreateBloc>();
    if (bloc.state.isRecording) return;
    if (!await _ensureMicPermission()) return;
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        // `mixWithOthers` — iOS'da AVAudioSession'ni boshqa app (Zoom, Meet,
        // musiqa player, Telegram va h.k.) bilan birgalikda ishlashga ruxsat
        // beradi; aks holda default `playAndRecord` boshqa session'larni
        // to'xtatib qo'yardi va recording boshlanmaydi. Mavjud defaults
        // (defaultToSpeaker, allowBluetooth*) saqlanadi.
        iosConfig: IosRecordConfig(
          categoryOptions: [
            IosAudioCategoryOption.mixWithOthers,
            IosAudioCategoryOption.defaultToSpeaker,
            IosAudioCategoryOption.allowBluetooth,
            IosAudioCategoryOption.allowBluetoothA2DP,
          ],
        ),
        // Android'da `voiceCommunication` source — VoIP-friendly: echo
        // cancellation, automatic gain control, va boshqa VoIP appga
        // tegmasdan ishlaydi. CELLULAR call paytida OS baribir mic'ni
        // bloklaydi, lekin Zoom/Meet/WhatsApp call paytida ishlaydi.
        androidConfig: AndroidRecordConfig(
          audioSource: AndroidAudioSource.voiceCommunication,
          manageBluetooth: true,
        ),
      ),
      path: path,
    );
    _activeRecordingPath = path;
    if (!mounted) return;
    // Recording successfully began - small confirmation tap. lightImpact is
    // the gentlest "something just happened" feedback that's audible on both
    // iOS UIImpactFeedbackGenerator(.light) and Android's HapticFeedback.
    HapticFeedback.lightImpact();
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
    _amplitudeSub = _recorder.onAmplitudeChanged(const Duration(milliseconds: 200)).listen((amp) {
      if (!mounted) return;
      // `current` is dBFS - silent ≈ -60, max ≈ 0. Clamp to a friendly range.
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
      // Crossed the lock threshold - confirm with a light tap. Reachable
      // exactly once per recording (early-return at the top blocks re-entry).
      HapticFeedback.lightImpact();
      setState(() {
        _isLockedRecord = true;
        _willCancelRecord = false;
        _recordDragOffset = 0.0;
        _recordDragOffsetY = 0.0;
      });
      return;
    }

    final willCancel = -clampedX >= _cancelDragThreshold;
    if (clampedX != _recordDragOffset || clampedY != _recordDragOffsetY || willCancel != _willCancelRecord) {
      // Subtle click each time the user crosses (or uncrosses) the cancel
      // threshold - gives "release now to cancel" a tactile boundary.
      if (willCancel != _willCancelRecord) {
        HapticFeedback.selectionClick();
      }
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
    HapticFeedback.lightImpact();
    setState(() => _isLockedRecord = false);
    await _stopRecording();
  }

  /// Locked-mode tap: discard the recording.
  Future<void> _onLockedCancel() async {
    HapticFeedback.selectionClick();
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
      _micButtonKey.currentState?.showMessage('Recording too short');
      return;
    }
    // Snapshot BEFORE appending the new audio message — if every question
    // was already answered, the user is editing from the preview and we
    // should reopen it instead of dropping them into the stray-Send-button
    // state.
    final wasComplete = bloc.state.allQuestionsAnswered;
    bloc.add(AudioRecordingStopped(path));
    if (wasComplete) {
      bloc.add(const ReviewRequested());
    }
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
    HapticFeedback.selectionClick();
    // Permission check shart emas:
    //  • iOS 14+ - PHPickerViewController (out-of-process, foydalanuvchi tanlagan
    //    rasm faqat sandbox'ga uzatiladi, butun gallery'ga kirish yo'q).
    //  • Android 13+ - system Photo Picker (PickVisualMedia), permission yo'q.
    //  • Android <13 - image_picker SAF ga fallback qiladi, u ham permission
    //    talab qilmaydi.
    // requestFullMetadata: false - iOS'da NSPhotoLibrary metadata so'rovini
    // bostiradi (location, asset id), bizga rasmning o'zi yetarli.
    final picked = await _picker.pickMultiImage(imageQuality: 85, maxWidth: 1920, requestFullMetadata: false);
    if (picked.isEmpty || !mounted) return;
    final files = picked.take(remaining).map((x) => File(x.path)).toList(growable: false);
    final bloc = context.read<OrderCreateBloc>();
    final wasComplete = bloc.state.allQuestionsAnswered;
    bloc.add(PhotosAdded(files));
    // Post-review edit ("Add another photo" from the preview) - bounce the
    // preview back open so the user reviews the new gallery, not a Send button.
    if (wasComplete) {
      bloc.add(const ReviewRequested());
    }
    _scrollToBottom();
  }

  // ---------- permission helpers ----------

  /// Mic permission with MIUI/HyperOS fallback. `record.hasPermission()` alone
  /// sometimes reports `false` on MIUI even when the OS would grant it, so we
  /// also request via [permission_handler] and direct the user to settings on
  /// permanent denial.
  Future<bool> _ensureMicPermission() async {
    if (await _recorder.hasPermission()) return true;
    var status = await Permission.microphone.status;
    if (status.isDenied || status.isRestricted) {
      status = await Permission.microphone.request();
    }
    if (status.isGranted || status.isLimited) {
      return await _recorder.hasPermission();
    }
    if (!mounted) return false;
    if (status.isPermanentlyDenied) {
      _showOpenSettingsDialog(
        title: 'Microphone access',
        message: 'Enable microphone permission in Settings to record voice messages.',
      );
    } else {
      AppSnackBar.showError(context, 'Microphone permission denied');
    }
    return false;
  }

  void _showOpenSettingsDialog({required String title, required String message}) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              openAppSettings();
            },
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
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

  /// Send button - commits whatever is in the input field to bloc state.
  /// Price step → fires [PriceChanged]; otherwise → [TextMessageAppended],
  /// which adds a new chat-style message to [OrderCreateState.messages].
  /// The bubble only appears after this commit, never on each keystroke.
  void _onSendDraft() {
    final state = context.read<OrderCreateBloc>().state;
    final raw = _inputController.text.trim();
    if (raw.isEmpty) return;
    HapticFeedback.selectionClick();
    final bloc = context.read<OrderCreateBloc>();
    if (_isPriceStep(state)) {
      bloc.add(PriceChanged(raw));
      // Price is the last question - open the review sheet immediately so
      // the user doesn't need a second tap on a separate Yuborish button.
      bloc.add(const ReviewRequested());
      FocusScope.of(context).unfocus();
    } else {
      bloc.add(TextMessageAppended(raw));
      // If every question was already answered before this send, the user is
      // editing from the preview - reopen the preview instead of leaving them
      // staring at a stray Send button.
      if (state.allQuestionsAnswered) {
        bloc.add(const ReviewRequested());
        FocusScope.of(context).unfocus();
      }
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
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    bloc.add(const ReviewRequested());
  }

  void _onConfirmSubmit() {
    HapticFeedback.lightImpact();
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

  // ---------- review sheet edit shortcuts ----------

  /// Preview'ni yopadi va darhol rasm picker'ni ochadi - vizual signal:
  /// foydalanuvchi yangi rasm tanlash kerakligini ko'radi.
  void _onAddAnotherPhoto() {
    context.read<OrderCreateBloc>().add(const ReviewDismissed());
    _pickPhotos();
  }

  /// Preview'ni yopadi va inputni focusga oladi - foydalanuvchi yangi text yoki
  /// audio message qo'shadi (eskilari saqlanib qoladi, chunki har bir send
  /// yangi `OrderMessage` append qiladi). Eski matnni pre-fill qilmaymiz, aks
  /// holda yuborilsa eski text takrorlanardi.
  void _onAddMoreDetails() {
    context.read<OrderCreateBloc>().add(const ReviewDismissed());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _inputFocusNode.requestFocus();
    });
  }

  /// Preview'ni yopadi, narxni bloc'da tozalaydi (price savoli yana faollashadi
  /// va bottom input price mode'ga o'tadi), eski narxni input'ga pre-fill qiladi
  /// va keyboardni ochadi. Foydalanuvchi xohlasa eski qiymatni qoldirib qayta
  /// yuboradi, xohlasa o'zgartiradi.
  void _onChangePrice() {
    final bloc = context.read<OrderCreateBloc>();
    final oldPrice = bloc.state.price;
    bloc.add(const ReviewDismissed());
    bloc.add(const PriceChanged(''));
    _inputController.text = oldPrice;
    _inputController.selection = TextSelection.collapsed(offset: _inputController.text.length);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _inputFocusNode.requestFocus();
    });
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
        if (state.status == OrderCreateStatus.failure && state.errorMessage.isNotEmpty) {
          AppSnackBar.showError(context, state.errorMessage);
        }
        // When the flow advances into the price step, drop any leftover
        // draft text so the digits-only keyboard starts on a clean slate.
        if (_isPriceStep(state) && _inputController.text.isNotEmpty) {
          _inputController.clear();
        }
        // Step changed (listenWhen guarantees this). The TextField rebuilds
        // with a new keyboardType, but Flutter does NOT push keyboardType
        // changes to an already-attached InputConnection - so the previous
        // step's keyboard stays. Cycle focus to force the platform to
        // rebuild the keyboard with the new type (e.g. number pad for the
        // price step).
        if (_inputFocusNode.hasFocus) {
          _inputFocusNode.unfocus();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _inputFocusNode.requestFocus();
          });
        }
      },
      builder: (context, state) {
        return KeyboardDismisser(
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Column(
              children: [
                SizedBox(height: context.padding.top),
                _Header(address: state.address, onBack: () => context.pop()),
                Expanded(
                  child: _ChatTranscript(
                    state: state,
                    scrollController: _scrollController,
                    onPhotoRemoved: (i) => context.read<OrderCreateBloc>().add(PhotoRemoved(i)),
                    onMessageRemoved: (position) => context.read<OrderCreateBloc>().add(MessageRemoved(position)),
                    onSubmit: _onReviewRequested,
                    onAddPhotos: _pickPhotos,
                    onDismissReview: () => context.read<OrderCreateBloc>().add(const ReviewDismissed()),
                    onConfirmSubmit: _onConfirmSubmit,
                    onAddPhoto: _onAddAnotherPhoto,
                    onAddDetails: _onAddMoreDetails,
                    onChangePrice: _onChangePrice,
                  ),
                ),
                if (!state.showReview)
                  _BottomInputBar(
                    controller: _inputController,
                    focusNode: _inputFocusNode,
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
                    micButtonKey: _micButtonKey,
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
          IconButton(onPressed: onBack, icon: SvgPicture.asset(AppIcons.back, width: 18, height: 18)),
          Expanded(
            child: Center(child: AddressChip(address: address)),
          ),
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
    required this.onMessageRemoved,
    required this.onSubmit,
    required this.onAddPhotos,
    required this.onDismissReview,
    required this.onConfirmSubmit,
    required this.onAddPhoto,
    required this.onAddDetails,
    required this.onChangePrice,
  });

  final OrderCreateState state;
  final ScrollController scrollController;
  final ValueChanged<int> onPhotoRemoved;
  final ValueChanged<int> onMessageRemoved;
  final VoidCallback onSubmit;
  final VoidCallback onAddPhotos;
  final VoidCallback onDismissReview;
  final VoidCallback onConfirmSubmit;
  final VoidCallback onAddPhoto;
  final VoidCallback onAddDetails;
  final VoidCallback onChangePrice;

  @override
  Widget build(BuildContext context) {
    if (state.questionsStatus == QuestionsLoadStatus.loading && state.questions.isEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    final children = <Widget>[
      const SizedBox(height: 4),
      Text(
        'What is your problem?',
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: -0.3),
      ),
      const SizedBox(height: 16),
    ];

    // 1) Avval - javob berilgan savollar, asl tartibida (Q1 oldin, Q2 keyin...)
    // 2) Keyin - hozirgi javob berilmagan savol (eng tepa unanswered) eng
    //    pastda, prompt sifatida. Foydalanuvchi tartibsiz javob bersa
    //    (masalan: rasmni avval yuborsa), javob berilmagan savol baribir
    //    chat oxirida turadi va e'tibor jalb qiladi.
    for (var i = 0; i < state.questions.length; i++) {
      final q = state.questions[i];
      if (!state.hasAnswerFor(q.type)) continue;
      children.add(_BotBubble(text: q.body));
      children.add(const SizedBox(height: 12));
      children.add(
        _UserAnswerBubble(
          question: q,
          state: state,
          onPhotoRemoved: onPhotoRemoved,
          onMessageRemoved: onMessageRemoved,
          onAddPhotos: onAddPhotos,
        ),
      );
      children.add(const SizedBox(height: 12));
    }
    final activeIdx = state.currentQuestionIndex;
    if (activeIdx < state.questions.length) {
      children.add(_BotBubble(text: state.questions[activeIdx].body));
      children.add(const SizedBox(height: 12));
    }

    if (state.showReview) {
      children.add(
        OrderReviewSheet(
          state: state,
          onDismiss: onDismissReview,
          onConfirm: onConfirmSubmit,
          onAddPhoto: onAddPhoto,
          onAddDetails: onAddDetails,
          onChangePrice: onChangePrice,
        ),
      );
    } else if (state.allQuestionsAnswered && state.canSubmit) {
      children.add(const SizedBox(height: 8));
      children.add(_SubmitButton(loading: state.status == OrderCreateStatus.submitting, onPressed: onSubmit));
      children.add(const SizedBox(height: 8));
    }

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(16, 8, 16, context.padding.bottom + 8),
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
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            style: const TextStyle(color: Colors.black, fontSize: 14, height: 1.4, letterSpacing: -0.3),
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
    required this.onMessageRemoved,
    required this.onAddPhotos,
  });

  final QuestionTemplate question;
  final OrderCreateState state;
  final ValueChanged<int> onPhotoRemoved;
  final ValueChanged<int> onMessageRemoved;
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
        if (state.messages.isEmpty) return null;
        // One bubble per OrderMessage, rendered in chronological order.
        // Mixed text + audio interleaved exactly as the user authored them.
        final pieces = <Widget>[];
        for (var i = 0; i < state.messages.length; i++) {
          final m = state.messages[i];
          if (pieces.isNotEmpty) pieces.add(const SizedBox(height: 8));
          pieces.add(switch (m) {
            OrderTextMessage() => _TextReply(text: m.text),
            OrderAudioMessage() => _AudioReply(
              path: m.path,
              duration: m.duration,
              peaks: m.peaks,
              onClear: () => onMessageRemoved(m.position),
            ),
          });
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.end, children: pieces);
      case QuestionType.photos:
        return _PhotosReply(photos: state.photos, maxCount: 5, onRemove: onPhotoRemoved, onAdd: onAddPhotos);
      case QuestionType.price:
        return _PriceReply(price: state.price);
      case QuestionType.unknown:
        return null;
    }
  }
}

/// Playable audio bubble - taps the circle to play/pause via `just_audio`.
/// The waveform fills in as playback progresses (Telegram-style).
class _AudioReply extends StatefulWidget {
  const _AudioReply({required this.path, required this.duration, required this.peaks, required this.onClear});

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
    final displayedTime = _isPlaying || _position > Duration.zero ? _position : widget.duration;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFFEFF3F6), borderRadius: BorderRadius.circular(24)),
        // mainAxisSize.max + Expanded waveform = bubble always spans its full
        // maxWidth allowance, so even a one-second clip renders a generous,
        // Telegram-style waveform instead of a stub.
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            GestureDetector(
              onTap: _togglePlay,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColor.kPrimaryColor, shape: BoxShape.circle),
                child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 28,
                child: _Waveform(peaks: widget.peaks, progress: _progress),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _format(displayedTime),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7073),
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: widget.onClear,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: SvgPicture.asset(AppIcons.x, width: 14, height: 14),
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

  static const int barCount = 40;

  // Fallback shape when no recording-time amplitudes are available
  // (e.g., audio coming from another client without `voice_peaks`).
  static const List<double> _fallback = [
    0.3,
    0.6,
    0.9,
    0.5,
    0.8,
    0.4,
    0.7,
    1.0,
    0.5,
    0.8,
    0.3,
    0.6,
    0.9,
    0.5,
    0.7,
    0.4,
    0.8,
    0.6,
    0.5,
    1.0,
    0.4,
    0.7,
    0.3,
    0.6,
    0.9,
    0.5,
    0.8,
    0.4,
    0.7,
    0.6,
  ];

  /// Returns exactly [target] samples. Short sources (e.g., a 1-second
  /// clip with only a handful of amplitude reads) are linearly interpolated
  /// — Telegram-style — so the bubble never looks half-empty. Long sources
  /// are bucket-averaged.
  List<double> _resample(List<double> source, int target) {
    if (source.isEmpty) {
      return List<double>.generate(target, (i) => _fallback[i % _fallback.length]);
    }
    if (source.length == target) return source;
    if (source.length < target) {
      final out = <double>[];
      for (var i = 0; i < target; i++) {
        if (target == 1) {
          out.add(source[0]);
          continue;
        }
        final pos = i * (source.length - 1) / (target - 1);
        final lo = pos.floor();
        final hi = pos.ceil().clamp(0, source.length - 1);
        if (lo == hi) {
          out.add(source[lo]);
        } else {
          final t = pos - lo;
          out.add(source[lo] * (1 - t) + source[hi] * t);
        }
      }
      return out;
    }
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
    final bars = _resample(peaks, barCount);
    final activePaint = AppColor.kPrimaryColor;
    final inactivePaint = AppColor.kPrimaryColor.withValues(alpha: 0.35);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight.isFinite ? constraints.maxHeight : 24.0;
        final minH = (maxH * 0.18).clamp(3.0, 5.0);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(barCount, (i) {
            final active = (i / barCount) <= progress;
            final h = (bars[i] * maxH).clamp(minH, maxH);
            return Container(
              width: 2.5,
              height: h,
              decoration: BoxDecoration(
                color: active ? activePaint : inactivePaint,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

class _TextReply extends StatelessWidget {
  const _TextReply({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
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
        child: Text(text, style: const TextStyle(color: Colors.black, fontSize: 14, height: 1.35, letterSpacing: -0.3)),
      ),
    );
  }
}

class _PhotosReply extends StatelessWidget {
  const _PhotosReply({required this.photos, required this.maxCount, required this.onRemove, required this.onAdd});

  final List<File> photos;
  final int maxCount;
  final ValueChanged<int> onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFEFF3F6), borderRadius: BorderRadius.circular(18)),
        child: PhotoGrid(photos: photos, maxCount: maxCount, onAdd: onAdd, onRemove: onRemove),
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
      decoration: BoxDecoration(color: const Color(0xFFEFF3F6), borderRadius: BorderRadius.circular(50)),
      child: Text(
        _formatted,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black, letterSpacing: -0.3),
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text('Send', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _BottomInputBar extends StatelessWidget {
  const _BottomInputBar({
    required this.controller,
    required this.focusNode,
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
    required this.micButtonKey,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
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
  final GlobalKey<_MicHoldHintButtonState> micButtonKey;

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
              right: 16,
              bottom: 78 + (-dragOffsetY).clamp(0.0, 120.0),
              child: _LockHintBadge(active: -dragOffsetY >= 60.0),
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
          Expanded(child: _RecordingInfoPill(elapsed: recordingElapsed, willCancel: false)),
          const SizedBox(width: 8),
          // Mic button bilan bir xil layout: 44x56 box, bottomCenter align,
          // active holatda 1.55x scale - lock paytida ham recording faol,
          // shuning uchun send button mic'dek katta bo'lib qoladi.
          SizedBox(
            width: 44,
            height: 56,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedScale(
                scale: 1.55,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: _MicGlow(
                  color: AppColor.kPrimaryColor,
                  active: true,
                  child: _SquareIconButton(
                    onPressed: onLockedSend,
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    background: AppColor.kPrimaryColor,
                    iconColor: Colors.white,
                  ),
                ),
              ),
            ),
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
                      icon: SvgPicture.asset(AppIcons.paperclip, width: 20, height: 20),
                      background: const Color(0xFFEFF3F6),
                      iconColor: AppColor.kPrimaryColor,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
        ),
        Expanded(
          child: isRecording
              ? _RecordingInfoPill(elapsed: recordingElapsed, willCancel: willCancel)
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: const Color(0xFFEFF3F6), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // $ har doim ko'rinadi - focus va matnga bog'liq emas.
                      if (isPriceStep)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Text(
                            '\$',
                            style: TextStyle(
                              fontSize: 14,
                              letterSpacing: -0.3,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          keyboardType: isPriceStep ? TextInputType.number : TextInputType.multiline,
                          textInputAction: isPriceStep ? TextInputAction.done : TextInputAction.newline,
                          inputFormatters: isPriceStep
                              ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
                              : null,
                          onSubmitted: (_) => onSend(),
                          maxLines: isPriceStep ? 1 : 4,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: isPriceStep ? 'Enter price' : 'Text or voice message',
                            border: InputBorder.none,
                            hintStyle: const TextStyle(color: Color(0xFFC5CACD)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 14, letterSpacing: -0.3),
                        ),
                      ),
                    ],
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
                  : _MicHoldHintButton(
                      key: micButtonKey,
                      isRecording: isRecording,
                      willCancel: willCancel,
                      dragOffset: dragOffset,
                      onLongPressStart: onMicLongPressStart,
                      onLongPressMoveUpdate: onMicLongPressMoveUpdate,
                      onLongPressEnd: onMicLongPressEnd,
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
  const _SendMicSlot({super.key, required this.onTap, required this.icon, required this.background});

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
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: Icon(icon, color: Colors.white, size: 20)),
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
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Color(0x29000000), blurRadius: 10, offset: Offset(0, 2))],
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
        width: 44,
        height: 44,
        decoration: const BoxDecoration(color: Color(0xFFEFF3F6), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: const Icon(Icons.close_rounded, color: Colors.red, size: 20),
      ),
    );
  }
}

class _RecordingInfoPill extends StatefulWidget {
  const _RecordingInfoPill({required this.elapsed, required this.willCancel});

  final Duration elapsed;
  final bool willCancel;

  @override
  State<_RecordingInfoPill> createState() => _RecordingInfoPillState();
}

class _RecordingInfoPillState extends State<_RecordingInfoPill> with SingleTickerProviderStateMixin {
  // Doimiy 1.2s sikl - qizil nuqta pulsatsiyasi + halqali ripple shu controllerdan.
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String get _label {
    final mm = widget.elapsed.inMinutes.toString().padLeft(2, '0');
    final ss = (widget.elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFEFF3F6), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          _PulsingRecordingDot(controller: _pulseController),
          const SizedBox(width: 12),
          // Live equalizer - to'liq Expanded'ni egallaydi, oxirgi (eng yangi)
          // amplituda o'ng tomonda, duration matniga yondashib chiqadi.
          // WillCancel paytida barlar qizilga aylanadi (cancel feedback).
          Expanded(child: _LiveAmplitudeBars(willCancel: widget.willCancel)),
          const SizedBox(width: 12),
          Text(
            _label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: -0.3,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Qizil nuqta + ikkita siljigan fazadagi halqalar (Telegram-style ripple).
/// Halqalar markazdan tashqariga tarqaladi va so'nadi - uzluksiz ko'rinish uchun
/// ikki halqa 0.5 fazaga siljitilgan.
class _PulsingRecordingDot extends StatelessWidget {
  const _PulsingRecordingDot({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final t = controller.value;
          // Markaziy nuqta nafas oladi: 10 ↔ 12 px, opacity bilan birga.
          final breath = (1 - (2 * t - 1).abs()); // 0..1..0 uchburchak
          final dotSize = 10 + 2 * breath;
          return Stack(
            alignment: Alignment.center,
            children: [
              _halo(t),
              _halo((t + 0.5) % 1.0),
              Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.85 + 0.15 * breath),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _halo(double t) {
    final size = 10 + 12 * t;
    final opacity = (0.35 * (1 - t)).clamp(0.0, 0.35);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Real vaqtli amplituda barlari - `state.currentRecordingPeaks` ro'yxatining
/// oxirgi N ta qiymatini ko'rsatadi. Mikrofonga gapirilganda barlar "raqsga
/// tushadi". Cancel rejimida (drag left) barlar qizilga aylanadi.
class _LiveAmplitudeBars extends StatelessWidget {
  const _LiveAmplitudeBars({this.willCancel = false});

  final bool willCancel;

  static const int _barCount = 26;

  @override
  Widget build(BuildContext context) {
    final color = willCancel ? Colors.red : AppColor.kPrimaryColor;
    return BlocBuilder<OrderCreateBloc, OrderCreateState>(
      buildWhen: (p, c) =>
          p.currentRecordingPeaks.length != c.currentRecordingPeaks.length ||
          (p.currentRecordingPeaks.isNotEmpty &&
              c.currentRecordingPeaks.isNotEmpty &&
              p.currentRecordingPeaks.last != c.currentRecordingPeaks.last),
      builder: (context, state) {
        final peaks = state.currentRecordingPeaks;
        final recent = peaks.length > _barCount ? peaks.sublist(peaks.length - _barCount) : peaks;
        // Ro'yxat to'lmagan paytda chap tomon bo'sh (h=2) qoladi, yangi qiymat
        // o'ngdan kelib qo'shiladi - Telegramdagi "scrolling waveform" hissi.
        final pad = _barCount - recent.length;
        return SizedBox(
          height: 22,
          // spaceBetween - barlar Expanded'ning butun kengligi bo'ylab teng
          // taqsimlanadi (eng chap bar chap chetida, eng o'ng bar duration
          // matniga yondashadi). Padding olib tashlandi - gaplar avtomatik
          // hisoblanadi.
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(_barCount, (i) {
              final value = i < pad ? 0.0 : recent[i - pad];
              final h = (value * 18).clamp(2.0, 18.0);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 2,
                height: h,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              );
            }),
          ),
        );
      },
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
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        child: SizedBox(width: 44, height: 44, child: Center(child: icon)),
      ),
    );
  }
}

/// Telegram-style amplitude-reaktiv glow: bolaning atrofida 3 ta konsentrik
/// halqa, har biri har xil radiusda (asimmetrik masofa), har biri o'z fazasi
/// bilan nafas oladi (sinus). Mikrofon amplitudasiga qarab halqalar bir oz
/// kengayadi va to'qroq bo'ladi, lekin amplituda 0 bo'lganda ham g'oyib
/// bo'lmaydi - baseline opacity saqlanadi.
class _MicGlow extends StatefulWidget {
  const _MicGlow({required this.color, required this.active, required this.child});

  final Color color;
  final bool active;
  final Widget child;

  @override
  State<_MicGlow> createState() => _MicGlowState();
}

class _MicGlowState extends State<_MicGlow> with TickerProviderStateMixin {
  // Har bir halqa o'z controlleriga ega - turli davriyliklar (1.7s/2.3s/2.9s)
  // tufayli halqalar bir-biri bilan sinxron emas, asinxron drift qiladi.
  late final AnimationController _c1;
  late final AnimationController _c2;
  late final AnimationController _c3;

  @override
  void initState() {
    super.initState();
    _c1 = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));
    _c2 = AnimationController(vsync: this, duration: const Duration(milliseconds: 2300));
    _c3 = AnimationController(vsync: this, duration: const Duration(milliseconds: 2900));
    if (widget.active) _startAll();
  }

  void _startAll() {
    for (final c in [_c1, _c2, _c3]) {
      if (!c.isAnimating) c.repeat();
    }
  }

  void _stopAll() {
    for (final c in [_c1, _c2, _c3]) {
      if (c.isAnimating) c.stop();
    }
  }

  @override
  void didUpdateWidget(covariant _MicGlow old) {
    super.didUpdateWidget(old);
    if (widget.active) {
      _startAll();
    } else {
      _stopAll();
    }
  }

  @override
  void dispose() {
    _c1.dispose();
    _c2.dispose();
    _c3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;

    return BlocBuilder<OrderCreateBloc, OrderCreateState>(
      buildWhen: (p, c) =>
          (p.currentRecordingPeaks.isEmpty && c.currentRecordingPeaks.isNotEmpty) ||
          (p.currentRecordingPeaks.isNotEmpty &&
              c.currentRecordingPeaks.isNotEmpty &&
              p.currentRecordingPeaks.last != c.currentRecordingPeaks.last),
      builder: (context, state) {
        final raw = state.currentRecordingPeaks.isNotEmpty ? state.currentRecordingPeaks.last : 0.0;
        // 200ms diskret samplelar orasini yumshatamiz.
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: raw),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          builder: (context, amp, child) {
            return AnimatedBuilder(
              animation: Listenable.merge([_c1, _c2, _c3]),
              builder: (context, _) {
                return SizedBox(
                  width: 44,
                  height: 44,
                  child: OverflowBox(
                    maxWidth: 140,
                    maxHeight: 140,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Har bir haloga ozgina oval va aylanish - sezilarli
                        // morfing, lekin asosan aylana ko'rinishida.
                        _halo(
                          baseRadius: 50,
                          breathRange: 8,
                          ampGain: 14,
                          amp: amp,
                          phase: _c1.value,
                          baseAlpha: 0.18,
                          ovalIntensity: 0.09,
                          rotationSpeed: 0.35,
                          rotationDir: 1,
                        ),
                        _halo(
                          baseRadius: 38,
                          breathRange: 6,
                          ampGain: 10,
                          amp: amp,
                          phase: _c2.value,
                          baseAlpha: 0.30,
                          ovalIntensity: 0.07,
                          rotationSpeed: 0.5,
                          rotationDir: -1,
                        ),
                        _halo(
                          baseRadius: 30,
                          breathRange: 4,
                          ampGain: 7,
                          amp: amp,
                          phase: _c3.value,
                          baseAlpha: 0.42,
                          ovalIntensity: 0.05,
                          rotationSpeed: 0.7,
                          rotationDir: 1,
                        ),
                        child!,
                      ],
                    ),
                  ),
                );
              },
              child: child,
            );
          },
          child: widget.child,
        );
      },
    );
  }

  /// Yumshoq halo - radial gradient + noyaridiy scaleX/scaleY (oval) +
  /// sekin rotation. Har bir halqa "tomchi" kabi suzib, asta-sekin
  /// shaklini o'zgartiradi.
  Widget _halo({
    required double baseRadius,
    required double breathRange,
    required double ampGain,
    required double amp,
    required double phase, // 0..1 - o'z controllerdan
    required double baseAlpha,
    required double ovalIntensity, // oval qancha kuchli (0..0.3)
    required double rotationSpeed, // aylanish tezligi (1.0 = bir aylana per cycle)
    required double rotationDir, // ±1 - aylanish yo'nalishi
  }) {
    // Yumshoq nafas olish: 0..1..0 sinusoid.
    final breath = (1 - math.cos(phase * 2 * math.pi)) / 2;
    final radius = baseRadius + breathRange * breath + ampGain * amp;
    final alphaPulse = 0.75 + 0.25 * breath;
    final alpha = (baseAlpha * alphaPulse + 0.22 * amp).clamp(0.0, 0.7);

    // Oval shakl - scaleX va scaleY 90° fazada siljitilgan, shuning uchun
    // X kengaygan paytda Y torayadi (va aksincha). Bu "morphing droplet"
    // ko'rinishini beradi, hech qachon mukammal aylana bo'lib qolmaydi.
    final scaleX = 1.0 + ovalIntensity * math.sin(phase * 2 * math.pi);
    final scaleY = 1.0 + ovalIntensity * math.sin(phase * 2 * math.pi + math.pi / 2);
    // Sekin rotation - oval yo'nalishi siljiydi, shakl statik tuyulmaydi.
    final rotation = phase * 2 * math.pi * rotationSpeed * rotationDir;

    return IgnorePointer(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..rotateZ(rotation)
          ..scaleByDouble(scaleX, scaleY, 1.0, 1.0),
        child: Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.color.withValues(alpha: alpha),
                widget.color.withValues(alpha: 0),
              ],
              stops: const [0.35, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

// Mic button + Telegram-style "Hold to record" tooltip. Visible icon and the
// surrounding row spacing stay exactly the same; only the upward portion of
// the hit-area is enlarged (44×56, bottom-aligned) so casual taps near the
// keyboard don't miss the button. A single tap shows the bubble; a long
// press hides any bubble and triggers recording as before.
class _MicHoldHintButton extends StatefulWidget {
  const _MicHoldHintButton({
    super.key,
    required this.isRecording,
    required this.willCancel,
    required this.dragOffset,
    required this.onLongPressStart,
    required this.onLongPressMoveUpdate,
    required this.onLongPressEnd,
  });

  final bool isRecording;
  final bool willCancel;
  final double dragOffset;
  final GestureLongPressStartCallback onLongPressStart;
  final GestureLongPressMoveUpdateCallback onLongPressMoveUpdate;
  final GestureLongPressEndCallback onLongPressEnd;

  @override
  State<_MicHoldHintButton> createState() => _MicHoldHintButtonState();
}

class _MicHoldHintButtonState extends State<_MicHoldHintButton> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _hintEntry;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideHint();
    super.dispose();
  }

  // Public - _stopRecording calls this to surface "Recording too short" in
  // the same tooltip design instead of a bottom snackbar.
  void showMessage(String message) {
    _showHint(message);
  }

  void _showHint([String message = 'Hold the mic to record']) {
    _hideHint();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    // Lightest possible feedback so the user feels the tap even when their
    // finger is just resting near the icon.
    HapticFeedback.selectionClick();
    final entry = OverlayEntry(
      builder: (ctx) => _MicHoldTooltip(layerLink: _layerLink, message: message, onDismissRequested: _hideHint),
    );
    overlay.insert(entry);
    _hintEntry = entry;
    _hideTimer = Timer(const Duration(milliseconds: 2400), _hideHint);
  }

  void _hideHint() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _hintEntry?.remove();
    _hintEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isRecording && widget.willCancel ? Colors.red : AppColor.kPrimaryColor;
    return CompositedTransformTarget(
      link: _layerLink,
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        // GestureDetector hard-codes long-press to kLongPressTimeout (500ms),
        // which feels sluggish for hold-to-record. Drop it to 220ms so the
        // mic activates almost as soon as the user commits to the hold.
        gestures: <Type, GestureRecognizerFactory>{
          TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            () => TapGestureRecognizer(),
            (instance) {
              instance.onTap = _showHint;
            },
          ),
          LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(duration: const Duration(milliseconds: 220)),
            (instance) {
              instance
                ..onLongPressStart = (d) {
                  _hideHint();
                  widget.onLongPressStart(d);
                }
                ..onLongPressMoveUpdate = widget.onLongPressMoveUpdate
                ..onLongPressEnd = widget.onLongPressEnd;
            },
          ),
        },
        // Layout footprint stays 44 wide (matches the original send button
        // width - no horizontal spacing change), but the box is 56 tall with
        // the visible icon pinned to the bottom. The extra 12px above the
        // icon is dead-tap territory the user can still hit.
        child: SizedBox(
          width: 44,
          height: 56,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Transform.translate(
              offset: widget.isRecording ? Offset(widget.dragOffset, 0) : Offset.zero,
              // Telegram-style enlargement: while recording the mic balloons
              // to ~1.55x its rest size — visual only, layout footprint stays
              // 44px so neighbouring widgets don't reflow. Centered scaling
              // means the visible disc overflows up & out symmetrically, which
              // is exactly how Telegram's recording button grows.
              child: AnimatedScale(
                scale: widget.isRecording ? 1.55 : 1.0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: _MicGlow(
                  active: widget.isRecording,
                  color: color,
                  child: _SendMicSlot(onTap: null, icon: Icons.mic_none_rounded, background: color),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Telegram-style speech bubble overlay positioned above the mic button.
// Uses CompositedTransformFollower so it tracks the button if layout shifts
// (keyboard appearing, etc.). Self-fades in then waits for the parent's
// auto-hide timer or a tap outside.
class _MicHoldTooltip extends StatefulWidget {
  const _MicHoldTooltip({required this.layerLink, required this.message, required this.onDismissRequested});

  final LayerLink layerLink;
  final String message;
  final VoidCallback onDismissRequested;

  @override
  State<_MicHoldTooltip> createState() => _MicHoldTooltipState();
}

class _MicHoldTooltipState extends State<_MicHoldTooltip> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 180))..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxWidth = math.min(screenWidth - 32.0, 320.0);
    // Mic hit-area is 44×56 with the visible icon pinned to the bottom - so
    // the LayerLink's top edge sits 12px ABOVE the visible icon. We shift the
    // bubble down by 8px so the arrow tip lands ~4px above the icon, matching
    // Telegram's tight visual gap.
    const double rightInset = 0.0;
    const double arrowFromRight = 14.0;
    const double verticalOffset = 8.0;
    // Overlay is pointer-transparent except for the bubble itself, so the
    // user can keep interacting with the chat behind it. Tapping the bubble
    // dismisses immediately; otherwise it auto-fades after the parent timer.
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: true,
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: widget.layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.topRight,
              followerAnchor: Alignment.bottomRight,
              offset: const Offset(-rightInset, verticalOffset),
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  alignment: Alignment.bottomRight,
                  scale: _scale,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    // Material wrapper kills the yellow debug underlines that
                    // appear on Text without a Material ancestor (the overlay
                    // is hosted outside the Scaffold's Material tree).
                    child: Material(
                      type: MaterialType.transparency,
                      child: IgnorePointer(
                        ignoring: false,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.onDismissRequested,
                          child: CustomPaint(
                            painter: _TooltipBubblePainter(
                              color: const Color(0xF20F0F10),
                              arrowFromRight: arrowFromRight,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 11, 14, 19),
                              child: Text(
                                widget.message,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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

class _TooltipBubblePainter extends CustomPainter {
  _TooltipBubblePainter({required this.color, required this.arrowFromRight});

  final Color color;
  final double arrowFromRight;

  static const double _radius = 14.0;
  static const double _arrowWidth = 14.0;
  static const double _arrowHeight = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final bodyRect = Rect.fromLTWH(0, 0, size.width, size.height - _arrowHeight);
    final bodyPath = Path()..addRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(_radius)));

    // Downward-pointing triangle anchored on the body's bottom edge.
    final tipCenterX = (size.width - arrowFromRight).clamp(
      _radius + _arrowWidth / 2,
      size.width - _radius - _arrowWidth / 2,
    );
    final arrowPath = Path()
      ..moveTo(tipCenterX - _arrowWidth / 2, bodyRect.bottom)
      ..lineTo(tipCenterX, bodyRect.bottom + _arrowHeight)
      ..lineTo(tipCenterX + _arrowWidth / 2, bodyRect.bottom)
      ..close();

    final combined = Path.combine(PathOperation.union, bodyPath, arrowPath);

    // Soft shadow beneath the bubble.
    canvas.drawShadow(combined.shift(const Offset(0, 2)), Colors.black.withValues(alpha: 0.35), 8, false);
    canvas.drawPath(combined, paint);
  }

  @override
  bool shouldRepaint(covariant _TooltipBubblePainter old) => old.color != color || old.arrowFromRight != arrowFromRight;
}
