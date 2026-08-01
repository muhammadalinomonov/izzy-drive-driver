import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:taxi_app/features/order_create/data/model/order_message.dart';

/// Wraps the user input for order creation.
/// Convert to multipart [FormData] via [toFormData] before sending to
/// `POST /drivers/create-report/`.
///
/// Wire format (v2 — multi-message):
///   - `messages` — JSON array; each entry is one of
///       {"kind":"text","text":"..."}
///       {"kind":"audio","audio_index":N,"peaks":[...],"duration_ms":1234}
///   - `audio_files` — repeated multipart files, indexed by `audio_index`
///   - `images` — repeated multipart files (already plural pre-v2)
///   - `text`, `voice_file`, `voice_peaks` — legacy shim fields populated
///     from the first text/audio message so older backend builds still
///     receive something readable.
class OrderCreateRequestModel {
  const OrderCreateRequestModel({
    required this.messages,
    required this.photos,
    required this.price,
    required this.latitude,
    required this.longitude,
  });

  final List<OrderMessage> messages;
  final List<File> photos;
  final String price; // raw digits, no formatting
  final double latitude;
  final double longitude;

  Future<FormData> toFormData() async {
    final form = FormData();
    form.fields
      ..add(MapEntry('price', price))
      ..add(MapEntry('latitude', latitude.toString()))
      ..add(MapEntry('longitude', longitude.toString()));

    // Build the messages JSON + collect audio files in matching order.
    final messagesPayload = <Map<String, Object?>>[];
    final audioFiles = <File>[];
    for (final m in messages) {
      switch (m) {
        case OrderTextMessage():
          messagesPayload.add({'kind': 'text', 'text': m.text});
        case OrderAudioMessage():
          final index = audioFiles.length;
          audioFiles.add(m.file);
          final trimmedPeaks = m.peaks.length > 128
              ? _resample(m.peaks, 128)
              : m.peaks;
          messagesPayload.add({
            'kind': 'audio',
            'audio_index': index,
            'peaks': trimmedPeaks
                .map((v) => double.parse(v.toStringAsFixed(3)))
                .toList(),
            'duration_ms': m.duration.inMilliseconds,
          });
      }
    }
    form.fields.add(MapEntry('messages', jsonEncode(messagesPayload)));

    for (final f in audioFiles) {
      form.files.add(MapEntry(
        'audio_files',
        await MultipartFile.fromFile(f.path),
      ));
    }

    // Legacy shim — first text message and first audio file populate the
    // pre-v2 `text` / `voice_file` / `voice_peaks` fields so an older
    // backend deployment still extracts something usable.
    final firstText = messages.whereType<OrderTextMessage>().firstOrNull;
    form.fields.add(MapEntry('text', firstText?.text ?? ''));

    final firstAudio = messages.whereType<OrderAudioMessage>().firstOrNull;
    if (firstAudio != null) {
      form.files.add(MapEntry(
        'voice_file',
        await MultipartFile.fromFile(firstAudio.path),
      ));
      if (firstAudio.peaks.isNotEmpty) {
        final trimmed = firstAudio.peaks.length > 128
            ? _resample(firstAudio.peaks, 128)
            : firstAudio.peaks;
        form.fields.add(MapEntry(
          'voice_peaks',
          jsonEncode(
            trimmed.map((v) => double.parse(v.toStringAsFixed(3))).toList(),
          ),
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
