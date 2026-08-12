import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_app/features/trips/data/model/fuel_station_model.dart';

/// Parsing rules for `GET mobile/fuel-stations` (docs/mobile-api.md §7).
///
/// The payload below is the exact response sample from §7.1, so a contract
/// change shows up here rather than as a blank marker sheet on a truck.
void main() {
  /// §7.1 sample item, verbatim.
  const itemJson = '''
  {
    "id": "01K1FUELSTATION00000000001",
    "source": "efs",
    "external_id": "1006",
    "name": "PILOT TRAVEL CENTER #123",
    "brand": "Pilot",
    "chain_id": "12",
    "address1": "1000 W Interstate 40",
    "address2": null,
    "city": "Nashville",
    "state": "TN",
    "zip": "37209",
    "country": "USA",
    "phone": "615-555-0100",
    "latitude": "36.162700",
    "longitude": "-86.781600",
    "open_24h": true,
    "amenities": [12, 31],
    "is_active": true,
    "source_updated_at": "2026-08-08T17:59:12Z",
    "latest_prices": [
      {
        "id": "01K1FUELPRICE0000000000001",
        "tax_included": false,
        "price_per_gallon": "3.459",
        "currency": "USD",
        "observed_at": "2026-08-08T17:59:12Z"
      }
    ]
  }
  ''';

  FuelStationModel parse([String json = itemJson]) =>
      FuelStationModel.fromJson(jsonDecode(json) as Map<String, dynamic>);

  group('FuelStationModel', () {
    test('parses the documented catalogue item', () {
      final station = parse();
      expect(station.id, '01K1FUELSTATION00000000001');
      expect(station.title, 'PILOT TRAVEL CENTER #123');
      expect(station.brand, 'Pilot');
      expect(station.open24h, isTrue);
      expect(station.amenities, [12, 31]);
    });

    test('coordinates arrive as strings and become numbers', () {
      final station = parse();
      expect(station.coordinate.lat, closeTo(36.1627, 1e-6));
      expect(station.coordinate.lng, closeTo(-86.7816, 1e-6));
    });

    test('address is composed from the parts, skipping a null address2', () {
      expect(
        parse().address,
        '1000 W Interstate 40, Nashville, TN 37209',
      );
    });

    test('price stays a major-unit decimal - never divided by 100', () {
      final price = parse().primaryPrice!;
      expect(price.pricePerGallon, '3.459');
      expect(price.formatted, r'$3.459');
      expect(price.amount, closeTo(3.459, 1e-9));
      expect(price.taxIncluded, isFalse);
    });

    test('leads with the tax-excluded rate and compares the other', () {
      final station = parse(itemJson.replaceFirst(
        '"latest_prices": [',
        '''"latest_prices": [
          {
            "id": "p2",
            "tax_included": true,
            "price_per_gallon": "3.899",
            "currency": "USD",
            "observed_at": "2026-08-08T17:59:12Z"
          },''',
      ));
      expect(station.primaryPrice!.taxIncluded, isFalse);
      expect(station.primaryPrice!.pricePerGallon, '3.459');
      expect(station.secondaryPrice!.pricePerGallon, '3.899');
    });

    test('an empty latest_prices is a valid station, not an error', () {
      final station = parse(
        itemJson.replaceFirst(RegExp(r'"latest_prices": \[[\s\S]*\]'),
            '"latest_prices": []'),
      );
      expect(station.latestPrices, isEmpty);
      expect(station.primaryPrice, isNull);
      expect(station.secondaryPrice, isNull);
      expect(station.priceLabel, '');
      // Still mappable to a destination - a priceless station is still a stop.
      expect(station.toPlace().coordinate.lat, closeTo(36.1627, 1e-6));
    });

    test('distance is absent until measured against a location', () {
      expect(parse().distanceMeters, isNull);
      expect(parse().withDistance(1800).distanceMeters, 1800);
    });

    test('toPlace carries the address as the field label', () {
      final place = parse().toPlace();
      expect(place.category, 'fuel_station');
      expect(place.fieldLabel, '1000 W Interstate 40, Nashville, TN 37209');
    });
  });
}
