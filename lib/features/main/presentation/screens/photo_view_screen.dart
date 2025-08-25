import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/features/common/presentation/widgets/common_image.dart';
import 'package:mechanic/features/common/presentation/widgets/common_scalel_animation.dart';

class PhotoViewScreen extends StatefulWidget {
  const PhotoViewScreen({super.key, required this.image, required this.tag});

  final String image;
  final String tag;

  @override
  State<PhotoViewScreen> createState() => _PhotoViewScreenState();
}

class _PhotoViewScreenState extends State<PhotoViewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Hero(
            tag: widget.tag,
            child: CommonImage(
              imageUrl: widget.image,
                fit: BoxFit.cover
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: CommonScaleAnimation(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                height: 32,
                width: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(CupertinoIcons.xmark),
              ),
            ),
          )
        ],
      ),
    );
  }
}
