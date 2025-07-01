import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voice_message_player/voice_message_player.dart';
import 'package:photo_viewer/photo_viewer.dart';
import 'package:hl_image_picker/hl_image_picker.dart';

import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';
import 'package:taxi_app/src/features/chat/presentation/widgets/chat_input_widget.dart';
import '../models/chat_model.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _recorder = Record();
  final _picker = HLImagePicker();

  bool isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;
  String? _recordedFilePath;

  final List<ChatMessage> _messages = [
    ChatMessage(
      type: MessageType.text,
      text: 'Salom, qanday yordam bera olaman?',
      isMe: false,
    ),
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _recorder.dispose();
    _animationController.dispose();
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
      setState(() {
        _messages.add(
          ChatMessage(
            type: MessageType.voice,
            voiceDuration: Duration(seconds: _recordDuration),
            audioPath: path,
            isMe: true,
          ),
        );
      });
    }
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
  }

  void _sendText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(
        ChatMessage(type: MessageType.text, text: text, isMe: true),
      );
      _controller.clear();
    });
  }

  Future<void> _pickImages() async {
    final picked = await _picker.openPicker(
      pickerOptions:
      HLPickerOptions(mediaType: MediaType.image, maxSelectedAssets: 6),
    );
    if (picked.isNotEmpty) {
      setState(() {
        _messages.add(
          ChatMessage(type: MessageType.images, images: picked, isMe: true),
        );
      });
    }
  }

  void _onLongPress(BuildContext itemCtx, int idx) {
    final renderBox = itemCtx.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context)!.context.findRenderObject() as RenderBox;
    final topLeft = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
    final size = renderBox.size;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const menuWidth = 200.0;
    const menuHeight = 180.0;
    const menuGap = 4.0;

    final showAbove = topLeft.dy + size.height + menuHeight > screenHeight;
    final menuLeft = (topLeft.dx + size.width - menuWidth)
        .clamp(16.0, screenWidth - menuWidth - 16.0);
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
                _animationController.reverse().then((_) => Navigator.of(context).pop());
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
                child: _buildBubble(_messages[idx], highlight: true),
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
                    _actionTile(
                        Icons.reply, 'Reply', () => _dismissAnd(() {/* reply */}),
                        textColor: Platform.isIOS ? Colors.white : Theme.of(context).colorScheme.onSurface),
                    if (msg.type == MessageType.text)
                      _actionTile(Icons.copy, 'Copy', () => _dismissAnd(() {
                        Clipboard.setData(ClipboardData(text: msg.text!));
                      }), textColor: Platform.isIOS ? Colors.white : Theme.of(context).colorScheme.onSurface),
                    if (msg.type == MessageType.text && msg.isMe)
                      _actionTile(Icons.edit, 'Edit', () => _dismissAnd(() {/* edit */}),
                          textColor: Platform.isIOS ? Colors.white : Theme.of(context).colorScheme.onSurface),
                    if (msg.type == MessageType.images) ...[
                      _actionTile(
                          Icons.remove_red_eye, 'View Images', () => _dismissAnd(() {
                        final paths = msg.images!.map((i) => i.path).toList();
                        showPhotoViewer(
                          context: context,
                          builders: paths
                              .map<WidgetBuilder>(
                                  (p) => (_) => Image.file(File(p), fit: BoxFit.contain))
                              .toList(),
                          initialPage: 0,
                        );
                      }), textColor: Platform.isIOS ? Colors.white : Theme.of(context).colorScheme.onSurface),
                      _actionTile(Icons.download, 'Save Images',
                              () => _dismissAnd(() {/* save */}), textColor: Platform.isIOS ? Colors.white : Theme.of(context).colorScheme.onSurface),
                    ],
                    if (msg.type == MessageType.voice) ...[
                      _actionTile(Icons.play_arrow, 'Play Voice',
                              () => _dismissAnd(() {/* play */}), textColor: Platform.isIOS ? Colors.white : Theme.of(context).colorScheme.onSurface),
                      _actionTile(Icons.share, 'Share Voice',
                              () => _dismissAnd(() {/* share */}), textColor: Platform.isIOS ? Colors.white : Theme.of(context).colorScheme.onSurface),
                    ],
                    _actionTile(Icons.delete, 'Delete', () => _dismissAnd(() {
                      setState(() => _messages.removeAt(idx));
                    }), textColor: Colors.redAccent),
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

  ListTile _actionTile(IconData icon, String label, VoidCallback onTap,
      {Color textColor = Colors.black}) {
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        title: Container(
          padding: const EdgeInsets.symmetric(vertical: 7.5, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF2F5),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SvgPicture.asset(AppIcons.location, width: 16, height: 16),
            const SizedBox(width: 6),
            const Text(
              '2972 Westheimer Rd. Santa Ana...',
              style: TextStyle(
                  color: Colors.black, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ]),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              'Sizda qanday muammo?',
              style: context.textS.headlineMedium!
                  .copyWith(fontWeight: FontWeight.w500, fontSize: 24),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) => Builder(
                builder: (itemCtx) => GestureDetector(
                  onLongPress: () => _onLongPress(itemCtx, i),
                  child: _buildBubble(_messages[i]),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ChatInputWidget(
                controller: _controller,
                onAttach: _pickImages,
                onVoice: isRecording ? _stopRecordingAndAdd : _startRecording,
                onCancel: _cancelRecording,
                onSend: _sendText,
                isRecording: isRecording,
                recordDuration: _recordDuration,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg, {bool highlight = false}) {
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
          style: TextStyle(color: msg.isMe ? Colors.black : Colors.black, fontSize: 14),
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
    }

    return Row(
      mainAxisAlignment: align,
      children: [
        Container(
          constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: EdgeInsets.all(highlight ? 14 : 12),
          decoration: BoxDecoration(color: bg, borderRadius: radius),
          child: content,
        ),
      ],
    );
  }

  Widget _buildImageGrid(List<HLPickerItem> items) {
    final half = (items.length / 2).ceil();
    final top = items.take(half).toList(), bottom = items.skip(half).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _rowOfImages(top),
        if (bottom.isNotEmpty) const SizedBox(height: 8),
        if (bottom.isNotEmpty) _rowOfImages(bottom),
      ],
    );
  }

  Widget _rowOfImages(List<HLPickerItem> items) {
    final builders = items
        .map<WidgetBuilder>((i) => (_) => Image.file(File(i.path), fit: BoxFit.contain))
        .toList();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: items.asMap().entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => showPhotoViewer(
              context: context,
              builders: builders,
              initialPage: e.key,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(e.value.path),
                  width: 80, height: 80, fit: BoxFit.cover),
            ),
          ),
        );
      }).toList(),
    );
  }
}