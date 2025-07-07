class DriverInfoPutModel {
  final String avatar;
  final String truckImage;
  final String truckMark;
  final String truckModel;
  final String truckYear;
  final String phoneNumber;
  final String licenseNumber;
  final String address;

  DriverInfoPutModel({
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
      avatar: json['avatar'],
      truckImage: json['truck_image'],
      truckMark: json['truck_mark'],
      truckModel: json['truck_model'],
      truckYear: json['truck_year'],
      phoneNumber: json['phone_number'],
      licenseNumber: json['license_number'],
      address: json['address'],
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
