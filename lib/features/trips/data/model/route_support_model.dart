import 'package:taxi_app/core/utils/json_safe.dart';
import 'package:taxi_app/core/utils/unit_format.dart';
import 'package:taxi_app/features/trips/data/model/place_model.dart';
import 'package:taxi_app/features/trips/data/model/trip_model.dart';

/// Models for the Premium "Send request" flow (docs/ui/8-2.png): the driver
/// asks support to review a priced route, and support answers - sometimes with
/// a different route to take instead.
///
/// **No backend yet.** These shapes are what the endpoint is expected to speak,
/// so `RouteSupportDataSource` can be swapped from mock data to real calls
/// without touching the bloc or the UI. Every parser goes through `json_safe`,
/// like the rest of the trips models, so a field the API renames degrades to a
/// default instead of crashing the thread.

/// Who wrote a message. Drives the bubble tint, not its alignment - both sides
/// are full width in the design.
enum RouteSupportAuthor {
  driver,
  agent;

  static RouteSupportAuthor parse(String raw) {
    return raw.toLowerCase() == 'driver'
        ? RouteSupportAuthor.driver
        : RouteSupportAuthor.agent;
  }

  String get wire => name;
}

/// A priced stop on a route card. `toll` renders the red bullet + "Toll"
/// badge, `fuel` the blue bullet + "Fuel Station" badge (docs/ui/8-2-2.png).
enum RouteSupportStopKind {
  toll,
  fuel;

  static RouteSupportStopKind parse(String raw) {
    return raw.toLowerCase() == 'fuel'
        ? RouteSupportStopKind.fuel
        : RouteSupportStopKind.toll;
  }

  String get wire => name;
}

/// One row of a route card: what the stop is, how far along it sits, what it
/// costs.
///
/// Price is carried as text rather than [TripMoney] because the design shows
/// both an exact toll (`$-34`) and a fuel *range* with a unit
/// (`$5-8 for gallon`) - a single minor-units amount can't express the latter.
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

  factory RouteSupportStop.fromJson(Map<String, dynamic> json) {
    final miles = json['distance_miles'];
    return RouteSupportStop(
      kind: RouteSupportStopKind.parse(toStr(json['kind'])),
      title: toStr(json['title']),
      distanceMiles: miles == null ? null : toDouble(miles),
      priceText: toStr(json['price_text']),
      priceNote: toStr(json['price_note']),
    );
  }

  Map<String, dynamic> toJson() => {
        'kind': kind.wire,
        'title': title,
        'distance_miles': distanceMiles,
        'price_text': priceText,
        'price_note': priceNote,
      };

  /// A toll gantry from a calculated route.
  factory RouteSupportStop.fromTollMarker(TripTollMarker marker) {
    return RouteSupportStop(
      kind: RouteSupportStopKind.toll,
      title: marker.name,
      priceText: marker.amount == null ? '' : '-${marker.amount!.formatted}',
    );
  }
}

/// The three figures under a route card (docs/ui/8-2-1.png): fuel cost, toll
/// cost, total distance. Pre-formatted for the same reason as
/// [RouteSupportStop.priceText] - support may quote a range.
class RouteSupportSummary {
  final String fuel;
  final String toll;
  final String distance;

  const RouteSupportSummary({
    required this.fuel,
    required this.toll,
    required this.distance,
  });

  factory RouteSupportSummary.fromJson(Map<String, dynamic> json) {
    return RouteSupportSummary(
      fuel: toStr(json['fuel'], '-'),
      toll: toStr(json['toll'], '-'),
      distance: toStr(json['distance'], '-'),
    );
  }

  Map<String, dynamic> toJson() => {
        'fuel': fuel,
        'toll': toll,
        'distance': distance,
      };

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

/// The white card inside a bubble: origin, the stops between, destination, and
/// optionally the fuel/toll/mile figures.
///
/// One shape covers both cards in the design - the driver's request carries a
/// [summary] and no stops, support's suggestion carries stops and no summary -
/// so the renderer has a single code path.
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

  factory RouteSupportRouteCard.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'];
    return RouteSupportRouteCard(
      originLabel: toStr(json['origin_label']),
      destinationLabel: toStr(json['destination_label']),
      summary: summary == null
          ? null
          : RouteSupportSummary.fromJson(toMap(summary)),
      stops: toList(
        json['stops'],
        (e) => RouteSupportStop.fromJson(toMap(e)),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'origin_label': originLabel,
        'destination_label': destinationLabel,
        'summary': summary?.toJson(),
        'stops': stops.map((s) => s.toJson()).toList(),
      };
}

/// One message in a route support thread.
class RouteSupportMessage {
  final String id;
  final RouteSupportAuthor author;

  /// Display name of the agent. Empty for driver messages.
  final String senderName;

  final String body;

  /// Emphasised blue lead-in above [body] - approvals and recommendations.
  final String highlight;

  final DateTime? sentAt;

  /// Route card attached to the message, if any.
  final RouteSupportRouteCard? card;

  /// Whether the message offers a Drive action for its [card].
  final bool showDriveAction;

  const RouteSupportMessage({
    required this.id,
    required this.author,
    this.senderName = '',
    this.body = '',
    this.highlight = '',
    this.sentAt,
    this.card,
    this.showDriveAction = false,
  });

  bool get isDriver => author == RouteSupportAuthor.driver;

  factory RouteSupportMessage.fromJson(Map<String, dynamic> json) {
    final card = json['route_card'];
    return RouteSupportMessage(
      id: toStr(json['id']),
      author: RouteSupportAuthor.parse(toStr(json['author'])),
      senderName: toStr(json['sender_name']),
      body: toStr(json['body']),
      highlight: toStr(json['highlight']),
      sentAt: DateTime.tryParse(toStr(json['sent_at'])),
      card: card == null ? null : RouteSupportRouteCard.fromJson(toMap(card)),
      showDriveAction: toBool(json['show_drive_action']),
    );
  }

  /// `23:00`, as shown under the driver's message. Empty when the server sent
  /// no timestamp.
  String get sentAtLabel {
    final at = sentAt;
    if (at == null) return '';
    final local = at.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

/// Everything needed to open a support request for a route - the payload the
/// future `POST` will carry, and the context the page renders from.
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

  /// The card shown with the driver's opening message.
  RouteSupportRouteCard get card => RouteSupportRouteCard(
        originLabel: origin.fieldLabel,
        destinationLabel: destination.fieldLabel,
        summary: RouteSupportSummary(
          fuel: fuel == null ? '-' : '-${fuel!.formatted}',
          toll: toll == null ? '-' : '-${toll!.formatted}',
          distance: '${distanceMiles.toStringAsFixed(0)} mi',
        ),
      );

  /// Request body for the endpoint that will back this flow.
  Map<String, dynamic> toJson() => {
        'route_request_id': routeId,
        'route_alternative_id': alternativeId,
        'origin': {
          'label': origin.fieldLabel,
          'lat': origin.coordinate.lat,
          'lng': origin.coordinate.lng,
        },
        'destination': {
          'label': destination.fieldLabel,
          'lat': destination.coordinate.lat,
          'lng': destination.coordinate.lng,
        },
        'distance_meters': distanceMeters,
        'duration_seconds': durationSeconds,
        'toll_amount_minor': toll?.amountMinor,
        'fuel_amount_minor': fuel?.amountMinor,
        'currency': toll?.currency ?? fuel?.currency,
      };
}
