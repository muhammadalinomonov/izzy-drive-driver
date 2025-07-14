
// import 'package:hl_image_picker/hl_image_picker.dart';

import 'dart:io';

enum MessageType { text, voice, images, finish }
class ChatMessage {
  final MessageType type;
  final String? text;
  final Duration? voiceDuration;
  final String? audioPath;
  final List<File>? images; // Ensure this is List<File>?
  final bool isMe;

  ChatMessage({
    required this.type,
    this.text,
    this.voiceDuration,
    this.audioPath,
    this.images,
    required this.isMe,
  });
}