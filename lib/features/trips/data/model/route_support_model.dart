import 'package:taxi_app/core/utils/json_safe.dart';
import 'package:taxi_app/core/utils/unit_format.dart';
import 'package:taxi_app/features/trips/data/model/place_model.dart';
import 'package:taxi_app/features/trips/data/model/support_chat_model.dart';
import 'package:taxi_app/features/trips/data/model/trip_model.dart';

/// Models for the Premium "Send request" flow (docs/ui/8-2.png): the driver
/// asks support to review a priced route, then follows up in the same thread.
///
/// The contract these follow is `docs/mobile-chat-route-fuel-drive.md`, which
/// documents what the backend actually serves and supersedes the earlier
/// proposal in `docs/mobile-fuel-api-websocket.md` on one decisive point:
/// **a route or fuel card is never a chat payload.** Messages carry no
/// `attachment` / `action` / `highlight`; every card on this screen is built
/// from the review object read back over REST. The loop is always
///
/// ```text
/// REST mutation -> event says "this review changed"
///   -> GET mobile/route-reviews/{id} -> replace UI state
/// ```
///
/// so [RouteReviewDetail] - not any individual message - is the screen's
/// single source of truth.

/// A priced stop on a route card (docs/ui/8-2-1.png / 8-2-2.png).
///
/// Client-built: a toll gantry comes off the alternative's `toll_markers`, a
/// fuel stop off the review's `fuel_recommendations`, and the two are only
/// alike on screen - the API has no generic stop list. Price is text rather
/// than [TripMoney] because a toll amount and a per-gallon price don't share
/// one numeric shape.
class RouteSupportStop {
  final RouteSupportStopKind kind;
  final String title;

  /// Distance from the route's origin. Null when unknown - the toll API does
  /// not report per-marker offsets today, so the row simply drops "in X mi".
  final double? distanceMiles;

  /// Main price text, e.g. `-$34.00` or `$3.459`.
  final String priceText;

  /// Trailing qualifier rendered smaller and grey, e.g. `for gallon`.
  final String priceNote;

  /// Fuel stops only: the driver has accepted this one, so it will be routed
  /// through. Always false for a toll gantry, which is not opt-in.
  final bool confirmed;

  const RouteSupportStop({
    required this.kind,
    required this.title,
    this.distanceMiles,
    this.priceText = '',
    this.priceNote = '',
    this.confirmed = false,
  });

  /// A toll gantry from a calculated route.
  factory RouteSupportStop.fromTollMarker(TripTollMarker marker) {
    return RouteSupportStop(
      kind: RouteSupportStopKind.toll,
      title: marker.name,
      priceText: marker.amount == null ? '' : '-${marker.amount!.formatted}',
    );
  }

  /// A dispatcher-recommended fuel stop. Unlike a toll marker this one *does*
  /// carry `distance_meters`, so the row can show "in X mi".
  factory RouteSupportStop.fromFuelRecommendation(
    RouteReviewFuelRecommendation recommendation, {
    required String perGallonNote,
  }) {
    final price = recommendation.priceText;
    return RouteSupportStop(
      kind: RouteSupportStopKind.fuel,
      title: recommendation.title,
      distanceMiles: recommendation.distanceMiles,
      priceText: price,
      priceNote: price.isEmpty ? '' : perGallonNote,
      confirmed: recommendation.confirmed,
    );
  }
}

/// `toll` renders the red bullet + "Toll" badge, `fuel` the blue bullet +
/// "Fuel Station" badge (docs/ui/8-2-2.png) - see `RouteSupportCard`.
enum RouteSupportStopKind { toll, fuel }

/// The three figures under a route card (docs/ui/8-2-1.png): fuel cost, toll
/// cost, total distance. Client-built, like [RouteSupportStop].
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

/// Where a review currently stands. `pending` until a dispatcher acts, then
/// one of the three decisions; `cancelled` is the reviewer or an auto-expiry
/// closing it (docs/mobile-chat-route-fuel-drive.md §4.3).
enum RouteReviewStatus {
  pending,
  approved,
  alternativeSuggested,
  declined,
  cancelled,

  /// A status this build doesn't know. Treated as "still open, nothing
  /// decided" rather than as an error - a new server-side status must not
  /// blank the screen.
  unknown;

  static RouteReviewStatus parse(String raw) {
    return switch (raw.toLowerCase()) {
      'pending' => RouteReviewStatus.pending,
      'approved' => RouteReviewStatus.approved,
      'alternative_suggested' => RouteReviewStatus.alternativeSuggested,
      'declined' => RouteReviewStatus.declined,
      'cancelled' || 'canceled' => RouteReviewStatus.cancelled,
      _ => RouteReviewStatus.unknown,
    };
  }

  /// No further dispatcher action is coming, so the composer and Drive are
  /// both pointless. Posting to a closed review answers
  /// 409 MOBILE_ROUTE_REVIEW_CLOSED (docs/mobile-api.md §9).
  bool get isClosed =>
      this == RouteReviewStatus.declined || this == RouteReviewStatus.cancelled;
}

/// The card-network price at a recommended station - the number that actually
/// applies to this driver, as opposed to the pump price.
class RouteReviewContractedPrice {
  /// Kept as text: the wire sends `"3.459"`, three decimals, and rounding it
  /// through a double to two would misquote the price the driver is promised.
  final String pricePerGallon;
  final String currency;
  final bool taxIncluded;
  final DateTime? observedAt;

  const RouteReviewContractedPrice({
    required this.pricePerGallon,
    required this.currency,
    required this.taxIncluded,
    this.observedAt,
  });

  factory RouteReviewContractedPrice.fromJson(Map<String, dynamic> json) {
    return RouteReviewContractedPrice(
      pricePerGallon: toStr(json['price_per_gallon']),
      currency: toStr(json['currency'], 'USD'),
      taxIncluded: toBool(json['tax_included']),
      observedAt: DateTime.tryParse(toStr(json['observed_at'])),
    );
  }

  /// `$3.459`. Not [TripMoney.formatted]: that one is minor units rounded to
  /// two decimals, which a per-gallon price is not.
  String get formatted {
    if (pricePerGallon.isEmpty) return '';
    return switch (currency.toUpperCase()) {
      'USD' => '\$$pricePerGallon',
      'EUR' => '€$pricePerGallon',
      'GBP' => '£$pricePerGallon',
      final other => '$pricePerGallon $other',
    };
  }
}

/// A fuel stop the dispatcher put on the review
/// (docs/mobile-chat-route-fuel-drive.md §5).
///
/// The flow is one-directional: dispatcher recommends, driver confirms. There
/// is no endpoint for a driver to *request* a station, and no fuel-card
/// activation state or `active_until` anywhere in the contract - so nothing
/// here may be invented client-side.
class RouteReviewFuelRecommendation {
  final String id;
  final String fuelStationId;
  final String stationName;
  final String address;
  final TripCoordinate? coordinate;

  /// Public pump price. Usually null - [contractedPrice] is the one that
  /// applies when the driver pays with the fleet card.
  final String pricePerGallon;

  final RouteReviewContractedPrice? contractedPrice;

  /// Distance along the route from its origin. Null when the dispatcher sent
  /// none.
  final int? distanceMeters;

  final String note;

  /// The driver has accepted this stop, so the backend will add it as a
  /// navigation waypoint when the session starts (§6).
  final bool confirmed;

  final DateTime? confirmedAt;

  const RouteReviewFuelRecommendation({
    required this.id,
    required this.fuelStationId,
    required this.stationName,
    required this.address,
    this.coordinate,
    this.pricePerGallon = '',
    this.contractedPrice,
    this.distanceMeters,
    this.note = '',
    this.confirmed = false,
    this.confirmedAt,
  });

  factory RouteReviewFuelRecommendation.fromJson(Map<String, dynamic> json) {
    final coordinate = json['coordinate'];
    final contracted = json['contracted_price'];
    final distance = json['distance_meters'];
    return RouteReviewFuelRecommendation(
      id: toStr(json['id']),
      fuelStationId: toStr(json['fuel_station_id']),
      stationName: toStr(json['station_name']),
      address: toStr(json['address']),
      coordinate: coordinate == null
          ? null
          : TripCoordinate.fromJson(toMap(coordinate)),
      pricePerGallon: toStr(json['price_per_gallon']),
      contractedPrice: contracted == null
          ? null
          : RouteReviewContractedPrice.fromJson(toMap(contracted)),
      distanceMeters: distance == null ? null : toInt(distance),
      note: toStr(json['note']),
      confirmed: toBool(json['confirmed']),
      confirmedAt: DateTime.tryParse(toStr(json['confirmed_at'])),
    );
  }

  /// Address if there is one, else the station's name - the stop row shows a
  /// street line, matching how a toll gantry is labelled.
  String get title => address.isNotEmpty ? address : stationName;

  double? get distanceMiles =>
      distanceMeters == null ? null : metersToMiles(distanceMeters!);

  /// Contracted price wins: it is what the driver will actually be charged.
  String get priceText {
    final contracted = contractedPrice?.formatted ?? '';
    if (contracted.isNotEmpty) return contracted;
    return pricePerGallon.isEmpty ? '' : '\$$pricePerGallon';
  }
}

/// The route-review as the backend serves it
/// (`GET mobile/route-reviews/{id}`, docs/mobile-chat-route-fuel-drive.md
/// §4.2). Also what creating a review and posting a message answer with, so
/// every call on this screen hands back the same whole object and callers
/// replace their state from it rather than patching it.
class RouteReviewDetail {
  final String id;
  final RouteReviewStatus status;

  /// `driver` when the driver asked for the review, `support` when a
  /// dispatcher pushed an approved route unprompted (§4.3).
  final String initiator;

  /// The backend's own verdict on whether this route may be driven. Checked
  /// rather than inferred from [status]: it is the field the contract names.
  final bool canDrive;

  /// `route.id` - the `route_request_id` a navigation session needs.
  final String routeRequestId;

  final TripCoordinate? origin;
  final TripCoordinate? destination;

  /// What the driver asked about.
  final TripAlternative? requestedAlternative;

  /// What the dispatcher suggested instead, not yet blessed for driving.
  final TripAlternative? proposedAlternative;

  /// The route cleared for driving. The only one a navigation session may be
  /// started with (§6).
  final TripAlternative? approvedAlternative;

  final String requestNote;
  final String decisionNote;

  final List<RouteReviewFuelRecommendation> fuelRecommendations;

  /// Oldest-first, unlike the generic chat history (docs/mobile-api.md §8.3).
  final List<SupportChatMessage> messages;

  const RouteReviewDetail({
    required this.id,
    this.status = RouteReviewStatus.pending,
    this.initiator = 'driver',
    this.canDrive = false,
    this.routeRequestId = '',
    this.origin,
    this.destination,
    this.requestedAlternative,
    this.proposedAlternative,
    this.approvedAlternative,
    this.requestNote = '',
    this.decisionNote = '',
    this.fuelRecommendations = const [],
    this.messages = const [],
  });

  factory RouteReviewDetail.fromJson(Map<String, dynamic> json) {
    final route = toMap(json['route']);
    TripAlternative? alternative(String key) {
      final raw = json[key];
      return raw == null ? null : TripAlternative.fromJson(toMap(raw));
    }

    TripCoordinate? point(String key) {
      final raw = route[key];
      return raw == null ? null : TripCoordinate.fromJson(toMap(raw));
    }

    // `route.id` is the documented home of the route request id; the flat
    // `route_request_id` is what the creation response used before the object
    // grew its `route` block, and older builds of the API still send it.
    final routeId = toStr(route['id']);

    return RouteReviewDetail(
      id: toStr(json['id']),
      status: RouteReviewStatus.parse(toStr(json['status'])),
      initiator: toStr(json['initiator'], 'driver'),
      canDrive: toBool(json['can_drive']),
      routeRequestId:
          routeId.isNotEmpty ? routeId : toStr(json['route_request_id']),
      origin: point('origin'),
      destination: point('destination'),
      requestedAlternative: alternative('requested_alternative'),
      proposedAlternative: alternative('proposed_alternative'),
      approvedAlternative: alternative('approved_alternative'),
      requestNote: toStr(json['request_note']),
      decisionNote: toStr(json['decision_note']),
      fuelRecommendations: toList(
        json['fuel_recommendations'],
        (e) => RouteReviewFuelRecommendation.fromJson(toMap(e)),
      ),
      messages: toList(
        json['messages'],
        (e) => SupportChatMessage.fromJson(toMap(e)),
      ),
    );
  }

  /// Which alternative the card on screen should show, per the selection
  /// table in §4.3. An approved route always wins over a merely proposed one:
  /// once the dispatcher blesses something, that is the route in play.
  ///
  /// The fallbacks are deliberate - a status must never leave the driver
  /// staring at a card-shaped hole, so each case degrades to the next
  /// most-specific alternative it has.
  TripAlternative? get activeAlternative {
    return switch (status) {
      RouteReviewStatus.pending => requestedAlternative,
      RouteReviewStatus.approved =>
        approvedAlternative ?? requestedAlternative,
      RouteReviewStatus.alternativeSuggested =>
        approvedAlternative ?? proposedAlternative ?? requestedAlternative,
      // Nothing was accepted, so the card stays on what the driver asked
      // about; `Drive` is hidden separately.
      RouteReviewStatus.declined ||
      RouteReviewStatus.cancelled =>
        requestedAlternative,
      RouteReviewStatus.unknown => approvedAlternative ??
          proposedAlternative ??
          requestedAlternative,
    };
  }

  /// `Drive` is shown only on `can_drive=true` **and** an approved
  /// alternative - the session endpoint has nothing to start without the
  /// latter (§4.3, §6).
  bool get canStartDrive =>
      canDrive && approvedAlternative != null && !status.isClosed;

  /// The stop that will become a navigation waypoint, if the driver has
  /// accepted one. The contract shows no cap, but only confirmed stops are
  /// routed through.
  List<RouteReviewFuelRecommendation> get confirmedFuelStops =>
      fuelRecommendations.where((r) => r.confirmed).toList();

  /// The dispatcher's verdict text, if any - shown under the card rather than
  /// as a bubble, since it belongs to the decision, not to the conversation.
  String get decisionText => decisionNote;

  /// The card for [activeAlternative]. Endpoint labels come from the caller:
  /// the route API returns coordinates only, never address text (§7), so the
  /// labels the driver picked in the planner are carried in local state.
  RouteSupportRouteCard cardFor({
    required String originLabel,
    required String destinationLabel,
    required String perGallonNote,
  }) {
    return buildRouteSupportRouteCard(
      alternative: activeAlternative,
      fuelRecommendations: fuelRecommendations,
      originLabel: originLabel,
      destinationLabel: destinationLabel,
      perGallonNote: perGallonNote,
    );
  }
}

/// Shared by [RouteReviewDetail.cardFor] and the unified timeline's
/// [RouteReviewCard.cardFor] (`support_timeline_model.dart`) - same card,
/// same stop list, the only thing that differs between the two call sites is
/// which alternative already won the approved/proposed/requested selection
/// (client-side in [RouteReviewDetail.activeAlternative], server-side as
/// `display_alternative` on the timeline's compact card).
RouteSupportRouteCard buildRouteSupportRouteCard({
  required TripAlternative? alternative,
  required List<RouteReviewFuelRecommendation> fuelRecommendations,
  required String originLabel,
  required String destinationLabel,
  required String perGallonNote,
}) {
  return RouteSupportRouteCard(
    originLabel: originLabel,
    destinationLabel: destinationLabel,
    summary: alternative == null
        ? null
        : RouteSupportSummary.fromAlternative(alternative),
    stops: [
      ...?alternative?.tollMarkers.map(RouteSupportStop.fromTollMarker),
      ...fuelRecommendations.map(
        (r) => RouteSupportStop.fromFuelRecommendation(
          r,
          perGallonNote: perGallonNote,
        ),
      ),
    ],
  );
}

/// Everything needed to open a support request for a route: the payload
/// `POST mobile/route-reviews` carries, and the endpoint labels the card
/// renders with - which the API itself never returns (§7).
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

  /// The card to show before the review has been read back - what the driver
  /// selected, drawn from local state alone.
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

  /// Body for `POST mobile/route-reviews`
  /// (docs/mobile-chat-route-fuel-drive.md §4.2). [message] is the optional
  /// opening note; when sent it must be 3..2000 characters.
  Map<String, dynamic> toCreateReviewJson({String? message}) => {
        'route_request_id': routeId,
        'route_alternative_id': alternativeId,
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
      };
}

/// How `route_support_page.dart` was opened - exactly one of the two named
/// constructors applies, so the bloc never has to guess which mode it is in:
///
/// - [RouteSupportPageArgs.create]: the driver just picked a route (route
///   overview's "Send request") and the page's first job is `POST
///   mobile/route-reviews`.
/// - [RouteSupportPageArgs.open]: the driver tapped an existing review's card
///   in the unified support timeline (`support_timeline_page.dart`) - the
///   review already exists, so the page's first job is `GET .../{id}`
///   instead. There is no local [RouteSupportRequest] in this case (the
///   review may never have gone through this driver's own compose flow at
///   all, e.g. `initiator: support`), so the request card falls back to
///   coordinate labels - see `_RequestCardBubble` in the page.
class RouteSupportPageArgs {
  final RouteSupportRequest? request;
  final String? reviewId;

  const RouteSupportPageArgs.create(this.request) : reviewId = null;

  const RouteSupportPageArgs.open(this.reviewId) : request = null;
}
