import 'package:taxi_app/core/utils/json_safe.dart';
import 'package:taxi_app/features/trips/data/model/place_model.dart';
import 'package:taxi_app/features/trips/data/model/trip_model.dart';

/// One contracted fuel price observation from `latest_prices` (docs §7.1).
///
/// [pricePerGallon] is deliberately kept as the raw decimal **string** the
/// backend sends (`"3.459"`). Per docs §7.2 this is a major-unit value, unlike
/// every other money field in this API, which arrives as `amount_minor` - so it
/// must never travel through the `/100` conversion the rest of the app uses.
/// [amount] parses it once for comparisons.
class FuelStationPrice {
  /// True when the quoted price already contains tax. The backend neither adds
  /// nor removes tax, so this is a label, not a modifier.
  final bool taxIncluded;
  final String pricePerGallon;
  final String currency;
  final DateTime? observedAt;

  const FuelStationPrice({
    required this.taxIncluded,
    required this.pricePerGallon,
    required this.currency,
    this.observedAt,
  });

  factory FuelStationPrice.fromJson(Map<String, dynamic> json) {
    return FuelStationPrice(
      taxIncluded: toBool(json['tax_included']),
      pricePerGallon: toStr(json['price_per_gallon']),
      currency: toStr(json['currency'], 'USD'),
      observedAt: DateTime.tryParse(toStr(json['observed_at'])),
    );
  }

  double? get amount => double.tryParse(pricePerGallon);

  /// `$3.459`, keeping every decimal the backend published - fuel is priced to
  /// three places and rounding to two would misstate the contracted rate.
  String get formatted {
    if (pricePerGallon.isEmpty) return '';
    return switch (currency.toUpperCase()) {
      'USD' => '\$$pricePerGallon',
      'EUR' => '€$pricePerGallon',
      final other => '$pricePerGallon $other',
    };
  }
}

/// A fuel station from `GET mobile/fuel-stations` (docs/mobile-api.md §7.1).
///
/// The catalogue is EFS-only, active-only and global; it carries no
/// company-specific card or contract data, and there is no detail endpoint -
/// the list row IS the full record, which is why the marker sheet renders
/// straight from this model.
class FuelStationModel {
  final String id;
  final String source;
  final String externalId;
  final String name;
  final String brand;

  final String address1;
  final String address2;
  final String city;
  final String state;
  final String zip;
  final String country;
  final String phone;

  final TripCoordinate coordinate;
  final bool open24h;

  /// Raw amenity codes. Left unmapped on purpose (docs §7.2): without an
  /// agreed code table a guessed label would be wrong more often than not.
  final List<int> amenities;

  /// Most recent price per tax variant. May be empty - a station with no
  /// published price is still a valid station and still gets a marker.
  final List<FuelStationPrice> latestPrices;

  /// Great-circle distance from the driver, in metres.
  ///
  /// Not part of the API response: the catalogue is a bounding-box query and
  /// returns no distance, so the data source fills this in from the driver's
  /// current location. Null means "not measured against a location".
  final int? distanceMeters;

  const FuelStationModel({
    required this.id,
    required this.source,
    required this.externalId,
    required this.name,
    required this.brand,
    required this.address1,
    required this.address2,
    required this.city,
    required this.state,
    required this.zip,
    required this.country,
    required this.phone,
    required this.coordinate,
    required this.open24h,
    required this.amenities,
    required this.latestPrices,
    this.distanceMeters,
  });

  factory FuelStationModel.fromJson(Map<String, dynamic> json) {
    return FuelStationModel(
      id: toStr(json['id']),
      source: toStr(json['source']),
      externalId: toStr(json['external_id']),
      name: toStr(json['name']),
      brand: toStr(json['brand']),
      address1: toStr(json['address1']),
      address2: toStr(json['address2']),
      city: toStr(json['city']),
      state: toStr(json['state']),
      zip: toStr(json['zip']),
      country: toStr(json['country']),
      phone: toStr(json['phone']),
      // Coordinates ship as 6-decimal strings, not numbers (docs §7.2).
      coordinate: TripCoordinate(
        lat: toDouble(json['latitude']),
        lng: toDouble(json['longitude']),
      ),
      open24h: toBool(json['open_24h']),
      amenities: toList(json['amenities'], (e) => toInt(e)),
      latestPrices: toList(
        json['latest_prices'],
        (e) => FuelStationPrice.fromJson(toMap(e)),
      ),
    );
  }

  FuelStationModel withDistance(int meters) {
    return FuelStationModel(
      id: id,
      source: source,
      externalId: externalId,
      name: name,
      brand: brand,
      address1: address1,
      address2: address2,
      city: city,
      state: state,
      zip: zip,
      country: country,
      phone: phone,
      coordinate: coordinate,
      open24h: open24h,
      amenities: amenities,
      latestPrices: latestPrices,
      distanceMeters: meters,
    );
  }

  /// Title for the marker sheet and list rows. `name` is guaranteed non-empty
  /// by the endpoint's own filter, but brand is a sane fallback regardless.
  String get title => name.isNotEmpty ? name : brand;

  /// `1000 W Interstate 40, Nashville, TN 37209` - built from the parts, since
  /// the catalogue has no pre-joined address field.
  String get address {
    final street = [address1, address2].where((p) => p.isNotEmpty).join(' ');
    final locality = [
      city,
      [state, zip].where((p) => p.isNotEmpty).join(' '),
    ].where((p) => p.isNotEmpty).join(', ');
    return [street, locality].where((p) => p.isNotEmpty).join(', ');
  }

  /// The price to lead with: tax-excluded when both variants are present,
  /// because that is the contracted rate the driver's card is billed at.
  FuelStationPrice? get primaryPrice {
    if (latestPrices.isEmpty) return null;
    for (final price in latestPrices) {
      if (!price.taxIncluded) return price;
    }
    return latestPrices.first;
  }

  /// The other tax variant, when the station published both. Shown beside
  /// [primaryPrice] as the struck-through comparison in the design.
  FuelStationPrice? get secondaryPrice {
    final primary = primaryPrice;
    if (primary == null) return null;
    for (final price in latestPrices) {
      if (price.taxIncluded != primary.taxIncluded) return price;
    }
    return null;
  }

  /// Formatted contracted price, or an empty string when the station publishes
  /// none - a normal state per docs §7.2, rendered as "Not available".
  String get priceLabel => primaryPrice?.formatted ?? '';

  /// Converts the station into the [PlaceModel] the trip flow already speaks,
  /// so routing to one reuses the normal destination path end to end rather
  /// than introducing a parallel route-planning branch.
  PlaceModel toPlace() {
    return PlaceModel(
      id: id,
      name: title,
      displayName: address.isEmpty ? title : address,
      coordinate: coordinate,
      category: 'fuel_station',
    );
  }
}
