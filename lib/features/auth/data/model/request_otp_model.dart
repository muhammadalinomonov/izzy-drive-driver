import 'package:json_annotation/json_annotation.dart';

part 'request_otp_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class RequestOtpModel {
  final String email;
  final int expiresIn;
  final int resendAfter;

  const RequestOtpModel({
    required this.email,
    required this.expiresIn,
    required this.resendAfter,
  });

  factory RequestOtpModel.fromJson(Map<String, dynamic> json) =>
      _$RequestOtpModelFromJson(json);

  Map<String, dynamic> toJson() => _$RequestOtpModelToJson(this);
}
