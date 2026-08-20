import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_app/features/trips/data/model/place_model.dart';
import 'package:taxi_app/features/trips/data/model/route_support_model.dart';
import 'package:taxi_app/features/trips/data/model/support_chat_model.dart';
import 'package:taxi_app/features/trips/data/model/trip_model.dart';

/// Parsing rules for support chat (docs/mobile-api.md §8) - both the normal
/// conversation and the route-review thread share the message shape, and the
/// sample payloads below are the exact ones from the doc.
void main() {
  group('SupportChatMessage', () {
    test('parses the §8.1 sample message', () {
      const json = '''
      {
        "id": "01K0SUPPORTMESSAGE000000002",
        "sender_type": "support",
        "sender_name": "Fleet Dispatcher",
        "message": "Yes, support is available.",
        "route_review_id": null,
        "created_at": "2026-07-29T14:06:00+00:00"
      }
      ''';
      final message =
          SupportChatMessage.fromJson(jsonDecode(json) as Map<String, dynamic>);
      expect(message.id, '01K0SUPPORTMESSAGE000000002');
      expect(message.isDriver, isFalse);
      expect(message.senderName, 'Fleet Dispatcher');
      expect(message.message, 'Yes, support is available.');
      expect(message.routeReviewId, isNull);
    });

    test('sender_type "driver" sets isDriver, everything else does not', () {
      Map<String, dynamic> withSender(String type) => {
            'id': 'x',
            'sender_type': type,
            'message': 'hi',
          };
      expect(SupportChatMessage.fromJson(withSender('driver')).isDriver, isTrue);
      expect(SupportChatMessage.fromJson(withSender('support')).isDriver, isFalse);
      expect(SupportChatMessage.fromJson(withSender('')).isDriver, isFalse);
    });

    test('a route-review message keeps its route_review_id', () {
      const json = '''
      {
        "id": "01K0SUPPORTMESSAGE000000001",
        "sender_type": "driver",
        "sender_name": "Alex Driver",
        "message": "Please review this route.",
        "route_review_id": "01K0ROUTEREVIEW00000000000",
        "created_at": "2026-07-29T13:59:00+00:00"
      }
      ''';
      final message =
          SupportChatMessage.fromJson(jsonDecode(json) as Map<String, dynamic>);
      expect(message.routeReviewId, '01K0ROUTEREVIEW00000000000');
      expect(message.isDriver, isTrue);
    });

    test('a missing sender_name degrades to empty, not a crash', () {
      final message = SupportChatMessage.fromJson({
        'id': 'x',
        'sender_type': 'support',
        'message': 'hi',
      });
      expect(message.senderName, '');
    });
  });

  group('SupportChatPage', () {
    test('parses the §8.1 sample page, newest-first as documented', () {
      final data = {
        'conversation': {'id': '01K0SUPPORTCHAT00000000000'},
        'items': [
          {
            'id': '01K0SUPPORTMESSAGE000000002',
            'sender_type': 'support',
            'message': 'Yes, support is available.',
          },
          {
            'id': '01K0SUPPORTMESSAGE000000001',
            'sender_type': 'driver',
            'message': 'I need help.',
          },
        ],
      };
      final pagination = {'page': 1, 'per_page': 50, 'total': 2, 'last_page': 1};

      final page = SupportChatPage.fromJson(data, pagination);
      expect(page.items, hasLength(2));
      expect(page.items.first.id, '01K0SUPPORTMESSAGE000000002');
      expect(page.total, 2);
    });

    test('an empty conversation parses to an empty page, not an error', () {
      final page = SupportChatPage.fromJson(
        {'conversation': null, 'items': []},
        {'page': 1, 'per_page': 50, 'total': 0, 'last_page': 1},
      );
      expect(page.items, isEmpty);
    });
  });

  group('RouteReviewDetail', () {
    test('parses the §4.2/§8.3 sample review fragment, oldest-first', () {
      const json = '''
      {
        "id": "01K0ROUTEREVIEW00000000000",
        "status": "approved",
        "messages": [
          {
            "id": "01K0SUPPORTMESSAGE000000001",
            "sender_type": "driver",
            "sender_name": "Alex Driver",
            "message": "Please review this route.",
            "route_review_id": "01K0ROUTEREVIEW00000000000",
            "created_at": "2026-07-29T13:59:00+00:00"
          },
          {
            "id": "01K0SUPPORTMESSAGE000000002",
            "sender_type": "support",
            "sender_name": "Fleet Dispatcher",
            "message": "Route approved.",
            "route_review_id": "01K0ROUTEREVIEW00000000000",
            "created_at": "2026-07-29T14:03:00+00:00"
          }
        ]
      }
      ''';
      final thread =
          RouteReviewDetail.fromJson(jsonDecode(json) as Map<String, dynamic>);
      expect(thread.id, '01K0ROUTEREVIEW00000000000');
      expect(thread.messages, hasLength(2));
      // Oldest first: the driver's opening message leads.
      expect(thread.messages.first.isDriver, isTrue);
      expect(thread.messages.last.isDriver, isFalse);
    });

    test('a freshly created review with no messages yet parses cleanly', () {
      final thread = RouteReviewDetail.fromJson({
        'id': '01K0ROUTEREVIEW00000000001',
        'status': 'pending',
      });
      expect(thread.messages, isEmpty);
      expect(thread.status, RouteReviewStatus.pending);
      expect(thread.canStartDrive, isFalse);
      expect(thread.activeAlternative, isNull);
    });

    test('parses the §4.2 detail: route, alternatives, fuel, can_drive', () {
      final review = RouteReviewDetail.fromJson(
        jsonDecode(_alternativeSuggestedReview) as Map<String, dynamic>,
      );

      expect(review.status, RouteReviewStatus.alternativeSuggested);
      expect(review.initiator, 'driver');
      expect(review.canDrive, isTrue);
      // `route.id`, not a flat `route_request_id` - it is what a navigation
      // session is started with.
      expect(review.routeRequestId, '01K0ROUTEREQUEST0000000000');
      expect(review.destination?.lng, 19.456);
      expect(review.decisionNote, 'Please take Alternative 2.');

      final approved = review.approvedAlternative;
      expect(approved?.id, '01K0ALTERNATIVE200000000000');
      expect(approved?.toll?.amountMinor, 20500);
      // Minor units: 20500 USD is \$205.00 (§4.2).
      expect(approved?.total?.formatted, r'$1410.00');
    });

    test('an approved alternative wins the card over a proposed one', () {
      final review = RouteReviewDetail.fromJson(
        jsonDecode(_alternativeSuggestedReview) as Map<String, dynamic>,
      );
      expect(review.activeAlternative?.id, '01K0ALTERNATIVE200000000000');
      // can_drive AND an approved alternative - both are required (§4.3).
      expect(review.canStartDrive, isTrue);
    });

    test('a pending review shows what the driver asked about, no Drive', () {
      final review = RouteReviewDetail.fromJson({
        'id': 'r1',
        'status': 'pending',
        'can_drive': false,
        'requested_alternative': {'id': 'req-1'},
      });
      expect(review.activeAlternative?.id, 'req-1');
      expect(review.canStartDrive, isFalse);
    });

    test('a suggestion not yet approved falls back to the proposal', () {
      final review = RouteReviewDetail.fromJson({
        'id': 'r1',
        'status': 'alternative_suggested',
        'can_drive': false,
        'requested_alternative': {'id': 'req-1'},
        'proposed_alternative': {'id': 'prop-1'},
      });
      expect(review.activeAlternative?.id, 'prop-1');
      expect(review.canStartDrive, isFalse);
    });

    test('declined keeps the requested card and hides Drive', () {
      final review = RouteReviewDetail.fromJson({
        'id': 'r1',
        'status': 'declined',
        // Even a stale can_drive + approved pair must not offer Drive on a
        // closed review.
        'can_drive': true,
        'requested_alternative': {'id': 'req-1'},
        'approved_alternative': {'id': 'appr-1'},
      });
      expect(review.activeAlternative?.id, 'req-1');
      expect(review.status.isClosed, isTrue);
      expect(review.canStartDrive, isFalse);
    });

    test('an unknown status degrades to open rather than closed', () {
      final review = RouteReviewDetail.fromJson({
        'id': 'r1',
        'status': 'under_dispute',
        'requested_alternative': {'id': 'req-1'},
      });
      expect(review.status, RouteReviewStatus.unknown);
      expect(review.status.isClosed, isFalse);
      expect(review.activeAlternative?.id, 'req-1');
    });
  });

  group('RouteReviewFuelRecommendation', () {
    test('parses the §5 card shape', () {
      final review = RouteReviewDetail.fromJson(
        jsonDecode(_alternativeSuggestedReview) as Map<String, dynamic>,
      );
      final fuel = review.fuelRecommendations.single;

      expect(fuel.id, '01K0FUELRECOMMENDATION0000');
      expect(fuel.stationName, 'Alixon Fuel');
      expect(fuel.confirmed, isFalse);
      expect(review.confirmedFuelStops, isEmpty);
      // Three decimals are kept verbatim - rounding would misquote the price
      // the driver is promised.
      expect(fuel.priceText, r'$3.459');
      expect(fuel.distanceMiles, closeTo(24.0, 0.1));
      // Address wins over the station name for the stop row's label.
      expect(fuel.title, '3301 Kuhn Rd, West Memphis, AR 72301');
    });

    test('a fuel stop becomes a card row carrying its confirmed flag', () {
      final review = RouteReviewDetail.fromJson({
        'id': 'r1',
        'status': 'approved',
        'can_drive': true,
        'approved_alternative': {
          'id': 'appr-1',
          'distance_meters': 160934,
          'costs': {
            'toll': {'amount_minor': 1000, 'currency': 'USD'},
            'fuel': {'amount_minor': 2000, 'currency': 'USD'},
          },
          'toll_markers': [
            {'id': 'm1', 'name': 'Gantry 1', 'amount': {'amount_minor': 3400, 'currency': 'USD'}},
          ],
        },
        'fuel_recommendations': [
          {'id': 'f1', 'station_name': 'Alixon Fuel', 'confirmed': true},
        ],
      });

      final card = review.cardFor(
        originLabel: 'Memphis',
        destinationLabel: 'Lodz',
        perGallonNote: 'for gallon',
      );

      expect(card.originLabel, 'Memphis');
      // Toll gantries first, then the fuel stops.
      expect(card.stops.map((s) => s.kind), [
        RouteSupportStopKind.toll,
        RouteSupportStopKind.fuel,
      ]);
      expect(card.stops.first.priceText, r'-$34.00');
      expect(card.stops.last.confirmed, isTrue);
      expect(card.summary?.distance, '100 mi');
    });
  });

  group('RouteSupportRequest.toCreateReviewJson', () {
    test('omits message when none is given', () {
      final json = _sampleRequest().toCreateReviewJson();
      expect(json['route_request_id'], 'route-1');
      expect(json['route_alternative_id'], 'alt-1');
      expect(json.containsKey('message'), isFalse);
    });

    test('includes a trimmed message when one is given', () {
      final json =
          _sampleRequest().toCreateReviewJson(message: '  please check  ');
      expect(json['message'], 'please check');
    });

    test('omits a message that is only whitespace', () {
      final json = _sampleRequest().toCreateReviewJson(message: '   ');
      expect(json.containsKey('message'), isFalse);
    });
  });
}

RouteSupportRequest _sampleRequest() {
  return RouteSupportRequest(
    routeId: 'route-1',
    alternativeId: 'alt-1',
    alternativeLabel: 'Recommended',
    origin: _place(39.9526, -75.1652, 'Philadelphia'),
    destination: _place(40.7128, -74.006, 'New York'),
    distanceMeters: 151200,
    durationSeconds: 7200,
  );
}

PlaceModel _place(double lat, double lng, String name) {
  return PlaceModel(
    id: name,
    name: name,
    displayName: name,
    coordinate: TripCoordinate(lat: lat, lng: lng),
    category: 'city',
  );
}

/// The §4.2 sample: the driver's route was reviewed, the dispatcher approved a
/// different alternative and attached a fuel stop.
const String _alternativeSuggestedReview = '''
{
  "id": "01K0ROUTEREVIEW00000000000",
  "status": "alternative_suggested",
  "initiator": "driver",
  "can_drive": true,
  "route": {
    "id": "01K0ROUTEREQUEST0000000000",
    "origin": { "lat": 35.1465, "lng": -90.1845 },
    "destination": { "lat": 51.7592, "lng": 19.456 }
  },
  "requested_alternative": {
    "id": "01K0REQUESTEDALTERNATIVE000",
    "labels": ["recommended"],
    "distance_meters": 10531600,
    "duration_seconds": 460800,
    "costs": {
      "toll": { "amount_minor": 20500, "currency": "USD" },
      "fuel": { "amount_minor": 20500, "currency": "USD" },
      "total": { "amount_minor": 141000, "currency": "USD" }
    },
    "polyline": "encoded-polyline",
    "toll_markers": []
  },
  "proposed_alternative": { "id": "01K0ALTERNATIVE200000000000" },
  "approved_alternative": {
    "id": "01K0ALTERNATIVE200000000000",
    "distance_meters": 10531600,
    "duration_seconds": 460800,
    "costs": {
      "toll": { "amount_minor": 20500, "currency": "USD" },
      "fuel": { "amount_minor": 20500, "currency": "USD" },
      "total": { "amount_minor": 141000, "currency": "USD" }
    },
    "toll_markers": []
  },
  "request_note": "I would like to take this route.",
  "decision_note": "Please take Alternative 2.",
  "fuel_recommendations": [
    {
      "id": "01K0FUELRECOMMENDATION0000",
      "fuel_station_id": "01K1FUELSTATION00000000001",
      "station_name": "Alixon Fuel",
      "address": "3301 Kuhn Rd, West Memphis, AR 72301",
      "coordinate": { "lat": 35.1465, "lng": -90.1845 },
      "price_per_gallon": null,
      "contracted_price": {
        "price_per_gallon": "3.459",
        "currency": "USD",
        "tax_included": false,
        "observed_at": "2026-08-19T15:45:00+00:00"
      },
      "distance_meters": 38624,
      "note": "Use the contracted card price.",
      "confirmed": false,
      "confirmed_at": null
    }
  ],
  "messages": []
}
''';
