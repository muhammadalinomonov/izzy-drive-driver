import 'package:dio/dio.dart';

class DioSettings {
  Dio dioData = Dio();

  BaseOptions _dioBaseOptions = BaseOptions(
    baseUrl: "https://master-api.ataxi.uz/api/v1/",
    connectTimeout: const Duration(minutes: 1),
    receiveTimeout: const Duration(minutes: 1),
    followRedirects: false,

    validateStatus: (status) => status != null && status <= 500,
  );

  void setBaseOptions({String? lang}) {
    _dioBaseOptions = BaseOptions(
      baseUrl: "https://master-api.ataxi.uz/api/v1/",
      connectTimeout: const Duration(minutes: 1),
      receiveTimeout: const Duration(minutes: 1),
      headers: <String, dynamic>{'Accept-Language': lang},
      followRedirects: false,
      validateStatus: (status) => status != null && status <= 500,
    );
  }

  BaseOptions get dioBaseOptions => _dioBaseOptions;

  Dio get dio {
    dioData.options = dioBaseOptions;
    return dioData;
  }
}
