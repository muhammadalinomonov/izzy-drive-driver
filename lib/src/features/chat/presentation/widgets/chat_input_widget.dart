import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';

class ChatInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onAttach;
  final VoidCallback onVoice;
  final VoidCallback onCancel;
  final VoidCallback onSend;
  final bool isRecording;
  final int recordDuration;

  const ChatInputWidget({
    Key? key,
    required this.controller,
    required this.onAttach,
    required this.onVoice,
    required this.onCancel,
    required this.onSend,
    required this.isRecording,
    required this.recordDuration,
  }) : super(key: key);

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  bool _isTextEmpty = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _isTextEmpty = widget.controller.text.trim().isEmpty;
  }

  void _onChanged() {
    final empty = widget.controller.text.trim().isEmpty;
    if (empty != _isTextEmpty) {
      setState(() => _isTextEmpty = empty);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  String _format(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildIconButton({required Widget icon, required VoidCallback onTap}) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: icon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: ShapeDecoration(
        color: const Color(0xFFEFF2F5),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFE2E7EB), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // Attach button
          _buildIconButton(
            icon: Icon(Icons.attach_file, size: 24, color: AppColor.grey),
            onTap: widget.onAttach,
          ),

          const SizedBox(width: 12),

          // Text input
          Expanded(
            child: TextField(
              controller: widget.controller,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              cursorColor: AppColor.kPrimaryColor,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) {
                if (!_isTextEmpty) widget.onSend();
              },
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Matn yoki ovozli habar',
                hintStyle: TextStyle(color: AppColor.grey, fontSize: 16),
              ),
            ),
          ),

          // Recording controls or mic/send
          if (widget.isRecording) ...[
            _buildIconButton(
              icon: const Icon(Icons.close, size: 24, color: Colors.red),
              onTap: widget.onCancel,
            ),
            const SizedBox(width: 12),
            Text(
              _format(widget.recordDuration),
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(width: 12),
            _buildIconButton(
              icon: const Icon(Icons.stop, size: 24, color: Colors.red),
              onTap: widget.onVoice,
            ),
          ] else
            _buildIconButton(
              icon: Icon(
                _isTextEmpty ? Icons.mic : Icons.send,
                size: 28,
                color: AppColor.kPrimaryColor,
              ),
              onTap: _isTextEmpty ? widget.onVoice : widget.onSend,
            ),
        ],
      ),
    );
  }
}
