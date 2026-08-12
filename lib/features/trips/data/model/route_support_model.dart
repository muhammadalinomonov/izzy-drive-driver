import 'package:taxi_app/core/utils/json_safe.dart';
import 'package:taxi_app/core/utils/unit_format.dart';
import 'package:taxi_app/features/trips/data/model/place_model.dart';
import 'package:taxi_app/features/trips/data/model/support_chat_model.dart';
import 'package:taxi_app/features/trips/data/model/trip_model.dart';

/// Models for the Premium "Send request" flow (docs/ui/8-2.png): the driver
/// asks support to review a priced route, then follows up in the same thread.
///
/// Two backends meet here, both documented, neither fully covering the
/// feature alone:
/// - `POST mobile/route-reviews` creates the review. It is NOT in
///   `docs/mobile-api.md` - only in `docs/mobile-fuel-api-websocket.md` §4.1 -
///   because that doc owns the fuel-recommendation flow the review exists
///   for. Without it there is nothing for "Send Request" to attach a message
///   to, so it is used here anyway.
/// - `POST mobile/route-reviews/{id}/messages` (docs/mobile-api.md §8.3) sends
///   a follow-up and answers with the review's messages, in the same wire
///   shape as the normal support chat - see [SupportChatMessage], reused
///   as-is rather than duplicated.

/// A priced stop on the driver's opening route card (docs/ui/8-2-1.png).
///
/// Client-built only - this never round-trips through the API, since the real
/// review object carries no per-stop breakdown of its own (docs
/// §4.2 shows `fuel_recommendations`, not a generic stop list). Price is text
/// rather than [TripMoney] because a toll amount and a fuel range don't share
/// one numeric shape.
class RouteSupportStop {
  final RouteSupportStopKind kind;
  final String title;

  /// Distance from the route's origin. Null when unknown - the toll API does
  /// not report per-marker offsets today, so the row simply drops "in X mi".
  final double? distanceMiles;

  /// Main price text, e.g. `-$34.00` or `$5-8`.
  final String priceText;

  /// Trailing qualifier rendered smaller and grey, e.g. `for gallon`.
  final String priceNote;

  const RouteSupportStop({
    required this.kind,
    required this.title,
    this.distanceMiles,
    this.priceText = '',
    this.priceNote = '',
  });

  /// A toll gantry from a calculated route.
  factory RouteSupportStop.fromTollMarker(TripTollMarker marker) {
    return RouteSupportStop(
      kind: RouteSupportStopKind.toll,
      title: marker.name,
      priceText: marker.amount == null ? '' : '-${marker.amount!.formatted}',
    );
  }
}

/// `toll` renders the red bullet + "Toll" badge, `fuel` the blue bullet +
/// "Fuel Station" badge (docs/ui/8-2-2.png) - see `RouteSupportCard`.
enum RouteSupportStopKind { toll, fuel }

/// The three figures under the driver's opening route card (docs/ui/8-2-1.png):
/// fuel cost, toll cost, total distance. Client-built, like [RouteSupportStop].
class RouteSupportSummary {
  final String fuel;
  final String toll;
  final String distance;

  const RouteSupportSummary({
    required this.fuel,
    required this.toll,
    required this.distance,
  });

  /// From a priced alternative: the same numbers the route overview footer
  /// shows, so the driver recognises what they asked about.
  factory RouteSupportSummary.fromAlternative(TripAlternative alternative) {
    return RouteSupportSummary(
      fuel: alternative.fuel == null ? '-' : '-${alternative.fuel!.formatted}',
      toll: alternative.toll == null ? '-' : '-${alternative.toll!.formatted}',
      distance: '${alternative.distanceMiles.toStringAsFixed(0)} mi',
    );
  }
}

/// The white card shown above the thread: origin, stops, destination, and the
/// fuel/toll/mile summary (docs/ui/8-2-1.png).
///
/// Always built from [RouteSupportRequest.card] - the request the page opened
/// with - never from a server message, since real messages carry no card
/// (docs/mobile-api.md §8.3's `messages` are plain text).
class RouteSupportRouteCard {
  final String originLabel;
  final String destinationLabel;
  final RouteSupportSummary? summary;
  final List<RouteSupportStop> stops;

  const RouteSupportRouteCard({
    required this.originLabel,
    required this.destinationLabel,
    this.summary,
    this.stops = const [],
  });
}

/// The review's id and its messages, oldest-first - the slice of the full
/// route-review object (docs/mobile-fuel-api-websocket.md §4.2) this feature
/// actually needs. Returned by both creating a review and posting to one,
/// since both endpoints answer with the same object.
class RouteReviewThread {
  final String id;
  final List<SupportChatMessage> messages;

  const RouteReviewThread({required this.id, required this.messages});

  factory RouteReviewThread.fromJson(Map<String, dynamic> json) {
    return RouteReviewThread(
      id: toStr(json['id']),
      messages: toList(
        json['messages'],
        (e) => SupportChatMessage.fromJson(toMap(e)),
      ),
    );
  }
}

/// Everything needed to open a support request for a route: the payload
/// `POST mobile/route-reviews` carries, and the context the opening card
/// renders from.
class RouteSupportRequest {
  /// `RouteRequest` id from `POST /mobile/toll-routes`.
  final String routeId;

  /// Which priced alternative the driver is asking about.
  final String alternativeId;

  /// Human label for that alternative, e.g. `Recommended` / `Alternative 2`.
  final String alternativeLabel;

  final PlaceModel origin;
  final PlaceModel destination;

  final int distanceMeters;
  final int durationSeconds;
  final TripMoney? toll;
  final TripMoney? fuel;

  /// Toll gantries on the selected alternative, in route order.
  final List<RouteSupportStop> stops;

  const RouteSupportRequest({
    required this.routeId,
    required this.alternativeId,
    required this.alternativeLabel,
    required this.origin,
    required this.destination,
    required this.distanceMeters,
    required this.durationSeconds,
    this.toll,
    this.fuel,
    this.stops = const [],
  });

  /// Built from what the route overview screen already has in hand.
  factory RouteSupportRequest.fromRoute({
    required TripModel trip,
    required TripAlternative alternative,
    required String alternativeLabel,
    required PlaceModel origin,
    required PlaceModel destination,
  }) {
    return RouteSupportRequest(
      routeId: trip.id,
      alternativeId: alternative.id,
      alternativeLabel: alternativeLabel,
      origin: origin,
      destination: destination,
      distanceMeters: alternative.distanceMeters,
      durationSeconds: alternative.durationSeconds,
      toll: alternative.toll,
      fuel: alternative.fuel,
      stops: alternative.tollMarkers
          .map(RouteSupportStop.fromTollMarker)
          .toList(),
    );
  }

  double get distanceMiles => metersToMiles(distanceMeters);

  /// The card shown above the thread.
  RouteSupportRouteCard get card => RouteSupportRouteCard(
        originLabel: origin.fieldLabel,
        destinationLabel: destination.fieldLabel,
        stops: stops,
        summary: RouteSupportSummary(
          fuel: fuel == null ? '-' : '-${fuel!.formatted}',
          toll: toll == null ? '-' : '-${toll!.formatted}',
          distance: '${distanceMiles.toStringAsFixed(0)} mi',
        ),
      );

  /// Body for `POST mobile/route-reviews` (docs/mobile-fuel-api-websocket.md
  /// §4.1). [message] is the optional opening note; "Send Request" itself
  /// sends none today - the composer only appears once the review exists.
  Map<String, dynamic> toCreateReviewJson({String? message}) => {
        'route_request_id': routeId,
        'route_alternative_id': alternativeId,
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
      };
}
