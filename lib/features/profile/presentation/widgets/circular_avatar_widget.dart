import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/assets/constants/icons.dart';

class CircularAvatarWidget extends StatelessWidget {
  const CircularAvatarWidget({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      clipBehavior: Clip.hardEdge,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: white, boxShadow: [
        BoxShadow(
          color: black.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 0), // changes position of shadow
        ),
      ]),
      alignment: Alignment.bottomCenter,
      child: SvgPicture.asset(
        AppIcons.avatar,
        width: 25,
        height: 35,
      ),
    );
  }
}
