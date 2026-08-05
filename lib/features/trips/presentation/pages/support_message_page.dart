import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/core/constants/color/app_icons.dart';
import 'package:taxi_app/features/trips/presentation/widgets/support_chat.dart';

/// Support conversation, per `docs/ui/11.png`.
///
/// **UI only.** Every action is a placeholder callback and the thread is
/// static sample content - no networking, no sending, no state management yet.
/// The shapes below (message model, composer callbacks) are deliberately the
/// ones a real backend would fill, so wiring it up later is additive.
///
/// The bubbles, Drive pill and composer are shared with the route review
/// thread (`route_support_page.dart`) - see `widgets/support_chat.dart`. Only
/// the card inside the driver's bubble is specific to this page, because this
/// conversation is about a fuel station rather than a route.
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
          'routeSupport.title'.tr(),
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
                const SupportAgentBubble(
                  sender: 'Nick Rose',
                  body: "Hello! We have received your request. We'll review it "
                      'and get back to you as soon as possible. Please wait.',
                ),
                const SizedBox(height: 12),
                SupportAgentBubble(
                  sender: 'Nick Rose',
                  highlight: 'Your request has been approved!',
                  body: 'You can now refuel at this fuel station. Your fuel '
                      'card has been activated and will remain active until '
                      '8:42 PM.',
                  action: SupportDriveButton(onTap: _onDrive),
                ),
              ],
            ),
          ),
          SupportComposer(
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
    return SupportBubble(
      outgoing: true,
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
                // Same three design icons the marker sheet uses, so a station
                // reads identically wherever it appears.
                _StationFact(icon: AppIcons.tripOrigin, text: address),
                const SizedBox(height: 8),
                _StationFact(icon: AppIcons.price, text: price),
                const SizedBox(height: 8),
                _StationFact(icon: AppIcons.routeMile, text: distance),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SupportTimestamp(text: time),
        ],
      ),
    );
  }
}

class _StationFact extends StatelessWidget {
  const _StationFact({required this.icon, required this.text});

  /// SVG asset path.
  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          icon,
          width: 17,
          height: 17,
          colorFilter: ColorFilter.mode(
            AppColor.kPrimaryColor,
            BlendMode.srcIn,
          ),
        ),
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
