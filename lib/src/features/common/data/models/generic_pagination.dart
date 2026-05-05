import 'package:taxi_app/src/core/utils/json_safe.dart';

class GenericPagination<T> {
  final bool status;
  final String message;
  final int total;
  final String? next;
  final String previous;
  final List<T>? data;
  final double totalSum;

  const GenericPagination({
    this.total = 0,
    this.next,
    this.previous = '',
    this.status = false,
    this.message = '',
    this.data = const [],
    this.totalSum = 0,
  });

  factory GenericPagination.fromJson(Map<String, dynamic> json, T Function(dynamic json) fromJsonT) {
    return GenericPagination<T>(
      total: toInt(json['total']),
      next: toStrNullable(json['next']),
      previous: toStr(json['previous']),
      status: toBool(json['status']),
      message: toStr(json['message']),
      data: toList(json['data'], (item) => fromJsonT(item)),
      totalSum: toDouble(json['total_balance']),
    );
  }
}
