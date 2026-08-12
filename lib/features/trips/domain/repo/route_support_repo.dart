import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/features/trips/data/model/route_support_model.dart';

/// Premium route support: the driver asks an agent to review a priced route
/// and keeps a conversation about it (docs/ui/8-2.png).
abstract class RouteSupportRepo {
  /// Creates the route review [request] is about and returns its id plus
  /// whatever messages it already has (normally none, right after creation).
  ///
  /// [idempotencyKey] should stay the same across retries of the same
  /// request - the API dedupes create calls by it (docs
  /// /mobile-fuel-api-websocket.md §4.1) - and only change for a genuinely
  /// new request.
  Future<NetworkResponse<RouteReviewThread>> startReview(
    RouteSupportRequest request, {
    required String idempotencyKey,
  });

  /// Posts [text] to [routeReviewId] and returns the review's full, updated
  /// message list - the endpoint answers with the whole review, not one
  /// message (docs/mobile-api.md §8.3), so callers replace rather than append.
  Future<NetworkResponse<RouteReviewThread>> sendMessage({
    required String routeReviewId,
    required String text,
  });
}
