part of 'profile_bloc.dart';

class ProfileState extends Equatable {
  final ProfileModel? profile;
  final String? message;
  final ProfileStatus status;
  final FormzSubmissionStatus outputsStatus;
  final List<OutPutEntity> outputs;
  final String totalAmount;
  final FormzSubmissionStatus createOutputStatus;
  final FormzSubmissionStatus updatePasswordStatus;
  final FormzSubmissionStatus uploadAvatarStatus;

  const ProfileState({
    this.profile,
    this.message,
    this.status = ProfileStatus.initial,
    this.outputsStatus = FormzSubmissionStatus.initial,
    this.outputs = const [],
    this.totalAmount = '',
    this.createOutputStatus = FormzSubmissionStatus.initial,
    this.updatePasswordStatus = FormzSubmissionStatus.initial,
    this.uploadAvatarStatus = FormzSubmissionStatus.initial,
  });

  ProfileState copyWith({
    ProfileModel? profile,
    String? message,
    ProfileStatus? status,
    FormzSubmissionStatus? outputsStatus,
    List<OutPutEntity>? outputs,
    String? totalAmount,
    FormzSubmissionStatus? createOutputStatus,
    FormzSubmissionStatus? updatePasswordStatus,
    FormzSubmissionStatus? uploadAvatarStatus,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      message: message ?? this.message,
      status: status ?? this.status,
      outputsStatus: outputsStatus ?? this.outputsStatus,
      outputs: outputs ?? this.outputs,
      totalAmount: totalAmount ?? this.totalAmount,
      createOutputStatus: createOutputStatus ?? this.createOutputStatus,
      updatePasswordStatus: updatePasswordStatus ?? this.updatePasswordStatus,
      uploadAvatarStatus: uploadAvatarStatus ?? this.uploadAvatarStatus,
    );
  }

  @override
  List<Object?> get props => [
    profile,
    message,
    status,
    outputsStatus,
    outputs,
    totalAmount,
    createOutputStatus,
    updatePasswordStatus,
    uploadAvatarStatus,
  ];
}

enum ProfileStatus { initial, loading, loaded, error }
