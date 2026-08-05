import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/core/constants/color/app_icons.dart';

/// Chrome shared by the two support conversations - the fuel-station thread
/// (`support_message_page.dart`, docs/ui/11.png) and the route review thread
/// (`route_support_page.dart`, docs/ui/8-2.png).
///
/// Both designs are the same chat: an outgoing bubble carrying a white detail
/// card, agent replies with an optional emphasised lead-in, a white Drive pill
/// under an approval, and one composer. Only the card inside the bubble
/// differs, so that is the part each page supplies itself.

/// Outgoing (driver) bubble tint.
const Color kSupportOutgoingColor = Color(0xFFE8F1FE);

/// Incoming (agent) bubble tint.
const Color kSupportIncomingColor = Color(0xFFF1F4F7);

/// A chat bubble. Full width in both directions, as in the designs - the
/// author is carried by the tint and by the sender name, not by alignment.
class SupportBubble extends StatelessWidget {
  const SupportBubble({
    super.key,
    required this.outgoing,
    required this.child,
  });

  final bool outgoing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: outgoing ? kSupportOutgoingColor : kSupportIncomingColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColor.black,
            ),
          ),
          const SizedBox(height: 8),
          if (lead != null)
            Text(
              lead,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: AppColor.kPrimaryColor,
              ),
            ),
          if (body.isNotEmpty)
            Text(
              body,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColor.black,
              ),
            ),
          if (attachment != null) ...[
            const SizedBox(height: 12),
            attachment!,
          ],
          if (action != null) ...[
            const SizedBox(height: 12),
            action!,
          ],
        ],
      ),
    );
  }
}

/// The timestamp under an outgoing message.
class SupportTimestamp extends StatelessWidget {
  const SupportTimestamp({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: AppColor.grey),
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
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'routeSupport.drive'.tr(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColor.black,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.navigation_rounded,
                  size: 18,
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

/// Bottom composer: attachment, text field, microphone.
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
              IconButton(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
