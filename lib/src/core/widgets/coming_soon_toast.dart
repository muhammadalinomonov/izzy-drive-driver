import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';

OverlayEntry? _activeEntry;
Timer? _dismissTimer;

void showComingSoonToast(
  BuildContext context, {
  required String icon,
  required String label,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);

  _dismissTimer?.cancel();
  _activeEntry?.remove();
  _activeEntry = null;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ComingSoonToast(
      icon: icon,
      label: label,
      onDismiss: () {
        if (_activeEntry == entry) {
          _dismissTimer?.cancel();
          _dismissTimer = null;
          _activeEntry?.remove();
          _activeEntry = null;
        }
      },
    ),
  );

  _activeEntry = entry;
  overlay.insert(entry);
}

class _ComingSoonToast extends StatefulWidget {
  const _ComingSoonToast({
    required this.icon,
    required this.label,
    required this.onDismiss,
  });

  final String icon;
  final String label;
  final VoidCallback onDismiss;

  @override
  State<_ComingSoonToast> createState() => _ComingSoonToastState();
}

class _ComingSoonToastState extends State<_ComingSoonToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();
    _autoDismiss = Timer(const Duration(milliseconds: 2600), _dismiss);
  }

  Future<void> _dismiss() async {
    _autoDismiss?.cancel();
    _autoDismiss = null;
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Positioned(
      top: media.padding.top + 8,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragEnd: (details) {
                if ((details.primaryVelocity ?? 0) < -120) _dismiss();
              },
              onTap: _dismiss,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColor.grey2, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColor.lightBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Image.asset(
                        widget.icon,
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.schedule_rounded,
                          color: AppColor.kPrimaryColor,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'comingSoon.title'.tr(
                                    namedArgs: {'feature': widget.label},
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                    height: 1.25,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColor.kPrimary2Color,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Text(
                                  'comingSoon.badge'.tr(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.kPrimaryColor,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'comingSoon.subtitle'.tr(),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColor.grey,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
