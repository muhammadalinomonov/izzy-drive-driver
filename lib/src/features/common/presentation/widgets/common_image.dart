import 'package:flutter/material.dart';

class CommonNetworkImage extends StatelessWidget {
  const CommonNetworkImage({
    super.key,
    this.imageUrl,
    this.height,
    this.width,
    this.radius,
    this.fit,
    this.fallback,
  });

  final String? imageUrl;
  final double? height;
  final double? width;
  final double? radius;
  final BoxFit? fit;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return _buildFallback();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? 0),
      child: Image.network(
        url,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    final iconSize = ((height ?? width ?? 40) * 0.5).clamp(16.0, 64.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? 0),
      child: Container(
        height: height,
        width: width,
        color: const Color(0xFFEFEFEF),
        alignment: Alignment.center,
        child: fallback ??
            Icon(
              Icons.person_outline,
              color: const Color(0xFF9E9E9E),
              size: iconSize,
            ),
      ),
    );
  }
}

class AvatarImage extends StatelessWidget {
  const AvatarImage({super.key, this.imageUrl, this.size = 40});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CommonNetworkImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      radius: size / 2,
      fit: BoxFit.cover,
    );
  }
}