import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:taxi_app/src/features/profile/data/model/profile_model.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repository/profile_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;

  ProfileBloc(this.repository)
    : super(ProfileState(status: ProfileStatus.initial)) {
    on<LoadProfile>((event, emit) async {
      emit(ProfileState(status: ProfileStatus.loading));
      final result = await repository.getProfile();
      if (result.errorText.isEmpty) {
        print((result.data as ProfileModel));
        emit(ProfileState(profile: result.data, status: ProfileStatus.loaded));
      } else {
        emit(
          ProfileState(status: ProfileStatus.error, message: result.errorText),
        );
      }
    });
  }
}
