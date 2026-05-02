import 'dart:io';

import 'package:dio/dio.dart';

/// Wraps the user input for order creation.
/// Convert to multipart [FormData] via [toFormData] before sending to
/// `POST /drivers/create-report/`.
class OrderCreateRequestModel {
  const OrderCreateRequestModel({
    required this.text,
    required this.voiceFile,
    required this.photos,
    required this.price,
    required this.latitude,
    required this.longitude,
  });

  final String text;
  final File? voiceFile;
  final List<File> photos;
  final String price; // raw digits, no formatting
  final double latitude;
  final double longitude;

  Future<FormData> toFormData() async {
    final form = FormData();
    form.fields
      ..add(MapEntry('text', text))
      ..add(MapEntry('price', price))
      ..add(MapEntry('latitude', latitude.toString()))
      ..add(MapEntry('longitude', longitude.toString()));

    if (voiceFile != null) {
      form.files.add(MapEntry(
        'voice_file',
        await MultipartFile.fromFile(voiceFile!.path),
      ));
    }
    for (final photo in photos) {
      form.files.add(MapEntry(
        'images',
        await MultipartFile.fromFile(photo.path),
      ));
    }
    return form;
  }
}
