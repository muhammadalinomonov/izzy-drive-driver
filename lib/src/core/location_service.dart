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

  /// Continuous GPS updates for Driving Mode. Distance-filtered (not
  /// time-filtered) so the stream only fires on meaningful movement instead
  /// of flooding the camera/progress-reporting logic while stationary.
  Stream<Position> watchPosition({int distanceFilterMeters = 15}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    );
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
