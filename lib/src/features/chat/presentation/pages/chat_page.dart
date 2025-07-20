import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hl_image_picker/hl_image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:taxi_app/src/core/widgets/app_button.dart';
import 'package:taxi_app/src/features/chat/data/model/question_model.dart';
import 'package:taxi_app/src/utils/local.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';
import 'package:taxi_app/src/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:taxi_app/src/features/chat/presentation/widgets/chat_input_widget.dart';
import 'package:voice_message_player/voice_message_player.dart';
import '../../../../routes/pages.dart';
import '../../data/model/report_model.dart';
import '../../model/chat_question_data.dart';
import '../models/chat_model.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with SingleTickerProviderStateMixin {
  bool _isRequestSent = false;

  final _controller = TextEditingController();
  final _recorder = Record();
  final _picker = HLImagePicker();
  final Map<int, String> _answers = {};
  final List<File> _selectedImages = [];
  String? _voiceFilePath;
  List<QuestionData> _questions = [];
  String? _acceptText;
  int _currentQuestionIndex = 0;
  bool _showAcceptUI = false;
  bool _isSubmitted = false;

  String? _submittedTextOrVoice;
  List<File> _submittedImages = [];
  String? _submittedPrice;

  bool isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;
  String? _recordedFilePath;

  final List<ChatMessage> _messages = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    context.read<ChatBloc>().add(
      FetchQuestionsEvent(onSuccess: () {}, onError: () {}),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _recorder.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    Directory dir;
    try {
      dir = await getApplicationDocumentsDirectory();
    } catch (_) {
      dir = Directory.systemTemp;
    }
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      encoder: AudioEncoder.aacLc,
      bitRate: 128000,
      samplingRate: 44100,
      path: path,
    );
    setState(() {
      isRecording = true;
      _recordedFilePath = path;
      _recordDuration = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordDuration++);
    });
  }

  Future<void> _stopRecordingAndAdd() async {
    if (!isRecording) return;
    final path = await _recorder.stop();
    _timer?.cancel();
    setState(() => isRecording = false);
    if (path != null) {
      if (_currentQuestionIndex == 0) {
        setState(() {
          _voiceFilePath = path;
          _messages.add(
            ChatMessage(
              type: MessageType.voice,
              voiceDuration: Duration(seconds: _recordDuration),
              audioPath: path,
              isMe: true,
            ),
          );
          _answers[_currentQuestionIndex] = 'Voice message';
          _processResponse();
        });
      } else {
        final f = File(path);
        if (await f.exists()) await f.delete();
        setState(() {
          _recordedFilePath = null;
          _recordDuration = 0;
          _messages.add(
            ChatMessage(
              type: MessageType.text,
              text: _currentQuestionIndex == 1
                  ? 'Iltimos, rasm yuklang!'
                  : 'Iltimos, narxni kiriting!',
              isMe: false,
            ),
          );
        });
      }
    }
    _scrollToBottom();
  }

  Future<void> _cancelRecording() async {
    if (!isRecording) return;
    await _recorder.stop();
    _timer?.cancel();
    if (_recordedFilePath != null) {
      final f = File(_recordedFilePath!);
      if (await f.exists()) await f.delete();
    }
    setState(() {
      isRecording = false;
      _recordedFilePath = null;
      _recordDuration = 0;
    });
    _scrollToBottom();
  }

  void _sendText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_currentQuestionIndex == 0 || _currentQuestionIndex == 2) {
      setState(() {
        _messages.add(
          ChatMessage(type: MessageType.text, text: text, isMe: true),
        );
        _answers[_currentQuestionIndex] = text;
        _controller.clear();
        if (_currentQuestionIndex == 2 && !isNumeric(text)) {
          _messages.add(
            ChatMessage(
              type: MessageType.text,
              text: 'Iltimos, faqat raqam kiriting!',
              isMe: false,
            ),
          );
        } else {
          _processResponse();
        }
      });
    } else {
      setState(() {
        _messages.add(
          ChatMessage(
            type: MessageType.text,
            text: 'Iltimos, rasm yuklang!',
            isMe: false,
          ),
        );
        _controller.clear();
      });
    }
    _scrollToBottom();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.openPicker(
      pickerOptions: HLPickerOptions(
        mediaType: MediaType.image,
        maxSelectedAssets: 6,
      ),
    );
    if (picked.isNotEmpty && _currentQuestionIndex == 1) {
      setState(() {
        _selectedImages.clear();
        _selectedImages.addAll(picked.map((e) => File(e.path)).toList());
        _messages.add(
          ChatMessage(
            type: MessageType.images,
            images: _selectedImages,
            isMe: true,
          ),
        );
        _answers[_currentQuestionIndex] = 'Images uploaded';
        _processResponse();
      });
    } else if (_currentQuestionIndex != 1) {
      setState(() {
        _messages.add(
          ChatMessage(
            type: MessageType.text,
            text: _currentQuestionIndex == 0
                ? 'Iltimos, avval matn yoki ovozli xabar yuboring!'
                : 'Iltimos, narxni kiriting!',
            isMe: false,
          ),
        );
      });
    }
    _scrollToBottom();
  }

  void _processResponse() {
    if (_currentQuestionIndex < 3 &&
        _currentQuestionIndex < _questions.length) {
      setState(() {
        _currentQuestionIndex++;
        if (_currentQuestionIndex < 3 &&
            _currentQuestionIndex < _questions.length) {
          _messages.add(
            ChatMessage(
              type: MessageType.text,
              text: _questions[_currentQuestionIndex].title,
              isMe: false,
            ),
          );
        } else if (_acceptText != null) {
          _submittedTextOrVoice = _voiceFilePath != null
              ? 'Ovozli xabar'
              : _answers[0];
          _submittedImages = List.from(_selectedImages);
          _submittedPrice = _answers[2];
          _messages.add(
            ChatMessage(
              voiceDuration: _voiceFilePath != null
                  ? Duration(seconds: _recordDuration)
                  : null,
              audioPath: _submittedTextOrVoice,
              type: MessageType.finish,
              text: _submittedTextOrVoice,
              isMe: false,
            ),
          );
          _showAcceptUI = true;
        }
      });
    }
    _scrollToBottom();
  }

  bool isNumeric(String str) {
    if (str == null) return false;
    return double.tryParse(str) != null;
  }

  void _onLongPress(BuildContext itemCtx, int idx) {
    final renderBox = itemCtx.findRenderObject() as RenderBox;
    final overlay =
        Overlay.of(context)!.context.findRenderObject() as RenderBox;
    final topLeft = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
    final size = renderBox.size;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const menuWidth = 200.0;
    const menuHeight = 180.0;
    const menuGap = 4.0;

    final showAbove = topLeft.dy + size.height + menuHeight > screenHeight;
    final menuLeft = (topLeft.dx + size.width - menuWidth).clamp(
      16.0,
      screenWidth - menuWidth - 16.0,
    );
    final menuTop = showAbove
        ? topLeft.dy - menuHeight - menuGap
        : topLeft.dy + size.height + menuGap;

    _animationController.forward();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.transparent,
      pageBuilder: (_, __, ___) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _animationController.reverse().then(
                  (_) => Navigator.of(context).pop(),
                );
              },
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(color: Colors.black26),
              ),
            ),
          ),
          Positioned(
            left: topLeft.dx,
            top: topLeft.dy,
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: size.width,
                child: _buildQuestionBubble(
                  _messages[idx],
                  idx,
                  highlight: true,
                ),
              ),
            ),
          ),
          Positioned(
            left: menuLeft,
            top: menuTop,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildPopupMenu(idx, showAbove: showAbove),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(int idx, {required bool showAbove}) {
    final msg = _messages[idx];
    final isMe = msg.isMe;

    BorderRadius radius;
    if (showAbove) {
      radius = BorderRadius.only(
        topLeft: const Radius.circular(16),
        topRight: const Radius.circular(16),
        bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
        bottomRight: isMe ? Radius.zero : const Radius.circular(16),
      );
    } else {
      radius = BorderRadius.only(
        topRight: isMe ? Radius.zero : const Radius.circular(16),
        topLeft: isMe ? const Radius.circular(16) : Radius.zero,
        bottomLeft: const Radius.circular(16),
        bottomRight: const Radius.circular(16),
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Platform.isIOS
                  ? const Color(0xFF2A2A2E).withOpacity(0.3)
                  : Theme.of(context).colorScheme.surface.withOpacity(0.9),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _actionTile(Icons.reply, 'Reply', () => _dismissAnd(() {})),
                    if (msg.type == MessageType.text)
                      _actionTile(
                        Icons.copy,
                        'Copy',
                        () => _dismissAnd(() {
                          Clipboard.setData(ClipboardData(text: msg.text!));
                        }),
                      ),
                    if (msg.type == MessageType.text && msg.isMe)
                      _actionTile(Icons.edit, 'Edit', () => _dismissAnd(() {})),
                    if (msg.type == MessageType.images) ...[
                      _actionTile(
                        Icons.remove_red_eye,
                        'View Images',
                        () => _dismissAnd(() {}),
                      ),
                      _actionTile(
                        Icons.download,
                        'Save Images',
                        () => _dismissAnd(() {}),
                      ),
                    ],
                    if (msg.type == MessageType.voice) ...[
                      _actionTile(
                        Icons.play_arrow,
                        'Play Voice',
                        () => _dismissAnd(() {}),
                      ),
                      _actionTile(
                        Icons.share,
                        'Share Voice',
                        () => _dismissAnd(() {}),
                      ),
                    ],
                    _actionTile(
                      Icons.delete,
                      'Delete',
                      () => _dismissAnd(() {
                        setState(() => _messages.removeAt(idx));
                      }),
                      textColor: Colors.redAccent,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _dismissAnd(VoidCallback action) {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
      action();
    });
  }

  ListTile _actionTile(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color textColor = Colors.black,
  }) {
    return ListTile(
      leading: Icon(icon, size: 20, color: textColor),
      title: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is ChatSuccess) {
          setState(() {
            final questions = state.questionTemplate.questions;
            _questions = questions
                .where((q) => q.key != 'accept_text')
                .toList();
            _acceptText = questions
                .firstWhere((q) => q.key == 'accept_text')
                .title;
            if (_questions.isNotEmpty &&
                _currentQuestionIndex < 3 &&
                _currentQuestionIndex < _questions.length) {
              _messages.add(
                ChatMessage(
                  type: MessageType.text,
                  text: _questions[_currentQuestionIndex].title,
                  isMe: false,
                ),
              );
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          title: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF2F5),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(AppIcons.location, width: 16, height: 16),
                const SizedBox(width: 8),
                Text(
                  currentAddress.length > 35
                      ? '${currentAddress.substring(0, 35)}…'
                      : currentAddress,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Sizda qanday muammo?',
                style: context.textS.headlineMedium!.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 25,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: _messages.length,
                itemBuilder: (ctx, i) {
                  final msg = _messages[i];
                  return Builder(
                    builder: (itemCtx) => GestureDetector(
                      onLongPress: () => _onLongPress(itemCtx, i),
                      child: _buildQuestionBubble(msg, i),
                    ),
                  );
                },
              ),
            ),
            if (!_showAcceptUI && !_isSubmitted)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ChatInputWidget(
                    controller: _controller,
                    onAttach: _pickImages,
                    onVoice: isRecording
                        ? _stopRecordingAndAdd
                        : _startRecording,
                    onCancel: _cancelRecording,
                    onSend: _sendText,
                    isRecording: isRecording,
                    recordDuration: _recordDuration,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionBubble(
    ChatMessage msg,
    int index, {
    bool highlight = false,
  }) {
    final bg = highlight
        ? Colors.yellow.shade100
        : (msg.isMe ? AppColor.kPrimary2Color : const Color(0xFFF0F2F5));
    final align = msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start;
    final radius = msg.isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          );

    Widget content;
    switch (msg.type) {
      case MessageType.text:
        content = Text(
          msg.text!,
          style: TextStyle(
            color: msg.isMe ? Colors.black87 : Colors.black54,
            fontSize: 15,
          ),
        );
        break;
      case MessageType.voice:

        content = VoiceMessagePlayer(
          activeSliderColor: AppColor.kPrimaryColor,
          controller: VoiceController(
            audioSrc: msg.audioPath!,
            onComplete: () {},
            onPause: () {},
            onPlaying: () {},
            onError: (_) {},
            isFile: true,
            maxDuration: msg.voiceDuration!,
          ),
          innerPadding: 12,
          cornerRadius: 12,
        );
        break;
      case MessageType.images:
        content = _buildImageGrid(msg.images!);
        break;
      case MessageType.finish:
        content = Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            color: const Color(0xFFEFF2F5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tekshirib o’tamiz..',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  height: 1.40,
                  letterSpacing: -0.30,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Muammo matni yoki audiosi',
                style: TextStyle(
                  color: const Color(0xFF6B7073),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: 1.40,
                  letterSpacing: -0.30,
                ),
              ),

              if (_voiceFilePath != null) ...[
                VoiceMessagePlayer(
                  activeSliderColor: AppColor.kPrimaryColor,
                  controller: VoiceController(
                    audioSrc: msg.audioPath!,
                    onComplete: () {},
                    onPause: () {},
                    onPlaying: () {},
                    onError: (_) {},
                    isFile: true,
                    maxDuration: msg.voiceDuration!,
                  ),
                  innerPadding: 12,
                  cornerRadius: 12,
                ),
                const SizedBox(height: 8),
              ] else ...[
                Text(
                  msg.text!,
                  style: TextStyle(color: Colors.black87, fontSize: 15),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Muammo rasmi yoki videosi',
                style: TextStyle(
                  color: const Color(0xFF6B7073),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: 1.40,
                  letterSpacing: -0.30,
                ),
              ),
              if (_submittedImages.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildImageGrid(_submittedImages),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 12),
              if (_submittedPrice != null) ...[
                Text(
                  'Ushbu ishni uchun nechpul bermoqchisiz?',
                  style: TextStyle(
                    color: const Color(0xFF6B7073),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.40,
                    letterSpacing: -0.30,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatPrice(_submittedPrice!),
                  style: TextStyle(color: Colors.black87, fontSize: 15),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(height: 8),
              Text(
                'Agar barchasi to’g’ri bo’lsa, “yuborish” tugmasini bosing, yoki yuborish deb yozing.',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: 1.40,
                  letterSpacing: -0.30,
                ),
              ),
              const SizedBox(height: 15),
              AppButton(
                // minWidth: double.infinity,
                // height: 48,
                // color: AppColor.kPrimaryColor,
                // shape: RoundedRectangleBorder(
                //   borderRadius: BorderRadius.circular(50),
                // ),
                isLoading: _isRequestSent,
                onTap: () {
                  setState(() {
                    _isRequestSent = true;
                  });
                  if (_voiceFilePath != null) {
                    var reportModel = ReportModel(
                      text: _submittedTextOrVoice ?? '',
                      voiceFile: File(_voiceFilePath!),
                      images: _submittedImages,
                      price: _submittedPrice ?? '',
                      latitude: currentLocation.lat.toDouble(),
                      longitude: currentLocation.lng.toDouble(),
                    );
                    context.read<ChatBloc>().add(
                      CreateReportEvent(
                        reportModel: reportModel,
                        onError: () {
                          _isRequestSent = false;
                          setState(() {});

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Xatolik yuz berdi. Iltimos, qayta urinib ko\'ring.',
                              ),
                            ),
                          );
                        },
                        onSuccess: () {
                          setState(() {
                            _isRequestSent = false;
                          });
                          context.push(Pages.invatesPage);
                          setState(() {
                            _isSubmitted = true;
                            // _messages.clear() ni olib tashlaymiz
                            _messages.add(
                              ChatMessage(
                                type: MessageType.text,
                                text: 'Muammo muvaffaqiyatli yuborildi!',
                                isMe: false,
                              ),
                            ); // Muvaffaqiyat xabarini qo'shamiz
                            _currentQuestionIndex = 0;
                            _showAcceptUI = false;
                          });
                          _scrollToBottom();
                        },
                      ),
                    );
                  } else {
                    var reportModel = ReportModel(
                      text: _submittedTextOrVoice ?? '',
                      images: _submittedImages,
                      price: _submittedPrice ?? '',
                      latitude: currentLocation.lat.toDouble(),
                      longitude: currentLocation.lng.toDouble(),
                    );
                    context.read<ChatBloc>().add(
                      CreateReportEvent(
                        reportModel: reportModel,
                        onError: () {
                          _isRequestSent = false;
                          setState(() {});

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Xatolik yuz berdi. Iltimos, qayta urinib ko\'ring.',
                              ),
                            ),
                          );
                        },
                        onSuccess: () {
                          setState(() {
                            _isRequestSent = false;
                          });
                          context.push(Pages.invatesPage);
                          setState(() {
                            _isSubmitted = true;
                            // _messages.clear() ni olib tashlaymiz
                            _messages.add(
                              ChatMessage(
                                type: MessageType.text,
                                text: 'Muammo muvaffaqiyatli yuborildi!',
                                isMe: false,
                              ),
                            ); // Muvaffaqiyat xabarini qo'shamiz
                            _currentQuestionIndex = 0;
                            _showAcceptUI = false;
                          });
                          _scrollToBottom();
                        },
                      ),
                    );
                  }
                },
                title: 'Yuborish',
                // child: Center(
                //   child: Text(
                //     ,
                //     style: TextStyle(
                //       color: Colors.white,
                //       fontSize: 16,
                //       fontFamily: 'Inter',
                //       fontWeight: FontWeight.w600,
                //       height: 1.40,
                //       letterSpacing: -0.30,
                //     ),
                //   ),
                // ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  '09:59 PM +05, Jul 14, 2025', // Updated to current time
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        );
        break;
    }

    return Row(
      mainAxisAlignment: align,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: content,
        ),
      ],
    );
  }

  Widget _buildImageGrid(List<File> items) {
    final half = (items.length / 2).ceil();
    final top = items.take(half).toList();
    final bottom = items.skip(half).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _rowOfImages(top),
        if (bottom.isNotEmpty) const SizedBox(height: 4),
        if (bottom.isNotEmpty) _rowOfImages(bottom),
      ],
    );
  }

  Widget _rowOfImages(List<File> items) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(item, width: 50, height: 50, fit: BoxFit.cover),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton(
    String text,
    Color color,
    VoidCallback onPressed, {
    bool isPrimary = false,
    bool isEdit = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minimumSize: const Size(120, 40),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
          color: isPrimary || isEdit ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  String _formatPrice(String price) {
    final number = double.tryParse(price) ?? 0.0;
    final format = NumberFormat.currency(locale: 'uz_UZ', symbol: 'UZS ');
    return format.format(number);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _validateForm() {
    if (_submittedTextOrVoice == null && _voiceFilePath == null) return false;
    if (_submittedImages.isEmpty) return false;
    if (_submittedPrice == null || !isNumeric(_submittedPrice!)) return false;
    return true;
  }

  void _editField() {
    setState(() {
      _showAcceptUI = false;
      _currentQuestionIndex = 0; // Start from the first question
      _messages.add(
        ChatMessage(
          type: MessageType.text,
          text: 'Ma\'lumotlar qayta kiritish uchun boshlanadi.',
          isMe: false,
        ),
      );
      _voiceFilePath = null; // Clear voice file
      _selectedImages.clear(); // Clear images
      _submittedTextOrVoice = null; // Clear submitted text or voice
      _submittedPrice = null; // Clear submitted price
      _answers.clear(); // Clear all answers
      if (_questions.isNotEmpty) {
        _messages.add(
          ChatMessage(
            type: MessageType.text,
            text: _questions[_currentQuestionIndex].title,
            isMe: false,
          ),
        );
      }
    });
  }
}
