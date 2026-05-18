import 'package:taxi_app/src/core/utils/json_safe.dart';

class ProfileResponse {
  final bool status;
  final String message;
  final ProfileModel data;

  ProfileResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      status: toBool(json['status']),
      message: toStr(json['message']),
      data: ProfileModel.fromJson(toMap(json['data'])),
    );
  }
}

class ProfileModel {
  final int id;
  final String email;
  final String fullName;
  ///for selected mechanic name
  final String mechanicName;
  final int mechanicId;
  final String photo;
  final String truckImage;
  final String truckYear;
  final String phoneNumber;
  final String licenseNumber;
  final String deviceToken;
  final String truckmodel;
  final String truckMark;
  final int wsId;
  final int driverId;

  const ProfileModel({
     this.truckMark = '',
     this.email = '',
     this.truckmodel = '',
     this.fullName = '',
    this.mechanicName = '',
    this.mechanicId = 0,
     this.photo = '',
     this.truckImage = '',
     this.truckYear = '',
     this.phoneNumber = '',
     this.licenseNumber = '',
     this.deviceToken = '',
     this.wsId = -1,
     this.driverId = -1,
     this.id = -1,
  });

  ProfileModel copyWith({
    int? id,
    String? email,
    String? fullName,
    String? mechanicName,
    int? mechanicId,
    String? photo,
    String? truckImage,
    String? truckYear,
    String? phoneNumber,
    String? licenseNumber,
    String? deviceToken,
    String? truckmodel,
    String? truckMark,
    int? wsId,
    int? driverId,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      mechanicName: mechanicName ?? this.mechanicName,
      mechanicId: mechanicId ?? this.mechanicId,
      photo: photo ?? this.photo,
      truckImage: truckImage ?? this.truckImage,
      truckYear: truckYear ?? this.truckYear,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      deviceToken: deviceToken ?? this.deviceToken,
      truckmodel: truckmodel ?? this.truckmodel,
      truckMark: truckMark ?? this.truckMark,
      wsId: wsId ?? this.wsId,
      driverId: driverId ?? this.driverId,
    );
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      email: toStr(json['email']),
      truckmodel: toStr(json['truck_model']),
      fullName: toStr(json['full_name']),
      mechanicName: toStr(json['mechanic_name']),
      mechanicId: toInt(json['mechanic_id']),
      photo: toStr(json['photo']),
      truckImage: toStr(json['truck_image']),
      truckMark: toStr(json['truck_mark']),
      truckYear: toStr(json['truck_year']),
      phoneNumber: toStr(json['phone_number']),
      licenseNumber: toStr(json['license_number']),
      deviceToken: toStr(json['device_token']),
      wsId: toInt(json['ws_id']),
      driverId: toInt(json['driver_id']),
      id: toInt(json['id']),
    );
  }
}
