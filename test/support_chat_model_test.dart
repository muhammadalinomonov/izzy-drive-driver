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

  group('RouteReviewThread', () {
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
          RouteReviewThread.fromJson(jsonDecode(json) as Map<String, dynamic>);
      expect(thread.id, '01K0ROUTEREVIEW00000000000');
      expect(thread.messages, hasLength(2));
      // Oldest first: the driver's opening message leads.
      expect(thread.messages.first.isDriver, isTrue);
      expect(thread.messages.last.isDriver, isFalse);
    });

    test('a freshly created review with no messages yet parses cleanly', () {
      final thread = RouteReviewThread.fromJson({
        'id': '01K0ROUTEREVIEW00000000001',
        'status': 'pending',
      });
      expect(thread.messages, isEmpty);
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
