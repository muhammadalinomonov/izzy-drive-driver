class GenericPagination<T> {
  final bool status;
  final String message;
  final int total;
  final String? next;
  final String previous;
  final List<T>? data;

  const GenericPagination({
    this.total = 0,
    this.next,
    this.previous = '',
    this.status = false,
    this.message = '',
    this.data = const [],
  });

  factory GenericPagination.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return GenericPagination<T>(
      total: json['total'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String? ?? '',
      status: json['status'] as bool,
      message: json['message'] as String,
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => fromJsonT(item))
          .toList(growable: false) ?? const [],
    );
  }
}

