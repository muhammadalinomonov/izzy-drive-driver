import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/features/trips/data/model/route_support_model.dart';

/// Premium route support: the driver asks an agent to review a priced route
/// and keeps a conversation about it (docs/ui/8-2.png).
///
/// The backing endpoints are not built yet; `RouteSupportRepoImpl` currently
/// serves a scripted thread from `RouteSupportDataSource`. This interface is
/// the seam - when the API ships, only the data source changes.
abstract class RouteSupportRepo {
  /// The thread for [request], oldest first.
  ///
  /// An empty list is a valid answer (nothing said yet), not an error.
  Future<NetworkResponse<List<RouteSupportMessage>>> getConversation(
    RouteSupportRequest request,
  );

  /// Posts a follow-up from the driver and returns the stored message.
  Future<NetworkResponse<RouteSupportMessage>> sendMessage({
    required RouteSupportRequest request,
    required String text,
  });
}
