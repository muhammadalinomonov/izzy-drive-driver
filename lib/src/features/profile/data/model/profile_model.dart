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
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: ProfileModel.fromJson(json['data'] ?? {}),
    );
  }
}

class ProfileModel {
  final int id;
  final String email;
  final String fullName;
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
      email: json['email'] ?? '',
      truckmodel: json['truck_model'] ?? '',
      fullName: json['full_name'] ?? '',
      photo: json['photo'] ?? '',
      truckImage: json['truck_image'] ?? '',
      truckName: json['truck_mar'] ?? '',
      truckYear: json['truck_year'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      licenseNumber: json['license_number'] ?? '',
      deviceToken: json['device_token'] ?? '',
      wsId: json['ws_id'] ?? 0,
      driverId: json['driver_id'] ?? 0,
      id: json['id']??0,
    );
  }
}
