/// Shared loading-placeholder primitives.
///
/// The same `Shimmer.fromColors` block with the same two greys and the same
/// 1400ms period was copy-pasted into eleven widgets across seven features,
/// and had already drifted in three of them (two different base greys plus one
/// `Colors.grey.shade300` pair). Skeletons are the first thing a user sees on
/// a cold start, so they have to look like one app rather than seven.
///
/// Usage: wrap a layout of [SkeletonBox]es in a single [AppSkeleton]. One
/// shimmer should sweep a whole screen, not each box independently — see
/// `docs/trips-spec.md` §7.1.
library;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// The resting colour of a placeholder block.
const Color kSkeletonBase = Color(0xFFEFF3F6);

/// The colour of the travelling highlight.
const Color kSkeletonHighlight = Color(0xFFF7F9FB);

const Duration _kSkeletonPeriod = Duration(milliseconds: 1400);

/// Applies the app's shimmer to [child]. Every descendant paints in the
/// shimmer gradient, so build the placeholder layout with plain boxes.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({super.key, required this.child, this.enabled = true});

  final Widget child;

  /// Lets a caller keep the placeholder layout mounted while stopping the
  /// animation (e.g. when a screen goes inactive).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: kSkeletonBase,
      highlightColor: kSkeletonHighlight,
      period: _kSkeletonPeriod,
      enabled: enabled,
      child: child,
    );
  }
}

/// One grey block standing in for content. Place inside an [AppSkeleton].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = 12,
    this.margin,
  });

  final double width;
  final double height;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: kSkeletonBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A [SkeletonBox] rendered as a circle — avatars, icon slots.
class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: kSkeletonBase,
        shape: BoxShape.circle,
      ),
    );
  }
}
