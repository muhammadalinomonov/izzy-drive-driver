import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/core/session/premium_session.dart';
import 'package:taxi_app/features/profile/data/model/driver_profile_model.dart';
import 'package:taxi_app/features/profile/domain/repository/driver_profile_repository.dart';
import 'package:taxi_app/features/trips/data/model/vehicle_model.dart';

part 'driver_profile_event.dart';
part 'driver_profile_state.dart';

/// Drives the redesigned Profile screen off the Quadrix Tolling endpoints.
///
/// Profile and vehicles are fetched together but tracked separately: a driver
/// with no truck assigned still has a perfectly good profile, and a failed
/// vehicles call must not blank the header.
class DriverProfileBloc extends Bloc<DriverProfileEvent, DriverProfileState> {
  final DriverProfileRepository repo;

  DriverProfileBloc({required this.repo}) : super(const DriverProfileState()) {
    on<DriverProfileLoaded>(_onLoad);
    on<DriverProfileRefreshed>(_onRefresh);
    on<DriverProfileUpdated>(_onUpdate);
  }

  Future<void> _onLoad(
    DriverProfileLoaded event,
    Emitter<DriverProfileState> emit,
  ) async {
    if (state.status == DriverProfileStatus.loading) return;
    emit(state.copyWith(
      status: DriverProfileStatus.loading,
      errorMessage: '',
    ));
    await _fetch(emit);
  }

  /// Pull-to-refresh keeps whatever is on screen: the refresh spinner is the
  /// visible progress affordance, so collapsing back to a skeleton would be a
  /// downgrade.
  Future<void> _onRefresh(
    DriverProfileRefreshed event,
    Emitter<DriverProfileState> emit,
  ) async {
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<DriverProfileState> emit) async {
    // Both in flight at once - neither depends on the other.
    final profileFuture = repo.fetchProfile();
    final vehiclesFuture = repo.fetchVehicles();

    final profileResponse = await profileFuture;
    final vehiclesResponse = await vehiclesFuture;

    if (profileResponse.errorText.isNotEmpty || profileResponse.data == null) {
      emit(state.copyWith(
        // A failed refresh with data already on screen shouldn't blank it.
        status: state.profile == null
            ? DriverProfileStatus.failure
            : DriverProfileStatus.success,
        errorMessage: profileResponse.errorText,
        errorCode: profileResponse.errorCode ?? '',
      ));
      return;
    }

    final profile = profileResponse.data!;
    // Publish the entitlement globally before the UI paints, so premium-gated
    // widgets elsewhere resolve on the same frame as the profile header.
    await PremiumSession.update(profile.isPaidUser);

    emit(state.copyWith(
      status: DriverProfileStatus.success,
      profile: profile,
      // Vehicles failing is survivable - keep the previous list and let the
      // section show its own error rather than failing the whole screen.
      vehicles: vehiclesResponse.errorText.isEmpty
          ? (vehiclesResponse.data ?? const [])
          : state.vehicles,
      vehiclesFailed: vehiclesResponse.errorText.isNotEmpty,
      errorMessage: '',
      errorCode: '',
    ));
  }

  Future<void> _onUpdate(
    DriverProfileUpdated event,
    Emitter<DriverProfileState> emit,
  ) async {
    emit(state.copyWith(
      saveStatus: DriverProfileStatus.loading,
      errorMessage: '',
    ));

    final response = await repo.updateProfile(
      firstName: event.firstName,
      lastName: event.lastName,
      phone: event.phone,
      licenseNumber: event.licenseNumber,
      licenseState: event.licenseState,
    );

    if (response.errorText.isNotEmpty || response.data == null) {
      emit(state.copyWith(
        saveStatus: DriverProfileStatus.failure,
        errorMessage: response.errorText,
        errorCode: response.errorCode ?? '',
      ));
      event.onError?.call(response.errorText);
      return;
    }

    final profile = response.data!;
    await PremiumSession.update(profile.isPaidUser);
    emit(state.copyWith(
      saveStatus: DriverProfileStatus.success,
      status: DriverProfileStatus.success,
      profile: profile,
      errorMessage: '',
    ));
    // Navigation stays with the caller, per this repo's callback-event style.
    event.onSuccess?.call();
  }
}
