import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position?> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied');
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        print('Location permission permanently denied');
        return null;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print(
        'Current location:  [32m${position.latitude}, ${position.longitude} [0m',
      );
      return position;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Continuous GPS updates for Driving Mode, at navigation grade.
  ///
  /// Distance-filtered (not time-filtered) so the stream fires on real
  /// movement rather than ticking while parked. The 3 m filter is deliberately
  /// tight: [DrivingSession] smooths these fixes through a Kalman filter and
  /// interpolates the marker between them, so a coarse filter shows up
  /// directly as a stuttering marker. Server reporting is throttled
  /// separately, by time, in `NavigationBloc` - this rate never reaches the
  /// API.
  ///
  /// Background behaviour is platform-specific and required: without it the
  /// stream dies the moment the driver leaves the app, taking progress
  /// reporting with it.
  /// - iOS: `allowBackgroundLocationUpdates` plus the automotive activity
  ///   type, which also stops iOS pausing updates on its own heuristics.
  ///   Needs the `location` UIBackgroundMode in Info.plist.
  /// - Android: a foreground-service notification, which the OS requires for
  ///   sustained background location.
  Stream<Position> watchPosition({int distanceFilterMeters = 3}) {
    late final LocationSettings settings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: distanceFilterMeters,
        intervalDuration: const Duration(seconds: 1),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Easy Drive',
          notificationText: 'Navigation active',
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: distanceFilterMeters,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    } else {
      settings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: distanceFilterMeters,
      );
    }
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  Future<String?> getAddressFromLatLng(
    double latitude,
    double longitude,
  ) async {
    try {
      print('getAddressFromLatLng worked');
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        final parts = [
          place.name,
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
          place.postalCode,
        ].where((p) => p != null && p.trim().isNotEmpty).toSet().join(', ');
        final fullAddress = parts.isEmpty ? null : parts;

        print('Full Address: $fullAddress');
        return fullAddress;
      } else {
        print('No address available for this location.');
        return null;
      }
    } catch (e) {
      print('Error on  getAddressFromLatLng: $e');
      return null;
    }
  }
}
