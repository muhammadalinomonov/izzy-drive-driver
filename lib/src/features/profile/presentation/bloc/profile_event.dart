part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {}

class UploadAvatarEvent extends ProfileEvent {
  final File file;
  final VoidCallback? onSuccess;
  final void Function(String message)? onError;

  UploadAvatarEvent({required this.file, this.onSuccess, this.onError});

  @override
  List<Object?> get props => [file.path];
}

class GetOutputsEvent extends ProfileEvent {}

class CreateOutputEvent extends ProfileEvent {
  final String title;
  final String amount;
  final String date;
  final VoidCallback onSuccess;
  final Function(String) onError;

  CreateOutputEvent({
    required this.title,
    required this.amount,
    required this.date,
    required this.onSuccess,
    required this.onError,
  });

  @override
  List<Object?> get props => [title, amount, date];
}

class UpdatePasswordEvent extends ProfileEvent {
  final String oldPassword;
  final String newPassword;
  final VoidCallback onSuccess;
  final Function(String errorMessage) onError;

  UpdatePasswordEvent({
    required this.oldPassword,
    required this.newPassword,
    required this.onSuccess,
    required this.onError,
  });

  @override
  List<Object?> get props => [oldPassword, newPassword, onSuccess, onError];
}
