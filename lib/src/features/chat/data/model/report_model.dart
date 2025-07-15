import 'dart:io';

import 'package:dio/dio.dart';

class ReportModel {
  final String text;
  final List<File> images;
  final File? voiceFile; // Changed to File? for null safety with File type
  final String price;
  final double latitude;
  final double longitude;

  ReportModel({
    required this.text,
    required this.images,
    this.voiceFile,
    required this.price,
    required this.latitude,
    required this.longitude,
  });

  // Convert to JSON for non-multipart serialization (if needed)
  Map<String, dynamic> toJson() => {
    'text': text,
    'price': price,
    'latitude': latitude.toString(),
    'longitude': longitude.toString(),
  };

  // Helper method to prepare FormData for multipart request
  FormData toFormData() {
    var formData = FormData.fromMap({
      'text': text,
      'price': price,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    });

    // Add images
    for (var image in images) {
      formData.files.add(
        MapEntry(
          'images',
          MultipartFile.fromFileSync(image.path, filename: image.path.split('/').last),
        ),
      );
    }

    // Add voice file if it exists
    if (voiceFile != null) {
      formData.files.add(
        MapEntry(
          'voice_file',
          MultipartFile.fromFileSync(voiceFile!.path, filename: voiceFile!.path.split('/').last),
        ),
      );
    }

    return formData;
  }
}