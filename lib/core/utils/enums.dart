enum LocationPermissionStatus {
  locationServiceDisabled,
  permissionDenied,
  permissionGranted;

  bool get isLocationServiceDisabled => this == LocationPermissionStatus.locationServiceDisabled;

  bool get isPermissionDenied => this == LocationPermissionStatus.permissionDenied;

  bool get isPermissionGranted => this == LocationPermissionStatus.permissionGranted;
}
