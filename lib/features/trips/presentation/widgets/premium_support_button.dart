import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/core/constants/color/app_icons.dart';
import 'package:taxi_app/core/session/premium_session.dart';
import 'package:taxi_app/routes/pages.dart';

/// The floating Support Message affordance (docs/ui/10.png), shown to Premium
/// drivers on every map screen in the Trips module: the planner, the route
/// overview and driving mode.
///
/// Visibility follows the global `is_paid_user` entitlement rather than a bloc,
/// so the button appears the moment the profile resolves without any of these
/// screens knowing that the profile feature exists. Non-premium drivers get a
/// zero-size widget, [spacingAbove] included - a hidden button must not leave a
/// gap in the control column it sits in.
class PremiumSupportButton extends StatelessWidget {
  const PremiumSupportButton({
    super.key,
    this.spacingAbove = 0,
    this.spacingBelow = 0,
  });

  /// Gaps inserted around the button when it is visible. Callers that stack it
  /// with other map controls pass the same spacing they use between those, and
  /// pick the side according to where in the stack it sits - the gap has to
  /// disappear with the button.
  final double spacingAbove;
  final double spacingBelow;

  /// Tap target size. Exposed so screens that reserve room for the control
  /// column (to keep it from sliding off-screen) can do the arithmetic against
  /// the real number instead of a copy of it.
  static const double diameter = 44;

  /// Total vertical room this takes when visible, at [spacing] above it.
  static double heightWith(double spacing) => diameter + spacing;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PremiumSession.listenable,
      builder: (context, isPremium, _) {
        if (!isPremium) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.only(top: spacingAbove, bottom: spacingBelow),
          child: Material(
            // Solid primary fill, so it reads as an offer rather than another
            // map control.
            color: AppColor.kPrimaryColor,
            shape: const CircleBorder(),
            elevation: 3,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.push(Pages.supportMessage),
              child: SizedBox(
                width: diameter,
                height: diameter,
                child: Center(
                  child: SvgPicture.asset(
                    AppIcons.chat,
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
