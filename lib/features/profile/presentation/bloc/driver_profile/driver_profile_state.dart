part of 'driver_profile_bloc.dart';

enum DriverProfileStatus { initial, loading, success, failure }

class DriverProfileState extends Equatable {
  final DriverProfileStatus status;

  /// Tracked apart from [status] so saving doesn't put the whole screen back
  /// into a loading state.
  final DriverProfileStatus saveStatus;

  final DriverProfileModel? profile;
  final List<VehicleModel> vehicles;

  /// The vehicles call failed while the profile succeeded, so that section
  /// shows its own retry instead of failing the screen.
  final bool vehiclesFailed;

  final String errorMessage;
  final String errorCode;

  const DriverProfileState({
    this.status = DriverProfileStatus.initial,
    this.saveStatus = DriverProfileStatus.initial,
    this.profile,
    this.vehicles = const [],
    this.vehiclesFailed = false,
    this.errorMessage = '',
    this.errorCode = '',
  });

  bool get isPremium => profile?.isPaidUser ?? false;

  /// Nothing to show yet and nothing in flight - the empty state.
  bool get isEmpty =>
      profile == null && status != DriverProfileStatus.loading;

  static const _sentinel = Object();

  DriverProfileState copyWith({
    DriverProfileStatus? status,
    DriverProfileStatus? saveStatus,
    Object? profile = _sentinel,
    List<VehicleModel>? vehicles,
    bool? vehiclesFailed,
    String? errorMessage,
    String? errorCode,
  }) {
    return DriverProfileState(
      status: status ?? this.status,
      saveStatus: saveStatus ?? this.saveStatus,
      profile: identical(profile, _sentinel)
          ? this.profile
          : profile as DriverProfileModel?,
      vehicles: vehicles ?? this.vehicles,
      vehiclesFailed: vehiclesFailed ?? this.vehiclesFailed,
      errorMessage: errorMessage ?? this.errorMessage,
      errorCode: errorCode ?? this.errorCode,
    );
  }

  @override
  List<Object?> get props => [
        status,
        saveStatus,
        profile?.id,
        profile?.displayName,
        profile?.phone,
        profile?.licenseLabel,
        profile?.isPaidUser,
        vehicles.length,
        vehiclesFailed,
        errorMessage,
        errorCode,
      ];
}
