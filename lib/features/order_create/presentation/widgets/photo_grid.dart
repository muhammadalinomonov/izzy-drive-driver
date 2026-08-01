import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/core/constants/color/app_icons.dart';
import 'package:taxi_app/features/order_create/presentation/widgets/photo_preview.dart';

/// 3-column grid showing attached photos plus a final "+" tile while
/// under the cap. Tap a photo to open a full-screen preview; tap the X
/// overlay to remove it.
class PhotoGrid extends StatelessWidget {
  const PhotoGrid({
    super.key,
    required this.photos,
    required this.maxCount,
    required this.onAdd,
    required this.onRemove,
  });

  final List<File> photos;
  final int maxCount;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final canAdd = photos.length < maxCount;
    final tiles = <Widget>[
      ...List.generate(photos.length, (i) => _PhotoTile(
            file: photos[i],
            onRemove: () => onRemove(i),
            onTap: () => openPhotoPreview(
              context,
              photos: photos,
              initialIndex: i,
            ),
          )),
      if (canAdd) _AddTile(onTap: onAdd),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tiles
          .map((w) => SizedBox(
                width: (MediaQuery.sizeOf(context).width - 24 - 16) / 3,
                height: (MediaQuery.sizeOf(context).width - 24 - 16) / 3,
                child: w,
              ))
          .toList(),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.file,
    required this.onRemove,
    required this.onTap,
  });
  final File file;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image area handles tap-to-preview. X overlay is in a separate
        // Positioned child so its own GestureDetector wins inside its bounds.
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(file, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                AppIcons.x,
                width: 12,
                height: 12,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.lightBlue,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColor.lightGrey, style: BorderStyle.solid),
        ),
        child: Icon(Icons.add, size: 26, color: AppColor.grey),
      ),
    );
  }
}
