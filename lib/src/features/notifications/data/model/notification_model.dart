import 'package:taxi_app/src/core/utils/json_safe.dart';

class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String? imageUrl;
  final bool isRead;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final createdRaw = toStrNullable(json['created_at']);
    return NotificationModel(
      id: toInt(json['id']),
      title: toStr(json['title']),
      body: toStr(json['body']),
      imageUrl: toStrNullable(json['image_url']),
      isRead: toBool(json['is_read']),
      createdAt: createdRaw == null ? null : DateTime.tryParse(createdRaw),
    );
  }

  NotificationModel copyWith({
    int? id,
    String? title,
    String? body,
    String? imageUrl,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class NotificationPage {
  final List<NotificationModel> items;
  final int total;
  final int totalPages;
  final int currentPage;
  final String? next;

  const NotificationPage({
    required this.items,
    required this.total,
    required this.totalPages,
    required this.currentPage,
    required this.next,
  });

  bool get hasMore => next != null && next!.isNotEmpty;

  factory NotificationPage.fromJson(Map<String, dynamic> json) {
    return NotificationPage(
      items: toList(json['data'], (e) => NotificationModel.fromJson(toMap(e))),
      total: toInt(json['total']),
      totalPages: toInt(json['total_pages']),
      currentPage: toInt(json['current_page']),
      next: toStrNullable(json['next']),
    );
  }
}
