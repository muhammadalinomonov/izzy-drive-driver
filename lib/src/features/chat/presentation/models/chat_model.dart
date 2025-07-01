
// import 'package:hl_image_picker/hl_image_picker.dart';

enum MessageType { text, voice, images }

class ChatMessage {
  final MessageType type;
  final String? text;
  final Duration? voiceDuration;
  final String? audioPath;
  final List? images;
  final bool isMe;
  ChatMessage({
    required this.type,
    this.text,
    this.voiceDuration,
    this.audioPath,
    this.images,
    this.isMe = false,
  });
}
