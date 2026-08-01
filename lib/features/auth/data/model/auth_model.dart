import 'package:taxi_app/core/utils/json_safe.dart';

class AuthModel {
  final String email;
  final String password;
  final String deviceToken;
  final String fullName;

  AuthModel({
    required this.email,
    required this.password,
    required this.fullName,
    required this.deviceToken,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'email': email,
      'password': password,
      'deviceToken': deviceToken,
      'full_Name': fullName,
      "is_driver": true,
      "is_mechanic": false,
    };
  }

  factory AuthModel.fromMap(Map<String, dynamic> map) {
    return AuthModel(
      fullName: toStr(map['full_Name']),
      email: toStr(map['email']),
      password: toStr(map['password']),
      deviceToken: toStr(map['deviceToken']),
    );
  }
}
