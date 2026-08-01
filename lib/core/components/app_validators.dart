import 'package:easy_localization/easy_localization.dart';
import 'package:taxi_app/core/localization/locale_keys.g.dart';

class AppValidators {
  static String _field(String? override) =>
      override ?? LocaleKeys.validators_field.tr();

  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return LocaleKeys.validators_required.tr(
        namedArgs: {'field': _field(fieldName)},
      );
    }
    return null;
  }

  static String? email(String? value, {String? fieldName}) {
    final field = fieldName ?? LocaleKeys.validators_fieldEmail.tr();
    if (value == null || value.trim().isEmpty) {
      return LocaleKeys.validators_required.tr(namedArgs: {'field': field});
    }
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return LocaleKeys.validators_invalid.tr(namedArgs: {'field': field});
    }
    return null;
  }

  static String? password(
    String? value, {
    String? fieldName,
    int minLength = 6,
  }) {
    final field = fieldName ?? LocaleKeys.validators_fieldPassword.tr();
    if (value == null || value.isEmpty) {
      return LocaleKeys.validators_required.tr(namedArgs: {'field': field});
    }
    if (value.length < minLength) {
      return LocaleKeys.validators_passwordTooShort.tr(
        namedArgs: {'field': field, 'min': minLength.toString()},
      );
    }
    return null;
  }

  static String? phone(String? value, {String? fieldName}) {
    final field = fieldName ?? LocaleKeys.validators_fieldPhone.tr();
    if (value == null || value.trim().isEmpty) {
      return LocaleKeys.validators_required.tr(namedArgs: {'field': field});
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return LocaleKeys.validators_invalid.tr(namedArgs: {'field': field});
    }
    return null;
  }

  static String? name(String? value, {String? fieldName}) {
    final field = fieldName ?? LocaleKeys.validators_fieldName.tr();
    if (value == null || value.trim().isEmpty) {
      return LocaleKeys.validators_required.tr(namedArgs: {'field': field});
    }
    if (value.trim().length < 2) {
      return LocaleKeys.validators_nameTooShort.tr(namedArgs: {'field': field});
    }
    return null;
  }
}
