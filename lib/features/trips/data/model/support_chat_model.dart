import 'package:taxi_app/core/utils/json_safe.dart';

/// One message in the driver's normal support conversation
/// (`GET/POST mobile/support-chat`, docs/mobile-api.md §8.1/§8.2).
///
/// The same shape also appears inside a route-review's `messages` array
/// (§8.3) - both contexts share this one wire format, distinguished only by
/// whether [routeReviewId] is set.
class SupportChatMessage {
  final String id;

  /// `driver` or `support` - no other value exists per §8.1.
  final bool isDriver;

  /// Display name of whoever sent it. Nullable on the wire (§8.1 note); empty
  /// string here degrades the same way every other model in this app treats
  /// a missing string.
  final String senderName;

  final String message;

  /// Set when this message belongs to a route-review thread rather than the
  /// generic conversation.
  final String? routeReviewId;

  final DateTime? createdAt;

  const SupportChatMessage({
    required this.id,
    required this.isDriver,
    required this.message,
    this.senderName = '',
    this.routeReviewId,
    this.createdAt,
  });

  factory SupportChatMessage.fromJson(Map<String, dynamic> json) {
    return SupportChatMessage(
      id: toStr(json['id']),
      isDriver: toStr(json['sender_type']).toLowerCase() == 'driver',
      senderName: toStr(json['sender_name']),
      message: toStr(json['message']),
      routeReviewId: toStrNullable(json['route_review_id']),
      createdAt: DateTime.tryParse(toStr(json['created_at'])),
    );
  }

  /// `23:00`, matching the timestamp already shown under a chat bubble
  /// elsewhere in the app. Empty when the server sent no timestamp.
  String get sentAtLabel {
    final at = createdAt;
    if (at == null) return '';
    final local = at.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

/// `GET mobile/support-chat` (docs §8.1): a page of the driver's single
/// support conversation.
///
/// [items] arrives **newest-first** from the API - the opposite of a
/// route-review's `messages` (§8.3) - so callers must not reuse the same
/// "append at the end" logic for both.
class SupportChatPage {
  final List<SupportChatMessage> items;
  final int page;
  final int perPage;
  final int total;
  final int lastPage;

  const SupportChatPage({
    required this.items,
    required this.page,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  factory SupportChatPage.fromJson(
    Map<String, dynamic> data,
    Map<String, dynamic> pagination,
  ) {
    return SupportChatPage(
      items: toList(data['items'], (e) => SupportChatMessage.fromJson(toMap(e))),
      page: toInt(pagination['page'], 1),
      perPage: toInt(pagination['per_page'], 50),
      total: toInt(pagination['total']),
      lastPage: toInt(pagination['last_page'], 1),
    );
  }
}
