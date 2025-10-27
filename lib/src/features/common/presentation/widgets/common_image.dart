import 'package:flutter/material.dart';

class CommonNetworkImage extends StatelessWidget {
  const CommonNetworkImage({super.key, this.imageUrl, this.height, this.width, this.radius, this.fit});

  final String? imageUrl;
  final double? height;
  final double? width;
  final double? radius;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? 0),
      child: Image.network(
        imageUrl!,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person_outlined),
      ),
    );
  }
}
