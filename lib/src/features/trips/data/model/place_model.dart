import 'package:taxi_app/src/core/utils/json_safe.dart';
import 'package:taxi_app/src/features/trips/data/model/trip_model.dart';

/// One geocoded place from `GET mobile/places` (docs/mobile-api.md §3.5).
///
/// Doubles as the persisted "recent location" record - [toJson] round-trips
/// through [RecentPlacesStore], so the shape must stay stable.
class PlaceModel {
  final String id;
  final String name;
  final String displayName;
  final TripCoordinate coordinate;
  final String category;

  const PlaceModel({
    required this.id,
    required this.name,
    required this.displayName,
    required this.coordinate,
    required this.category,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: toStr(json['id']),
      name: toStr(json['name']),
      displayName: toStr(json['display_name']),
      coordinate: TripCoordinate.fromJson(toMap(json['coordinate'])),
      category: toStr(json['category']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'display_name': displayName,
        'coordinate': {'lat': coordinate.lat, 'lng': coordinate.lng},
        'category': category,
      };

  /// Text written into the active field when this place is picked. The API's
  /// `display_name` is the fully-qualified address; `name` alone is ambiguous
  /// (several "Memphis" rows differ only by their display_name).
  String get fieldLabel => displayName.isNotEmpty ? displayName : name;

  /// Secondary line of a suggestion row: the address with the leading title
  /// removed, so "Memphis" + "Memphis, Shelby County, ..." doesn't repeat.
  String get subtitle {
    if (displayName.isEmpty || name.isEmpty) return displayName;
    if (!displayName.startsWith(name)) return displayName;
    return displayName.substring(name.length).replaceFirst(RegExp(r'^,\s*'), '');
  }

  /// A synthetic place for a raw GPS fix, which has no API id.
  factory PlaceModel.fromCoordinate({
    required String label,
    required double lat,
    required double lng,
  }) {
    return PlaceModel(
      id: 'gps_${lat.toStringAsFixed(5)}_${lng.toStringAsFixed(5)}',
      name: label,
      displayName: label,
      coordinate: TripCoordinate(lat: lat, lng: lng),
      category: 'gps',
    );
  }
}
