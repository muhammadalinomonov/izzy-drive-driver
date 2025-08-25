import 'package:flutter/material.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/core/storage/storage_repository.dart';
import 'package:mechanic/core/storage/store_keys.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/features/common/presentation/widgets/common_button.dart';
import 'package:mechanic/features/profile/presentation/widgets/language_item.dart';

class ChooseLanguageBottomSheet extends StatefulWidget {
  const ChooseLanguageBottomSheet({super.key});

  @override
  State<ChooseLanguageBottomSheet> createState() => _ChooseLanguageBottomSheetState();
}

class _ChooseLanguageBottomSheetState extends State<ChooseLanguageBottomSheet> {
  late ValueNotifier<String> _selectedLanguage;

  @override
  void initState() {
    super.initState();

    final languageCode = StorageRepository.getString(StoreKeys.language, defValue: 'en');
    _selectedLanguage = ValueNotifier(languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        color: solitude,
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(left: 14, top: 12, bottom: 18, right: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
                bottom: Radius.circular(12),
              ),
              color: white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: gray2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  margin: EdgeInsets.only(bottom: 25),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tilni o’zgartirish',
                    style: context.textTheme.headlineLarge!.copyWith(fontWeight: FontWeight.w600, fontSize: 20),
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
                color: white,
              ),
              padding: EdgeInsets.only(left: 12, top: 2, bottom: 8 + context.padding.bottom, right: 12),
              child: Column(
                children: [
                  LanguageItem(
                    isSelected: value == 'uz',
                    language: 'O’zbekcha',
                    onTap: () {
                      _selectedLanguage.value = 'uz';
                    },
                  ),
                  Divider(),
                  LanguageItem(
                    isSelected: value == 'ru',
                    language: 'Русский',
                    onTap: () {
                      _selectedLanguage.value = 'ru';
                    },
                  ),
                  Divider(),
                  LanguageItem(
                    isSelected: value == 'en',
                    language: 'English',
                    onTap: () {
                      _selectedLanguage.value = 'en';
                    },
                  ),
                  Divider(),
                  LanguageItem(
                    isSelected: value == 'fr',
                    language: 'French',
                    onTap: () {
                      _selectedLanguage.value = 'fr';
                    },
                  ),

                ],
              ),
            ),
          ),
          CommonButton(
            onTap: () {
              StorageRepository.putString(StoreKeys.language, _selectedLanguage.value);
              Navigator.of(context).pop();
            },
            text: 'Saqlash',
            margin: EdgeInsets.only(top: 24, left: 12, right: 12),
          )
        ],
      ),
    );
  }
}
