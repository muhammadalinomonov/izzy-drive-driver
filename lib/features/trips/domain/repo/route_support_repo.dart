import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/features/trips/data/model/route_support_model.dart';

/// Premium route support: the driver asks a dispatcher to review a priced
/// route, then follows the review's decisions, fuel stops and Drive
/// availability (docs/ui/8-2.png, docs/mobile-chat-route-fuel-drive.md §4/§5).
///
/// Every method answers with the whole review - the contract's own reconcile
/// rule is "replace UI state from the REST detail", so callers never merge.
abstract class RouteSupportRepo {
  /// Creates the route review [request] is about.
  ///
  /// [idempotencyKey] should stay the same across retries of the same
  /// request - the API dedupes create calls by it (§4.2) - and only change
  /// for a genuinely new request.
  Future<NetworkResponse<RouteReviewDetail>> startReview(
    RouteSupportRequest request, {
    required String idempotencyKey,
  });

  /// Re-reads [routeReviewId]. Called whenever the review may have changed:
  /// on resume, and as the reconcile step behind every dispatcher action,
  /// since decisions are never delivered as chat payloads.
  Future<NetworkResponse<RouteReviewDetail>> fetchReview(String routeReviewId);

  /// Posts [text] to [routeReviewId]. Answers with the review, its `messages`
  /// including the new one.
  Future<NetworkResponse<RouteReviewDetail>> sendMessage({
    required String routeReviewId,
    required String text,
  });

  /// Accepts a dispatcher-recommended fuel stop, which is what puts it on the
  /// navigation route (§5). A driver can only accept a stop, never request
  /// one - the backend has no endpoint for the latter.
  Future<NetworkResponse<RouteReviewDetail>> confirmFuelRecommendation({
    required String routeReviewId,
    required String recommendationId,
  });

  /// Withdraws a still-`pending` review
  /// (docs/mobile-chat-complete-api-websocket.md §9.4).
  Future<NetworkResponse<RouteReviewDetail>> cancelReview(
    String routeReviewId,
  );
}
