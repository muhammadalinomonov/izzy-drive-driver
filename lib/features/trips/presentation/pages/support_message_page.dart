import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/core/constants/color/app_icons.dart';

/// Support conversation, per `docs/ui/11.png`.
///
/// **UI only.** Every action is a placeholder callback and the thread is
/// static sample content - no networking, no sending, no state management yet.
/// The shapes below (message model, composer callbacks) are deliberately the
/// ones a real backend would fill, so wiring it up later is additive.
class SupportMessagePage extends StatefulWidget {
  const SupportMessagePage({super.key});

  @override
  State<SupportMessagePage> createState() => _SupportMessagePageState();
}

class _SupportMessagePageState extends State<SupportMessagePage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Placeholder actions, ready for backend integration ──────────────────

  void _onSend() {}

  void _onAttach() {}

  void _onVoice() {}

  void _onDrive() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        backgroundColor: AppColor.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColor.black),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Support',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColor.black,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                _OutgoingRequestBubble(
                  message:
                      'I would like to refuel at this fuel station. Please '
                      'review my request and activate my fuel card.',
                  stationName: 'Alixon Fuel',
                  address: '3301 Kuhn Rd, West Memphis, AR 72301',
                  price: r'$54.54-$60.6 for gallon',
                  distance: '24 mi',
                  time: '23:00',
                ),
                const SizedBox(height: 12),
                const _AgentBubble(
                  sender: 'Nick Rose',
                  body: "Hello! We have received your request. We'll review it "
                      'and get back to you as soon as possible. Please wait.',
                ),
                const SizedBox(height: 12),
                _AgentBubble(
                  sender: 'Nick Rose',
                  highlight: 'Your request has been approved!',
                  body: 'You can now refuel at this fuel station. Your fuel '
                      'card has been activated and will remain active until '
                      '8:42 PM.',
                  action: _DriveButton(onTap: _onDrive),
                ),
              ],
            ),
          ),
          _Composer(
            controller: _controller,
            onAttach: _onAttach,
            onVoice: _onVoice,
            onSend: _onSend,
          ),
        ],
      ),
    );
  }
}

/// The driver's request: a blue bubble carrying the message plus a white card
/// describing the fuel station it refers to.
class _OutgoingRequestBubble extends StatelessWidget {
  const _OutgoingRequestBubble({
    required this.message,
    required this.stationName,
    required this.address,
    required this.price,
    required this.distance,
    required this.time,
  });

  final String message;
  final String stationName;
  final String address;
  final String price;
  final String distance;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(fontSize: 14, height: 1.4, color: AppColor.black),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stationName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColor.black,
                  ),
                ),
                const SizedBox(height: 10),
                _StationFact(icon: Icons.location_on_outlined, text: address),
                const SizedBox(height: 8),
                _StationFact(icon: Icons.attach_money_rounded, text: price),
                const SizedBox(height: 8),
                _StationFact(
                  icon: Icons.directions_car_outlined,
                  text: distance,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              time,
              style: TextStyle(fontSize: 12, color: AppColor.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class _StationFact extends StatelessWidget {
  const _StationFact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: AppColor.kPrimaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, height: 1.35, color: AppColor.black),
          ),
        ),
      ],
    );
  }
}

/// A support agent's reply. [highlight] renders the emphasised blue lead-in
/// used for the approval message; [action] hangs an optional button beneath.
class _AgentBubble extends StatelessWidget {
  const _AgentBubble({
    required this.sender,
    required this.body,
    this.highlight,
    this.action,
  });

  final String sender;
  final String body;
  final String? highlight;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final lead = highlight;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F7),
        borderRadius: BorderRadius.circular(14),
      ),
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
          Text(
            body,
            style: TextStyle(fontSize: 14, height: 1.4, color: AppColor.black),
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            action!,
          ],
        ],
      ),
    );
  }
}

/// White pill that starts navigation to the approved station.
class _DriveButton extends StatelessWidget {
  const _DriveButton({required this.onTap});

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
                  'Drive',
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
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onAttach,
    required this.onVoice,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onAttach;
  final VoidCallback onVoice;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F4F7),
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
                onPressed: onAttach,
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  style: TextStyle(fontSize: 14, color: AppColor.black),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Matn yoki ovozli habar',
                    hintStyle: TextStyle(fontSize: 14, color: AppColor.grey),
                  ),
                ),
              ),
              IconButton(
                icon: SvgPicture.asset(
                  AppIcons.microphone,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    AppColor.kPrimaryColor,
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: onVoice,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
