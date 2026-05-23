import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/common_image.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/bloc/orders_bloc.dart';

const Color _kBg = Color(0xFFEFF3F6);
const Color _kBorder = Color(0xFFE3E8EB);
const Color _kSubtitle = Color(0xFF6B7073);
const Color _kMuted = Color(0xFF93989B);
const Color _kPrimary = Color(0xFF0866FF);

/// "Mexanik javobini kutmoqdamiz" bottom sheet - Figma frame 14534:11949
/// dizayniga moslangan. Avatar atrofida konsentrik pulse + tipa kichik dot
/// animatsiyalari + pastda aylana Cancel tugma (icon + matn).
class AwaitingMechanicSheet extends StatefulWidget {
  const AwaitingMechanicSheet({
    super.key,
    required this.mechanicName,
    required this.mechanicPhoto,
    required this.onCancel,
  });

  final String mechanicName;
  final String? mechanicPhoto;
  final VoidCallback onCancel;

  @override
  State<AwaitingMechanicSheet> createState() => _AwaitingMechanicSheetState();
}

class _AwaitingMechanicSheetState extends State<AwaitingMechanicSheet>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _dotsController;
  late final AnimationController _stripController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _stripController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _dotsController.dispose();
    _stripController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle (vizual).
            Container(
              width: 43,
              height: 4,
              decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(540),
              ),
            ),
            const SizedBox(height: 16),
            // Tepada yumshoq indeterminate progress strip.
            _ProgressStrip(controller: _stripController),
            const SizedBox(height: 22),
            // Avatar + pulse rings.
            _PulseAvatar(
              controller: _pulseController,
              imageUrl: widget.mechanicPhoto,
              name: widget.mechanicName,
            ),
            const SizedBox(height: 22),
            Text(
              widget.mechanicName.isEmpty
                  ? 'Master selected'.tr()
                  : widget.mechanicName,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                letterSpacing: -0.30,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Waiting for the master to accept'.tr(),
                  style: const TextStyle(
                    color: _kSubtitle,
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.30,
                  ),
                ),
                const SizedBox(width: 6),
                _TypingDots(controller: _dotsController),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Usually responds within 30–60 seconds'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _kMuted,
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                letterSpacing: -0.30,
              ),
            ),
            const SizedBox(height: 18),
            // Aylana Cancel tugmasi (X icon) + matn pastda - Figma'dagidek.
            _CircleCancelButton(onTap: widget.onCancel),
          ],
        ),
      ),
    );
  }
}

/// 3 ta konsentrik halqa avatar atrofida tarqaladi.
class _PulseAvatar extends StatelessWidget {
  const _PulseAvatar({
    required this.controller,
    required this.imageUrl,
    required this.name,
  });

  final AnimationController controller;
  final String? imageUrl;
  final String name;

  static const double _avatarSize = 64;
  static const double _maxRingSize = 152;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _maxRingSize,
      height: _maxRingSize,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              for (int i = 0; i < 3; i++)
                _pulseRing((controller.value + i / 3) % 1.0),
              ClipOval(
                child: SizedBox(
                  width: _avatarSize,
                  height: _avatarSize,
                  child: AvatarImage(
                    imageUrl: imageUrl,
                    name: name,
                    size: _avatarSize,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _pulseRing(double t) {
    final size = _avatarSize + (_maxRingSize - _avatarSize) * t;
    final opacity = (1 - t) * 0.5;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _kPrimary.withValues(alpha: opacity),
          width: 2,
        ),
      ),
    );
  }
}

class _TypingDots extends StatelessWidget {
  const _TypingDots({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (controller.value + i * 0.2) % 1.0;
            final t = (phase < 0.5 ? phase * 2 : (1 - phase) * 2).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: _kSubtitle.withValues(alpha: 0.3 + t * 0.7),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: SizedBox(
        height: 4,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final stripWidth = constraints.maxWidth * 0.35;
                final left = (constraints.maxWidth + stripWidth) * controller.value -
                    stripWidth;
                return Stack(
                  children: [
                    Container(color: _kPrimary.withValues(alpha: 0.08)),
                    Positioned(
                      left: left,
                      top: 0,
                      bottom: 0,
                      width: stripWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _kPrimary,
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CircleCancelButton extends StatelessWidget {
  const _CircleCancelButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: _kBg,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.close, size: 22, color: Colors.black),
            ),
          ),
        ),
        const SizedBox(height: 9),
        Text(
          'Cancel'.tr(),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            letterSpacing: -0.30,
          ),
        ),
      ],
    );
  }
}

/// Connector - `OrdersBloc`'dan mexanik ma'lumotlarini avtomatik oladi.
class AwaitingMechanicSheetConnector extends StatelessWidget {
  const AwaitingMechanicSheetConnector({super.key, required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      buildWhen: (p, c) =>
          p.currentOrder.selectedMechanic != c.currentOrder.selectedMechanic ||
          p.currentOrder.mechanicInfo != c.currentOrder.mechanicInfo,
      builder: (context, state) {
        final selected = state.currentOrder.selectedMechanic;
        final fallback = state.currentOrder.mechanicInfo;
        final name = selected.mechanicName.isNotEmpty
            ? selected.mechanicName
            : (fallback.mechanicName.isNotEmpty
                ? fallback.mechanicName
                : selected.fullName);
        final photo = selected.photo.isNotEmpty
            ? selected.photo
            : fallback.photo;
        return AwaitingMechanicSheet(
          mechanicName: name,
          mechanicPhoto: photo.isEmpty ? null : photo,
          onCancel: onCancel,
        );
      },
    );
  }
}
