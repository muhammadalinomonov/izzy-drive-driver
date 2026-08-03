part of 'driver_profile_bloc.dart';

sealed class DriverProfileEvent extends Equatable {
  const DriverProfileEvent();

  @override
  List<Object?> get props => [];
}

/// First load, behind the skeleton.
class DriverProfileLoaded extends DriverProfileEvent {
  const DriverProfileLoaded();
}

/// Pull-to-refresh; keeps the current content on screen while it runs.
class DriverProfileRefreshed extends DriverProfileEvent {
  const DriverProfileRefreshed();
}

/// Saves edited fields via `PATCH mobile/profile`. Only non-null values are
/// sent, so this works for a single field or the whole form.
///
/// Carries [onSuccess] / [onError] callbacks in this repo's established style
/// - the page pops or shows a message from them, keeping navigation out of
/// the bloc.
class DriverProfileUpdated extends DriverProfileEvent {
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? licenseNumber;
  final String? licenseState;
  final VoidCallback? onSuccess;
  final void Function(String message)? onError;

  const DriverProfileUpdated({
    this.firstName,
    this.lastName,
    this.phone,
    this.licenseNumber,
    this.licenseState,
    this.onSuccess,
    this.onError,
  });

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        phone,
        licenseNumber,
        licenseState,
      ];
}
