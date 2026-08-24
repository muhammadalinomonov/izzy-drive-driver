import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/core/constants/color/app_icons.dart';
import 'package:taxi_app/features/trips/data/model/support_chat_model.dart';

/// Chrome shared by the support screens - the unified timeline
/// (`support_timeline_page.dart`, docs/ui/11.png) and the per-review thread
/// it opens into (`route_support_page.dart`, docs/ui/8-2.png).
///
/// Both designs are the same chat: an outgoing bubble carrying a white detail
/// card, agent replies with an optional emphasised lead-in, a white Drive pill
/// under an approval, and one composer. Only the card inside the bubble
/// differs, so that is the part each page supplies itself.

/// Outgoing (driver) bubble tint.
const Color kSupportOutgoingColor = Color(0xFFE8F1FE);

/// Incoming (agent) bubble tint.
const Color kSupportIncomingColor = Color(0xFFF1F4F7);

/// A chat bubble.
///
/// Sided like a real messenger: the driver's own messages sit against the
/// right edge, support's against the left, and each squares off the bottom
/// corner on its own side so the thread reads as two voices at a glance.
/// Bubbles hug their content up to [maxWidthFactor] of the screen rather than
/// spanning it, which is what makes a one-line reply look like a one-line
/// reply.
class SupportBubble extends StatelessWidget {
  const SupportBubble({
    super.key,
    required this.outgoing,
    required this.child,
    this.wide = false,
  });

  final bool outgoing;
  final Widget child;

  /// Set for bubbles carrying a route or station card - those need most of the
  /// screen to stay legible, where plain text should stay narrow.
  final bool wide;

  static const double _radius = 16;

  /// Share of the screen a bubble may take, leaving the far edge visibly free
  /// so the sided layout stays obvious even on a long message.
  double get maxWidthFactor => wide ? 0.9 : 0.76;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * maxWidthFactor,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: outgoing ? kSupportOutgoingColor : kSupportIncomingColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(_radius),
              topRight: const Radius.circular(_radius),
              bottomLeft:
                  outgoing ? const Radius.circular(_radius) : Radius.zero,
              bottomRight:
                  outgoing ? Radius.zero : const Radius.circular(_radius),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A support agent's reply: sender name, an optional emphasised blue lead-in
/// (used for approvals and recommendations), the body, then anything the page
/// hangs beneath - a suggested-route card, a Drive button.
class SupportAgentBubble extends StatelessWidget {
  const SupportAgentBubble({
    super.key,
    required this.sender,
    required this.body,
    this.highlight,
    this.attachment,
    this.action,
  });

  final String sender;
  final String body;

  /// Rendered above [body] in primary blue.
  final String? highlight;

  /// Card shown under the text, e.g. the suggested route.
  final Widget? attachment;

  /// Button shown last, e.g. [SupportDriveButton].
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final lead = highlight;
    return SupportBubble(
      outgoing: false,
      wide: attachment != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            sender,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColor.kPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          if (lead != null)
            Text(
              lead,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColor.kPrimaryColor,
              ),
            ),
          if (body.isNotEmpty)
            Text(
              body,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: AppColor.black,
              ),
            ),
          if (attachment != null) ...[
            const SizedBox(height: 10),
            attachment!,
          ],
          if (action != null) ...[
            const SizedBox(height: 10),
            action!,
          ],
        ],
      ),
    );
  }
}

/// The timestamp inside a message bubble.
///
/// Plain text on purpose: the bubble's own column pins it to the trailing edge
/// (`CrossAxisAlignment.end`), so it can't stretch a short message to the full
/// bubble width the way a self-aligning widget would.
class SupportTimestamp extends StatelessWidget {
  const SupportTimestamp({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 11, color: AppColor.grey),
    );
  }
}

/// One plain message bubble - the driver's own on the right with a
/// timestamp, support's reply on the left. Shared by every screen that
/// renders a [SupportChatMessage] as a bare bubble (no card, no action):
/// plain text is the whole contract for a message
/// (docs/mobile-chat-complete-api-websocket.md §2 - a route or fuel card is
/// never a message payload).
class SupportMessageBubble extends StatelessWidget {
  const SupportMessageBubble({super.key, required this.message});

  final SupportChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (!message.isDriver) {
      return SupportAgentBubble(
        sender: message.senderName.isEmpty
            ? 'routeSupport.supportFallbackName'.tr()
            : message.senderName,
        body: message.message,
      );
    }

    final timestamp = message.sentAtLabel;
    return SupportBubble(
      outgoing: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.message,
            style: TextStyle(fontSize: 14, height: 1.35, color: AppColor.black),
          ),
          if (timestamp.isNotEmpty) ...[
            const SizedBox(height: 4),
            SupportTimestamp(text: timestamp),
          ],
        ],
      ),
    );
  }
}

/// White pill that starts navigation for whatever the agent just approved or
/// suggested.
class SupportDriveButton extends StatelessWidget {
  const SupportDriveButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'routeSupport.drive'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColor.black,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.navigation_rounded,
                  size: 17,
                  color: AppColor.kPrimaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom composer: attachment, text field, then microphone or send.
///
/// The trailing action swaps depending on whether there is anything typed -
/// voice input while the field is empty, an explicit Send button the moment
/// there is text to send - the same convention as every mainstream messenger,
/// so a driver never has to hunt for how to actually submit a message.
class SupportComposer extends StatelessWidget {
  const SupportComposer({
    super.key,
    required this.controller,
    required this.onAttach,
    required this.onVoice,
    required this.onSend,
    this.enabled = true,
  });

  final TextEditingController controller;
  final VoidCallback onAttach;
  final VoidCallback onVoice;
  final VoidCallback onSend;

  /// False while a send is in flight, so the same message can't be posted
  /// twice.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: kSupportIncomingColor,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              IconButton(
                icon: SvgPicture.asset(
                  AppIcons.paperclip,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(AppColor.grey, BlendMode.srcIn),
                ),
                onPressed: enabled ? onAttach : null,
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  style: TextStyle(fontSize: 14, color: AppColor.black),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'routeSupport.composerHint'.tr(),
                    hintStyle: TextStyle(fontSize: 14, color: AppColor.grey),
                  ),
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  if (value.text.trim().isEmpty) {
                    return IconButton(
                      icon: SvgPicture.asset(
                        AppIcons.micFilled,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          AppColor.kPrimaryColor,
                          BlendMode.srcIn,
                        ),
                      ),
                      onPressed: enabled ? onVoice : null,
                    );
                  }
                  return _SendButton(enabled: enabled, onTap: onSend);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filled circular Send action, shown once there is text to submit.
class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: enabled ? AppColor.kPrimaryColor : AppColor.grey2,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.send_rounded, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
