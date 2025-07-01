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
      fullName: map['full_Name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      deviceToken: map['deviceToken'] as String,
    );
  }
}
