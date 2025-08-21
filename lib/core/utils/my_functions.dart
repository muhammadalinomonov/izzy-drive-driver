import 'dart:ui' as ui;

import 'package:mechanic/assets/constants/icons.dart';
import 'package:mechanic/assets/constants/images.dart';
import 'package:mechanic/core/utils/enums.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:yandex_mapkit/yandex_mapkit.dart';

class MyFunctions {
  // static Future<BitmapDescriptor> getBitmap({
  //   required String asset,
  //   required int size,
  // }) async {
  //   ByteData data = await rootBundle.load(asset);
  //   ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: size);
  //   ui.FrameInfo fi = await codec.getNextFrame();
  //   Uint8List markerIcon = (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  //   return BitmapDescriptor.fromBytes(markerIcon);
  // }

  // static Future<LocationPermissionStatus> getLocationPermission() async {
  //   try {
  //     final isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
  //     if (!isLocationServiceEnabled) {
  //       return LocationPermissionStatus.locationServiceDisabled;
  //     } else {
  //       final permission = await Geolocator.checkPermission();
  //       if (permission == LocationPermission.denied) {
  //         return LocationPermissionStatus.permissionDenied;
  //       } else if (permission == LocationPermission.deniedForever) {
  //         return LocationPermissionStatus.permissionDenied;
  //       } else {
  //         return LocationPermissionStatus.permissionGranted;
  //       }
  //     }
  //   } catch (e) {
  //     return LocationPermissionStatus.permissionDenied;
  //   }
  // }

  // static Future<Position?> getCurrentPosition() async {
  //   try {
  //     return await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
  //   } catch (e) {
  //     return null;
  //   }
  // }
  static String formatCost(dynamic cost, {bool withRounding = true}) {
    if (cost is String) {
      return cost;
    }
    if (cost is num) {
      int rounded =withRounding? ((cost / 1000).round() * 1000) : cost.round();
      return rounded.toString().replaceAllMapped(
        RegExp(r'(?<=\d)(?=(\d{3})+$)'),
            (match) => ' ',
      );
    }
    return cost.toString();
  }

  static String formatCustomDate(String dateString) {
    try {
      print(DateTime.now().toString());
      DateTime now = DateTime.now();
      DateFormat inputFormat = DateFormat("MMM dd, yyy'yy' HH:mm:ss");
      DateTime dateTime = inputFormat.parse(dateString);

      DateFormat timeFormat = DateFormat("HH:mm");
      DateFormat fullDateFormat = DateFormat("dd.MM.yyyy, HH:mm");

      if (DateFormat("yyyy-MM-dd").format(dateTime) == DateFormat("yyyy-MM-dd").format(now)) {
        return "Bugun, ${timeFormat.format(dateTime)}";
      } else if (DateFormat("yyyy-MM-dd").format(dateTime) ==
          DateFormat("yyyy-MM-dd").format(now.subtract(Duration(days: 1)))) {
        return "Kecha, ${timeFormat.format(dateTime)}";
      } else {
        return fullDateFormat.format(dateTime);
      }
    } catch (e) {
      return dateString;
    }
  }

  static String formatTimeAgo(String dateTimeStr) {
    try {
      final parsedDate = DateTime.parse(dateTimeStr).toLocal();
      final now = DateTime.now();
      final difference = now.difference(parsedDate);

      if (difference.inDays > 2) {
        final day = parsedDate.day.toString().padLeft(2, '0');
        final month = parsedDate.month.toString().padLeft(2, '0');
        final year = parsedDate.year.toString();
        return '$day.$month.$year';
      } else if (difference.inDays >= 1) {
        return '${difference.inDays} kun oldin';
      } else if (difference.inHours >= 1) {
        return '${difference.inHours} soat oldin';
      } else if (difference.inMinutes >= 1) {
        return '${difference.inMinutes} daqiqa oldin';
      } else {
        return 'Hozirgina';
      }
    } catch (e) {
      return 'Noto‘g‘ri sana';
    }
  }

  static String formatDate(String dateString) {
    final date = DateTime.parse(dateString).toLocal();
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final hhmm = "${twoDigits(date.hour)}:${twoDigits(date.minute)}";
    final full = "${twoDigits(date.day)}.${twoDigits(date.month)}.${date.year}, $hhmm";

    if (dateOnly == today) {
      return "Bugun, $hhmm";
    } else if (dateOnly == yesterday) {
      return "Kecha, $hhmm";
    } else {
      return full;
    }
  }



// static List<MapObject> getCarMapObjects(List<CarEntity> cars) {
  //   return cars.map((car) {
  //     if (car.isMyTaxi) {
  //       return ClusterizedPlacemarkCollection(
  //         mapId: const MapObjectId('cars-taxi'),
  //         placemarks: [
  //           PlacemarkMapObject(
  //             opacity: 1,
  //             mapId: const MapObjectId('car-taxi'),
  //             direction: car.angle.toDouble() + 55,
  //             // direction: r.location.angle.toDouble(),
  //             point: Point(
  //               latitude: (car.latitude is String) ? double.parse(car.latitude.toString()) : car.latitude,
  //               longitude: (car.longitude is String) ? double.parse(car.longitude.toString()) : car.longitude,
  //             ),
  //             // Example: Tashkent coordinates
  //             icon: PlacemarkIcon.single(
  //               PlacemarkIconStyle(
  //                 image: BitmapDescriptor.fromAssetImage(AppImages.taxiMarker),
  //                 scale: 1.15,
  //                 rotationType: RotationType.rotate,
  //               ),
  //             ),
  //           )
  //         ],
  //         radius: 50,
  //         minZoom: 0,
  //       );
  //     }
  //     return ClusterizedPlacemarkCollection(
  //       mapId: MapObjectId('cars ${car.id}'),
  //       placemarks: [
  //         PlacemarkMapObject(
  //           opacity: 1,
  //           direction: car.angle + 55,
  //           mapId: MapObjectId('car${car.id}'),
  //           point: Point(
  //             latitude: car.latitude,
  //             longitude: car.longitude,
  //           ),
  //           // Example: Tashkent coordinates
  //           icon: PlacemarkIcon.single(
  //             PlacemarkIconStyle(
  //               image: BitmapDescriptor.fromAssetImage(AppImages.carMarker),
  //               scale: 1.0,
  //               rotationType: RotationType.rotate,
  //             ),
  //           ),
  //         )
  //       ],
  //       radius: 50,
  //       minZoom: 0,
  //     );
  //   }).toList();
  // }

  // static String getCardIcon(String cardNumber){
  //   if(cardNumber.startsWith('9860') || cardNumber.startsWith('4067')){
  //     return AppImages.humo;
  //   }else{
  //     return AppImages.uzcard;
  //   }
  // }

}
