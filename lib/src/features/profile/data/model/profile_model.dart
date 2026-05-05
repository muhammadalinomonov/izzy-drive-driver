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
  final String truckName;
  final int wsId;
  final int driverId;

  const ProfileModel({
     this.truckName = '',
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

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      email: toStr(json['email']),
      truckmodel: toStr(json['truck_model']),
      fullName: toStr(json['full_name']),
      mechanicName: toStr(json['mechanic_name']),
      mechanicId: toInt(json['mechanic_id']),
      photo: toStr(json['photo']),
      truckImage: toStr(json['truck_image']),
      truckName: toStr(json['truck_mar']),
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
