import 'package:equatable/equatable.dart';
import 'package:mechanic/features/auth/domain/entities/id_name_entity.dart';

class UserEntity extends Equatable {
  final int id;
  final String fullName;
  final String phoneNumber;
  final String status;
  final String photo;
  final String balance;
  final String deviceToken;
  final int wsId;
  final String email;


  const UserEntity({
    this.id = -1,
    this.phoneNumber = '',
    this.fullName = '',
    this.status = '',
    this.photo = '',
    this.balance = '',
    this.deviceToken = '',
    this.wsId = -1,
    this.email = '',
  });

  @override
  List<Object?> get props => [
        id,
        phoneNumber,
        fullName,
        status,
        photo,
        balance,
        deviceToken,
        wsId,
        email,
      ];
}
