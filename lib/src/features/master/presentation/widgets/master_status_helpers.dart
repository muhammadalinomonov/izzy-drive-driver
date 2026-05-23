import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/features/master/data/model/master_model.dart';

// Backend status enum: 'online' | 'offline' | 'onwork' (see usta/mechanic/
// models.py). Per product, `onwork` (mechanic on a job) is presented to the
// driver as "Online" — they're still active in the system; the busy nuance
// is internal. `busy` kept as a legacy alias.
bool _isAvailable(String normalized) =>
    normalized == 'online' || normalized == 'onwork' || normalized == 'busy';

String masterStatusLabel(String? status) {
  final normalized = (status ?? '').toLowerCase();
  if (_isAvailable(normalized)) return 'Online'.tr();
  return 'Offline'.tr();
}

Color masterStatusColor(String? status) {
  final normalized = (status ?? '').toLowerCase();
  if (_isAvailable(normalized)) return AppColor.kPrimaryColor;
  return AppColor.grey;
}

/// Picks the best distance source from the model and formats it for display.
/// Distance is computed on the backend (driver_lat/driver_long are sent on
/// every request) — the client just renders.
String masterDistanceLabel(MasterModel m) {
  // Coordinate presence is a "do we know where the mechanic is" signal. The
  // detail endpoint sends lat/long; the list endpoint also sends them now,
  // but if a stale build still serves the old list shape we fall back to
  // "do we have any non-zero distance value" before giving up with "—".
  final hasCoords = m.latitude != 0 || m.longitude != 0;
  final fromStringKm = double.tryParse(m.distanceKm ?? '') ?? 0;
  final km = m.distance > 0
      ? m.distance
      : (m.map.distanceKm > 0 ? m.map.distanceKm : fromStringKm);
  if (!hasCoords && km <= 0) return '-';
  if (km <= 0) return 'Nearby'.tr();
  if (km < 1) return '${(km * 1000).round()} ${'m away'.tr()}';
  return '${km.toStringAsFixed(1)} ${'km away'.tr()}';
}

class MasterStatusPill extends StatelessWidget {
  const MasterStatusPill({super.key, required this.status, this.compact = false});

  final String? status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = masterStatusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 2 : 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: compact ? 4 : 5),
          Text(
            masterStatusLabel(status),
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
