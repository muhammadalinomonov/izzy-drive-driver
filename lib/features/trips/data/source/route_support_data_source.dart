import 'package:injectable/injectable.dart';
import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/features/trips/data/model/route_support_model.dart';

/// PLACEHOLDER route-support source.
///
/// The backend endpoints for the Premium "Send request" flow do not exist yet,
/// so this serves a scripted conversation built around the route the driver
/// actually asked about. That is enough to exercise the whole feature - bloc,
/// loading/empty/error states, the chat UI and its route cards - today.
///
/// ## Replacing this with the real API
///
/// Everything around this class is already API-shaped: [RouteSupportMessage]
/// parses the JSON the endpoint is expected to return, [RouteSupportRequest]
/// serialises the body it is expected to take, and the repository returns
/// `NetworkResponse` like every other source here. When the endpoints land,
/// swap these bodies for real calls:
///
/// ```dart
/// final response = await client.post(
///   TollApiConstants.routeSupportRequests,
///   data: request.toJson(),
/// );
/// ```
///
/// Nothing in the bloc or the UI should need to change.
@lazySingleton
class RouteSupportDataSource {
  /// Simulated latency, so loading states are actually exercised in
  /// development rather than resolving in the same frame.
  static const Duration _fakeLatency = Duration(milliseconds: 600);
  static const Duration _fakeSendLatency = Duration(milliseconds: 350);

  /// Name the mock agent answers under. The real payload carries this per
  /// message.
  static const String _agentName = 'Nick Rose';

  /// The thread for [request], oldest first.
  Future<NetworkResponse<List<RouteSupportMessage>>> getConversation(
    RouteSupportRequest request,
  ) async {
    await Future.delayed(_fakeLatency);

    try {
      final now = DateTime.now();
      return NetworkResponse<List<RouteSupportMessage>>(
        data: [
          RouteSupportMessage(
            id: 'mock-request-${request.routeId}',
            author: RouteSupportAuthor.driver,
            body: "I'd like to take this route. Could you please review it?",
            highlight: 'Selected Route: ${request.alternativeLabel}',
            sentAt: now.subtract(const Duration(minutes: 6)),
            card: request.card,
          ),
          RouteSupportMessage(
            id: 'mock-ack-${request.routeId}',
            author: RouteSupportAuthor.agent,
            senderName: _agentName,
            body: "Hello! We have received your request. We'll review it and "
                'get back to you as soon as possible. Please wait.',
            sentAt: now.subtract(const Duration(minutes: 4)),
          ),
          RouteSupportMessage(
            id: 'mock-suggestion-${request.routeId}',
            author: RouteSupportAuthor.agent,
            senderName: _agentName,
            body: "We don't recommend this route. We suggest taking "
                'Alternative 2 instead.',
            sentAt: now.subtract(const Duration(minutes: 2)),
            card: _suggestedRoute(request),
            showDriveAction: true,
          ),
        ],
      );
    } catch (e) {
      return NetworkResponse<List<RouteSupportMessage>>(errorText: e.toString());
    }
  }

  /// Posts a follow-up from the driver. Echoed straight back as the stored
  /// message, which is what the real endpoint will return.
  Future<NetworkResponse<RouteSupportMessage>> sendMessage({
    required RouteSupportRequest request,
    required String text,
  }) async {
    await Future.delayed(_fakeSendLatency);

    try {
      return NetworkResponse<RouteSupportMessage>(
        data: RouteSupportMessage(
          id: 'mock-sent-${DateTime.now().microsecondsSinceEpoch}',
          author: RouteSupportAuthor.driver,
          body: text,
          sentAt: DateTime.now(),
        ),
      );
    } catch (e) {
      return NetworkResponse<RouteSupportMessage>(errorText: e.toString());
    }
  }

  /// The route support "suggests" instead (docs/ui/8-2-2.png).
  ///
  /// Built from the driver's own endpoints and toll stops so the card reads as
  /// a real answer to a real question. A fuel stop is appended because the
  /// toll API never returns fuel stations as a list - see [RouteSupportStop] -
  /// and the design's card shows one; canned stops fill in when the selected
  /// alternative had no toll markers at all.
  RouteSupportRouteCard _suggestedRoute(RouteSupportRequest request) {
    final stops = <RouteSupportStop>[
      ...request.stops.take(2),
      const RouteSupportStop(
        kind: RouteSupportStopKind.fuel,
        title: 'Alixon Fuel, 3301 Kuhn Rd, West Memphis, AR',
        priceText: r'$5-8',
        priceNote: 'for gallon',
      ),
    ];
    if (request.stops.isEmpty) {
      stops.insertAll(0, const [
        RouteSupportStop(
          kind: RouteSupportStopKind.toll,
          title: 'I-40 West Memphis Toll Plaza',
          priceText: r'-$34.00',
        ),
      ]);
    }
    return RouteSupportRouteCard(
      originLabel: request.origin.fieldLabel,
      destinationLabel: request.destination.fieldLabel,
      stops: stops,
    );
  }
}
