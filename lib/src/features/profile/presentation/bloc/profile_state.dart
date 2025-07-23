part of 'profile_bloc.dart';

class ProfileState extends Equatable {
  final ProfileModel? profile;
  final String? message;
  final ProfileStatus status;

  ProfileState({this.profile, this.message, required this.status});

  @override
  List<Object?> get props => [profile, message, status];
}

enum ProfileStatus { initial, loading, loaded, error }
