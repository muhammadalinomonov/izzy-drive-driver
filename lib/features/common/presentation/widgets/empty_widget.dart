import 'package:flutter/material.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/core/utils/context_extensions.dart';

class EmptyWidget extends StatelessWidget {
  const EmptyWidget({
    super.key,
    this.icon,
    this.title,
    this.subtitle,
    this.imageWidth,
    this.imageHeight,
  });

  final String? icon;
  final String? title;
  final String? subtitle;
  final double? imageWidth;
  final double? imageHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Image.asset(
            icon!,
            width: imageWidth,
            height: imageHeight,
          ),
        SizedBox(height: 20),
        if (title != null)
          Text(
            title!,
            style: context.textTheme.titleLarge!.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              subtitle!,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(color: gray6),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
