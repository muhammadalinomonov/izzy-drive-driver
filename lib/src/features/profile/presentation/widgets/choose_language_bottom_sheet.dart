import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/localization/locale_keys.g.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/common_button.dart';
import 'package:taxi_app/src/features/profile/presentation/widgets/language_item.dart';

class ChooseLanguageBottomSheet extends StatefulWidget {
  const ChooseLanguageBottomSheet({super.key});

  @override
  State<ChooseLanguageBottomSheet> createState() => _ChooseLanguageBottomSheetState();
}

class _ChooseLanguageBottomSheetState extends State<ChooseLanguageBottomSheet> {
  final ValueNotifier<String> _selectedLanguage = ValueNotifier('uz');
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _selectedLanguage.value = context.locale.languageCode;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _selectedLanguage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        color: AppColor.lightBlue,
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(left: 14, top: 12, bottom: 16, right: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20), bottom: Radius.circular(12)),
              color: AppColor.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(color: AppColor.grey2, borderRadius: BorderRadius.circular(2)),
                  margin: EdgeInsets.only(bottom: 25),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    LocaleKeys.language_title.tr(),
                    style: context.textTheme.headlineLarge!.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
          ValueListenableBuilder(
            valueListenable: _selectedLanguage,
            builder: (context, value, child) => Container(
              margin: EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                color: AppColor.white,
              ),
              padding: EdgeInsets.only(left: 12, top: 2, bottom: 8 + context.padding.bottom, right: 12),
              child: Column(
                children: [
                  LanguageItem(
                    isSelected: value == 'uz',
                    language: LocaleKeys.language_uz.tr(),
                    onTap: () => _selectedLanguage.value = 'uz',
                  ),
                  Divider(color: AppColor.lightBlue),
                  LanguageItem(
                    isSelected: value == 'ru',
                    language: LocaleKeys.language_ru.tr(),
                    onTap: () => _selectedLanguage.value = 'ru',
                  ),
                  Divider(color: AppColor.lightBlue),
                  LanguageItem(
                    isSelected: value == 'en',
                    language: LocaleKeys.language_en.tr(),
                    onTap: () => _selectedLanguage.value = 'en',
                  ),
                ],
              ),
            ),
          ),
          CommonButton(
            onTap: () async {
              await context.setLocale(Locale(_selectedLanguage.value));
              if (context.mounted) Navigator.of(context).pop();
            },
            text: LocaleKeys.common_save.tr(),
            margin: EdgeInsets.only(top: 24, left: 12, right: 12),
          ),
        ],
      ),
    );
  }
}
