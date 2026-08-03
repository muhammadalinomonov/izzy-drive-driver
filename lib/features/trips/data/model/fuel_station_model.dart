import 'package:taxi_app/core/utils/json_safe.dart';
import 'package:taxi_app/features/trips/data/model/place_model.dart';
import 'package:taxi_app/features/trips/data/model/trip_model.dart';

/// A fuel station near the driver.
///
/// The nearby-stations endpoint does not exist yet, so this shape is a
/// forward guess modelled on the toll API's existing conventions: ULID `id`,
/// a `{lat,lng}` coordinate object, and money as minor units plus a currency.
/// [fromJson] is written against that shape so the placeholder repository can
/// be swapped for a real one without touching the UI or the bloc.
class FuelStationModel {
  final String id;
  final String name;
  final String brand;
  final String address;
  final TripCoordinate coordinate;

  /// Straight-line distance from the driver, in metres, as returned by the
  /// backend. The placeholder computes it locally.
  final int distanceMeters;

  /// Per-gallon price range in minor units. Either may be null when the
  /// station publishes a single price or none at all.
  final int? priceMinMinor;
  final int? priceMaxMinor;
  final String currency;

  const FuelStationModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.address,
    required this.coordinate,
    required this.distanceMeters,
    required this.priceMinMinor,
    required this.priceMaxMinor,
    required this.currency,
  });

  factory FuelStationModel.fromJson(Map<String, dynamic> json) {
    final price = toMap(json['price_per_gallon']);
    return FuelStationModel(
      id: toStr(json['id']),
      name: toStr(json['name']),
      brand: toStr(json['brand']),
      address: toStr(json['address']),
      coordinate: TripCoordinate.fromJson(toMap(json['coordinate'])),
      distanceMeters: toInt(json['distance_meters']),
      priceMinMinor: price['min_minor'] == null ? null : toInt(price['min_minor']),
      priceMaxMinor: price['max_minor'] == null ? null : toInt(price['max_minor']),
      currency: toStr(price['currency'], 'USD'),
    );
  }

  /// `$54.54-$60.60 for gallon`, matching the Support page's phrasing, or an
  /// empty string when the station publishes no price.
  String get priceLabel {
    final min = priceMinMinor;
    final max = priceMaxMinor;
    if (min == null && max == null) return '';
    String money(int minor) {
      final value = (minor / 100).toStringAsFixed(2);
      return switch (currency.toUpperCase()) {
        'USD' => '\$$value',
        'EUR' => '€$value',
        final other => '$value $other',
      };
    }

    if (min != null && max != null && min != max) {
      return '${money(min)}-${money(max)}';
    }
    return money(min ?? max!);
  }

  /// Converts the station into the [PlaceModel] the trip flow already speaks,
  /// so selecting one reuses the normal destination path end to end rather
  /// than introducing a parallel route-planning branch.
  PlaceModel toPlace() {
    return PlaceModel(
      id: id,
      name: name.isEmpty ? brand : name,
      displayName: address.isEmpty ? name : address,
      coordinate: coordinate,
      category: 'fuel_station',
    );
  }
}
