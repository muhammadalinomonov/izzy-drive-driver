import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/core/utils/unit_format.dart';

/// The Driving Mode information bar, built to `docs/ui/info-bar.svg`.
///
/// Two rows split by a full-bleed divider: the destination address above, and
/// distance / arrival clock / time-remaining below, over a route progress bar.
///
/// The bar fills with colour as the trip progresses - empty at the start,
/// complete on arrival - with an arrow head marking the vehicle at the leading
/// edge. The gradient is anchored across the whole route, so the colour that
/// appears behind the arrow depends on how far along it is.
class TripInfoBar extends StatelessWidget {
  const TripInfoBar({
    super.key,
    required this.destinationLabel,
    required this.remainingMeters,
    required this.remainingSeconds,
    required this.percent,
  });

  final String destinationLabel;
  final int remainingMeters;
  final int remainingSeconds;

  /// Route completion, 0-100, straight from the session's progress.
  final double percent;

  // Geometry transcribed from the SVG (349x83 artboard).
  static const double _radius = 12;
  static const double _rowOneHeight = 34.5;
  static const double _barHeight = 8;

  /// Clock time the driver is expected to arrive. `DateFormat.Hm` is the
  /// 24-hour `HH:mm` the design shows, and stays 24-hour across locales.
  String get _arrivalClock {
    final arrival = DateTime.now().add(Duration(seconds: remainingSeconds));
    return DateFormat.Hm().format(arrival);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: const Color(0xFFE3E8EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _rowOneHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: Text(
                  destinationLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF43484B),
                  ),
                ),
              ),
            ),
          ),
          // Full-bleed, matching the SVG's edge-to-edge divider.
          const Divider(height: 1, thickness: 1, color: Color(0xFFE3E8EB)),
          // Spacing solved against the SVG rather than eyeballed: row one is
          // 34.5 + a 1px divider, the stat text is 16 tall, and the arrow band
          // is 17.7 with the 8px bar centred in it. 6 / 4 / 4 puts the bar's
          // top at y=66.35 and the card at 83.2 - the artboard's 66 and 83.
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 6, 13, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    formatMiles(remainingMeters),
                    textAlign: TextAlign.left,
                    style: _statStyle,
                  ),
                ),
                Expanded(
                  child: Text(
                    _arrivalClock,
                    textAlign: TextAlign.center,
                    style: _statStyle,
                  ),
                ),
                Expanded(
                  child: Text(
                    formatDuration(remainingSeconds),
                    textAlign: TextAlign.right,
                    style: _statStyle,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            // Asymmetric inset (19 left, 12 right) is the artboard's, leaving
            // room for the arrow to overhang the track's start.
            padding: const EdgeInsets.fromLTRB(19, 4, 12, 4),
            child: _RouteProgressBar(
              fraction: (percent / 100).clamp(0.0, 1.0),
              height: _barHeight,
            ),
          ),
        ],
      ),
    );
  }

  static const TextStyle _statStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Color(0xFF01060F),
    height: 1,
  );
}

/// Route progress bar: an empty track that fills with colour as the driver
/// covers ground, with an arrow head riding the leading edge.
class _RouteProgressBar extends StatelessWidget {
  const _RouteProgressBar({required this.fraction, required this.height});

  final double fraction;
  final double height;

  /// Stops transcribed from the SVG gradient, mirrored: the export runs red at
  /// the right-hand origin through amber at 51.4% to green, so left-to-right
  /// is green -> amber -> red.
  static const List<Color> _trackColors = [
    Color(0xFF00A911),
    Color(0xFFF1BC1D),
    Color(0xFFFF0000),
  ];
  static const List<double> _trackStops = [0.0, 0.485577, 1.0];

  /// Arrow footprint from the SVG: ~21.6 x 17.7, so it overhangs the 8px bar
  /// top and bottom.
  static const double _arrowWidth = 21.6;
  static const double _arrowHeight = 17.7;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final driven = (width * fraction).clamp(0.0, width);

        return SizedBox(
          height: _arrowHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              // Empty track. The bar starts blank and fills as the driver
              // covers ground, rather than starting full and draining.
              Container(
                height: height,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E8EB),
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
              // Driven portion, in colour.
              //
              // The gradient is laid out across the *full* track and then
              // clipped to the driven width, so each colour stays pinned to
              // its point on the route. Sizing the gradient to the driven
              // width instead would squeeze the whole green-amber-red spectrum
              // into the first few pixels and re-stretch it on every fix.
              if (driven > 0)
                ClipRRect(
                  borderRadius: BorderRadius.circular(height / 2),
                  child: SizedBox(
                    width: driven,
                    height: height,
                    child: OverflowBox(
                      alignment: Alignment.centerLeft,
                      minWidth: width,
                      maxWidth: width,
                      child: Container(
                        height: height,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: _trackColors,
                            stops: _trackStops,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Vehicle marker, centred on the boundary between the two.
              Positioned(
                left: (driven - _arrowWidth / 2).clamp(
                  -_arrowWidth / 2,
                  width - _arrowWidth / 2,
                ),
                child: const _ProgressArrow(
                  width: _arrowWidth,
                  height: _arrowHeight,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressArrow extends StatelessWidget {
  const _ProgressArrow({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _ArrowPainter()),
    );
  }
}

/// Right-pointing arrow head: swept-back wings with a concave rear, filled
/// with the SVG's blue-to-indigo gradient and outlined in white so it stays
/// legible wherever it sits on the coloured track.
class _ArrowPainter extends CustomPainter {
  static const Color _from = Color(0xFF0078FF);
  static const Color _to = Color(0xFF443599);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w, h / 2) // tip
      ..lineTo(0, 0) // upper wing
      ..lineTo(w * 0.34, h / 2) // rear notch
      ..lineTo(0, h) // lower wing
      ..close();

    final rect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [_from, _to],
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
        ).createShader(rect),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.75
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) => false;
}
