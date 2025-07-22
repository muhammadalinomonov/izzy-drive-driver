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
}
