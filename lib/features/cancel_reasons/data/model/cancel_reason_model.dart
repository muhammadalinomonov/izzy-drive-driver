import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:taxi_app/core/utils/json_safe.dart';

/// Single backend-defined cancel reason. Audience values are
/// `driver` | `mechanic` | `both`. Driver fetches with `audience=driver`
/// and the backend also returns `both` entries.
class CancelReasonModel {
  final int id;
  final String textUz;
  final String textRu;
  final String textEn;
  final String audience;
  final int order;

  const CancelReasonModel({
    required this.id,
    required this.textUz,
    required this.textRu,
    required this.textEn,
    required this.audience,
    required this.order,
  });

  factory CancelReasonModel.fromJson(Map<String, dynamic> json) {
    return CancelReasonModel(
      id: toInt(json['id']),
      textUz: toStr(json['text_uz']),
      textRu: toStr(json['text_ru']),
      textEn: toStr(json['text_en']),
      audience: toStr(json['audience']),
      order: toInt(json['order']),
    );
  }

  /// Returns the matching translation for the active locale, falling back
  /// to `text_uz` whenever the picked field is blank.
  String localizedText(BuildContext context) {
    final code = EasyLocalization.of(context)?.currentLocale?.languageCode ?? 'uz';
    final String picked = switch (code) {
      'ru' => textRu,
      'en' => textEn,
      _ => textUz,
    };
    if (picked.trim().isNotEmpty) return picked;
    return textUz;
  }
}

/// Result returned by `showCancelReasonSheet`. Exactly one of
/// [reasonId] / [customText] is non-null:
///  - [reasonId] populated when the user picked a backend-defined reason.
///  - [customText] populated when the user picked the locally-rendered
///    "Other" row and typed a free-form reason.
class CancelReasonChoice {
  final int? reasonId;
  final String? customText;

  const CancelReasonChoice({this.reasonId, this.customText})
      : assert(
          (reasonId != null) != (customText != null),
          'Exactly one of reasonId / customText must be non-null',
        );
}
