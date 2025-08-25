import 'package:flutter/material.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/core/utils/context_extensions.dart';

class LanguageItem extends StatelessWidget {
  const LanguageItem({super.key, required this.isSelected, required this.language, required this.onTap});

  final bool isSelected;
  final String language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              language,
              style: context.textTheme.headlineLarge!.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelected ? black : gray4,
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(
                  Icons.check,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
