import 'dart:convert';
import 'dart:developer';

import 'package:taxi_app/core/network/token_service.dart';
import 'package:taxi_app/core/utils/json_safe.dart';
import 'package:taxi_app/features/trips/data/model/place_model.dart';

/// Locally persisted "recent locations" for the trip-planning sheet.
///
/// The toll API has no search-history endpoint - `mobile/places` is a pure
/// geocoder - so the list shown when nothing is focused is built from what the
/// driver has previously picked on this device.
class RecentPlacesStore {
  RecentPlacesStore._();

  static const String _key = 'trip_recent_places';
  static const int maxEntries = 8;

  static List<PlaceModel> load() {
    final raw = StorageRepository.getString(_key);
    if (raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      return toList(decoded, (e) => PlaceModel.fromJson(toMap(e)));
    } catch (e) {
      log('RecentPlacesStore: unreadable payload, dropping - $e');
      return const [];
    }
  }

  /// Moves [place] to the front, de-duplicating on the geocoder id so the same
  /// place picked twice doesn't occupy two rows.
  static Future<List<PlaceModel>> add(PlaceModel place) async {
    final current = load();
    final next = <PlaceModel>[
      place,
      ...current.where((p) => p.id != place.id),
    ];
    final trimmed = next.take(maxEntries).toList();
    await StorageRepository.putString(
      _key,
      jsonEncode(trimmed.map((p) => p.toJson()).toList()),
    );
    return trimmed;
  }

  static Future<void> clear() async {
    await StorageRepository.deleteString(_key);
  }
}
