import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

/// Wraps the user input for order creation.
/// Convert to multipart [FormData] via [toFormData] before sending to
/// `POST /drivers/create-report/`.
class OrderCreateRequestModel {
  const OrderCreateRequestModel({
    required this.text,
    required this.voiceFile,
    required this.voicePeaks,
    required this.photos,
    required this.price,
    required this.latitude,
    required this.longitude,
  });

  final String text;
  final File? voiceFile;
  // Normalized amplitude samples (0..1). Forwarded so the mechanic app can
  // render the same bars without re-reading the audio file. Trim heavy
  // lists down to 128 entries — that's already more than the rendered bar
  // count, and the backend caps to 256 anyway.
  final List<double> voicePeaks;
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
      if (voicePeaks.isNotEmpty) {
        final trimmed = voicePeaks.length > 128
            ? _resample(voicePeaks, 128)
            : voicePeaks;
        // Multipart form-data fields are strings — JSON-encode the list.
        form.fields.add(MapEntry(
          'voice_peaks',
          jsonEncode(trimmed.map((v) => double.parse(v.toStringAsFixed(3))).toList()),
        ));
      }
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

/// Downsamples [src] to [target] entries by bucket-averaging. Pure func
/// kept top-level so it stays testable.
List<double> _resample(List<double> src, int target) {
  if (src.length <= target) return src;
  final out = <double>[];
  final bucket = src.length / target;
  for (var i = 0; i < target; i++) {
    final start = (i * bucket).floor();
    final end = ((i + 1) * bucket).floor().clamp(start + 1, src.length);
    var sum = 0.0;
    for (var j = start; j < end; j++) {
      sum += src[j];
    }
    out.add(sum / (end - start));
  }
  return out;
}
