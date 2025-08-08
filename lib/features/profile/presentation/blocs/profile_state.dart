part of 'profile_bloc.dart';

@immutable
class ProfileState extends Equatable {
  final FormzSubmissionStatus updateStatusStatus;
  final String? errorMessage;
  final FormzSubmissionStatus getProfileStatus;
  final UserEntity user;
  final String status;
  final FormzSubmissionStatus updateCurrentLocationStatus;

  const ProfileState({
    this.updateStatusStatus = FormzSubmissionStatus.initial,
    this.errorMessage,
    this.getProfileStatus = FormzSubmissionStatus.initial,
    this.user = const UserEntity(),
    this.status = '',
    this.updateCurrentLocationStatus = FormzSubmissionStatus.initial,
  });

  ProfileState copyWith({
    FormzSubmissionStatus? updateStatusStatus,
    String? errorMessage,
    FormzSubmissionStatus? getProfileStatus,
    UserEntity? user,
    String? status,
    FormzSubmissionStatus? updateCurrentLocationStatus,
  }) {
    return ProfileState(
      updateStatusStatus: updateStatusStatus ?? this.updateStatusStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      getProfileStatus: getProfileStatus ?? this.getProfileStatus,
      user: user ?? this.user,
      status: status ?? this.status,
      updateCurrentLocationStatus: updateCurrentLocationStatus ?? this.updateCurrentLocationStatus,
    );
  }

  @override
  List<Object?> get props => [
        updateStatusStatus,
        errorMessage,
        getProfileStatus,
        user,
        status,
        updateCurrentLocationStatus,
      ];
}
