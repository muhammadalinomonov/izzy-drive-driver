import 'package:dio/dio.dart';

extension StatusCodeExtension on Response {
  bool get isSuccess =>
      statusCode != null && statusCode! >= 200 && statusCode! < 300;
}
