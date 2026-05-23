import 'dart:io';

import 'package:taxi_app/src/core/utils/json_safe.dart';

class DriverInfoPutModel {
  /// Lokal fayl - yangi tanlangan rasm. Backend'ga multipart sifatida
  /// `truck_image` field nomi bilan yuboriladi. `null` bo'lsa, mavjud
  /// rasm o'zgarishsiz qoldiriladi.
  final File? truckImageFile;
  final String avatar;
  final String truckImage;
  final String truckMark;
  final String truckModel;
  final String truckYear;
  final String phoneNumber;
  final String licenseNumber;
  final String address;

  DriverInfoPutModel({
    this.truckImageFile,
    required this.avatar,
    required this.truckImage,
    required this.truckMark,
    required this.truckModel,
    required this.truckYear,
    required this.phoneNumber,
    required this.licenseNumber,
    required this.address,
  });

  factory DriverInfoPutModel.fromJson(Map<String, dynamic> json) {
    return DriverInfoPutModel(
      avatar: toStr(json['avatar']),
      truckImage: toStr(json['truck_image']),
      truckMark: toStr(json['truck_mark']),
      truckModel: toStr(json['truck_model']),
      truckYear: toStr(json['truck_year']),
      phoneNumber: toStr(json['phone_number']),
      licenseNumber: toStr(json['license_number']),
      address: toStr(json['address']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avatar': avatar,
      'truck_image': truckImage,
      'truck_mark': truckMark,
      'truck_model': truckModel,
      'truck_year': truckYear,
      'phone_number': phoneNumber,
      'license_number': licenseNumber,
      'address': address,
    };
  }
}
