import 'package:taxi_app/core/utils/json_safe.dart';
import 'package:taxi_app/features/trips/data/model/route_support_model.dart';
import 'package:taxi_app/features/trips/data/model/support_chat_model.dart';
import 'package:taxi_app/features/trips/data/model/trip_model.dart';

/// `GET mobile/support-chat?view=timeline` (docs/mobile-chat-complete-api-websocket.md
/// §6): the driver's single merged feed - plain messages and route-review
/// cards, newest-first, discriminated by [SupportTimelineItem.type].
///
/// This is now the one screen for both "Support Message" and "Send request"
/// entry points (§1's Figma table maps every Chat `Main` state to this
/// endpoint). A route-review card here is intentionally thin - the doc is
/// explicit that it does not repeat `request_note` / `decision_note` (§6.3),
/// those live in the real `message` items sitting next to it in the feed -
/// so [RouteReviewCard] only carries what the card itself needs to render and
/// to offer a `Drive` shortcut. Everything else about one review (replying,
/// confirming a fuel stop, cancelling) happens on `route_support_page.dart`,
/// opened by tapping the card.

enum SupportTimelineItemType {
  message,
  routeReview,

  /// A `type` this build doesn't know. Dropped rather than rendered with
  /// missing data - see [SupportTimelinePage.fromJson].
  unknown,
}

class SupportTimelineItem {
  /// `message:{id}` or `route_review:{id}` - stable across reloads, so this
  /// doubles as the dedupe/list key.
  final String key;
  final SupportTimelineItemType type;
  final DateTime? occurredAt;

  /// Set when [type] is [SupportTimelineItemType.message].
  final SupportChatMessage? message;

  /// Set when [type] is [SupportTimelineItemType.routeReview].
  final RouteReviewCard? routeReviewCard;

  const SupportTimelineItem({
    required this.key,
    required this.type,
    this.occurredAt,
    this.message,
    this.routeReviewCard,
  });

  factory SupportTimelineItem.fromJson(Map<String, dynamic> json) {
    final type = switch (toStr(json['type'])) {
      'message' => SupportTimelineItemType.message,
      'route_review' => SupportTimelineItemType.routeReview,
      _ => SupportTimelineItemType.unknown,
    };
    return SupportTimelineItem(
      key: toStr(json['key']),
      type: type,
      occurredAt: DateTime.tryParse(toStr(json['occurred_at'])),
      message: type == SupportTimelineItemType.message
          ? SupportChatMessage.fromJson(toMap(json['message']))
          : null,
      routeReviewCard: type == SupportTimelineItemType.routeReview
          ? RouteReviewCard.fromJson(toMap(json['route_review']))
          : null,
    );
  }
}

/// A page of the merged timeline. Same pagination shape as
/// [SupportChatPage], but newest-first response ordering is a rule of this
/// endpoint specifically (§6.3) - callers reverse it for display exactly like
/// the legacy history already does.
class SupportTimelinePage {
  final List<SupportTimelineItem> items;
  final int page;
  final int perPage;
  final int total;
  final int lastPage;

  const SupportTimelinePage({
    required this.items,
    required this.page,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  factory SupportTimelinePage.fromJson(
    Map<String, dynamic> data,
    Map<String, dynamic> pagination,
  ) {
    final items = toList(
      data['items'],
      (e) => SupportTimelineItem.fromJson(toMap(e)),
    ).where((item) => item.type != SupportTimelineItemType.unknown).toList();

    return SupportTimelinePage(
      items: items,
      page: toInt(pagination['page'], 1),
      perPage: toInt(pagination['per_page'], 50),
      total: toInt(pagination['total']),
      lastPage: toInt(pagination['last_page'], 1),
    );
  }
}

/// The compact route-review card as it appears inline in the timeline -
/// deliberately not the full `RouteReviewDetail` (`route_support_model.dart`):
/// no `request_note`/`decision_note` (§6.3), and one already-resolved
/// [displayAlternative] instead of three raw alternatives, because the
/// backend has already applied the approved → proposed → requested selection
/// server-side.
class RouteReviewCard {
  final String id;
  final RouteReviewStatus status;

  /// `driver` when the driver asked for the review, `support` when a
  /// dispatcher pushed an approved route unprompted - decides which side of
  /// the timeline the card bubble sits on.
  final String initiator;

  final bool canDrive;

  /// `route.id` - the `route_request_id` a navigation session needs.
  final String routeRequestId;
  final String approvedAlternativeId;

  final TripCoordinate? origin;
  final TripCoordinate? destination;

  /// Already resolved by the backend; see the class doc. `null` only while a
  /// route is still being calculated.
  final TripAlternative? displayAlternative;

  final List<RouteReviewFuelRecommendation> fuelRecommendations;

  const RouteReviewCard({
    required this.id,
    this.status = RouteReviewStatus.pending,
    this.initiator = 'driver',
    this.canDrive = false,
    this.routeRequestId = '',
    this.approvedAlternativeId = '',
    this.origin,
    this.destination,
    this.displayAlternative,
    this.fuelRecommendations = const [],
  });

  factory RouteReviewCard.fromJson(Map<String, dynamic> json) {
    final route = toMap(json['route']);
    TripCoordinate? point(String key) {
      final raw = route[key];
      return raw == null ? null : TripCoordinate.fromJson(toMap(raw));
    }

    final displayAlternative = json['display_alternative'];

    return RouteReviewCard(
      id: toStr(json['id']),
      status: RouteReviewStatus.parse(toStr(json['status'])),
      initiator: toStr(json['initiator'], 'driver'),
      canDrive: toBool(json['can_drive']),
      routeRequestId: toStr(route['id']),
      approvedAlternativeId: toStr(json['approved_alternative_id']),
      origin: point('origin'),
      destination: point('destination'),
      displayAlternative: displayAlternative == null
          ? null
          : TripAlternative.fromJson(toMap(displayAlternative)),
      fuelRecommendations: toList(
        json['fuel_recommendations'],
        (e) => RouteReviewFuelRecommendation.fromJson(toMap(e)),
      ),
    );
  }

  /// Same rule as `RouteReviewDetail.canStartDrive`: the session endpoint has
  /// nothing to start without an approved alternative, and a closed review
  /// has nothing left to drive.
  bool get canStartDrive =>
      canDrive && approvedAlternativeId.isNotEmpty && !status.isClosed;

  /// The card `RouteSupportCard` renders. [originLabel]/[destinationLabel]
  /// fall back to [TripCoordinate.shortLabel] when the caller has no address
  /// text - a card that arrived via the timeline (never locally created by
  /// this driver's own compose flow) has none.
  RouteSupportRouteCard cardFor({
    required String originLabel,
    required String destinationLabel,
    required String perGallonNote,
  }) {
    return buildRouteSupportRouteCard(
      alternative: displayAlternative,
      fuelRecommendations: fuelRecommendations,
      originLabel: originLabel,
      destinationLabel: destinationLabel,
      perGallonNote: perGallonNote,
    );
  }
}
