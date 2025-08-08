
class BaseModel<T> {
  final bool status;
  final String message;
  final T? data;

  const BaseModel({
    this.status = false,
    this.message = '',
    this.data,
  });

  factory BaseModel.fromJson(
      Map<String, dynamic> json,
      T Function(dynamic json) fromJsonT,
      ) {
    return BaseModel<T>(
      status: json['status'] as bool,
      message: json['message'] as String,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }
}