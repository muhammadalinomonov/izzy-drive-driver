import 'dart:io';

import 'package:flutter/material.dart';

/// Opens a full-screen, swipeable photo preview. Tap anywhere or hit the X
/// to dismiss; pinch or drag inside an image to zoom / pan.
Future<void> openPhotoPreview(
  BuildContext context, {
  required List<File> photos,
  int initialIndex = 0,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, animation, __) {
        return FadeTransition(
          opacity: animation,
          child: _PhotoPreviewPage(
            photos: photos,
            initialIndex: initialIndex.clamp(0, photos.length - 1),
          ),
        );
      },
    ),
  );
}

class _PhotoPreviewPage extends StatefulWidget {
  const _PhotoPreviewPage({
    required this.photos,
    required this.initialIndex,
  });

  final List<File> photos;
  final int initialIndex;

  @override
  State<_PhotoPreviewPage> createState() => _PhotoPreviewPageState();
}

class _PhotoPreviewPageState extends State<_PhotoPreviewPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _close() {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, i) {
              // Tap a single time (no drag/pinch) → dismiss. Pan/pinch are
              // claimed by InteractiveViewer's ScaleGestureRecognizer once
              // they exceed slop, so taps and zooms cleanly disambiguate.
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _close,
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  clipBehavior: Clip.none,
                  child: Center(
                    child: Image.file(
                      widget.photos[i],
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              );
            },
          ),
          // Close button — always reachable even when an image is zoomed.
          Positioned(
            top: media.padding.top + 8,
            right: 8,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _close,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.close_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
          if (widget.photos.length > 1)
            Positioned(
              top: media.padding.top + 12,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.photos.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}