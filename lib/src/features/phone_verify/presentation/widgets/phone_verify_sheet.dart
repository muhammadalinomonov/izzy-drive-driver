import 'package:country_picker/country_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/components/app_snack_bar.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';
import 'package:taxi_app/src/core/localization/locale_keys.g.dart';
import 'package:taxi_app/src/core/widgets/app_button.dart';
import 'package:taxi_app/src/core/network/auth_session.dart';
import 'package:taxi_app/src/features/phone_verify/data/repo/phone_verify_repo_impl.dart';
import 'package:taxi_app/src/features/phone_verify/data/source/phone_verify_data_source.dart';
import 'package:taxi_app/src/features/phone_verify/presentation/bloc/phone_verify_bloc.dart';
import 'package:taxi_app/src/routes/pages.dart';

// Phone-verify bottom sheet. It is dismissible — the user can close it and
// keep using the app. Phone verification is only enforced for account-based
// actions (creating an order) via [ensurePhoneVerified].
Future<void> showPhoneVerifySheet(
  BuildContext context, {
  required PhoneVerifyBloc bloc,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return BlocProvider.value(value: bloc, child: const _PhoneVerifySheet());
    },
  );
}

/// Gate for account-based actions such as creating an order. Returns true if
/// the user's phone is already verified (caller proceeds). Otherwise it opens
/// the dismissible phone-verify sheet and returns false so the caller stops.
bool ensurePhoneVerified(BuildContext context) {
  if (AuthSession.isPhoneVerified) return true;
  final bloc = PhoneVerifyBloc(
    repo: PhoneVerifyRepoImpl(dataSource: PhoneVerifyDataSource()),
  );
  showPhoneVerifySheet(context, bloc: bloc).whenComplete(bloc.close);
  return false;
}

class _PhoneVerifySheet extends StatefulWidget {
  const _PhoneVerifySheet();

  @override
  State<_PhoneVerifySheet> createState() => _PhoneVerifySheetState();
}

class _PhoneVerifySheetState extends State<_PhoneVerifySheet> {
  final _phoneController = TextEditingController();
  late Country _selected;
  late _PhoneMaskFormatter _maskFormatter;

  @override
  void initState() {
    super.initState();
    // Default davlat - USA, Figma'dagi kabi.
    _selected = Country.parse('US');
    _maskFormatter = _PhoneMaskFormatter(_maskFor(_selected));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // Mamlakat dial-code → mask. Asosiy bozorlar uchun aniq maska bor;
  // qolganlari uchun umumiy "### ### ### ###" (xom raqamlar bilan ishlaydi).
  static const Map<String, String> _masks = {
    '+1': '(###) ###-####', // US/Canada
    '+7': '### ###-##-##', // RU/KZ
    '+44': '#### ### ####', // UK
    '+49': '### #######', // DE
    '+33': '# ## ## ## ##', // FR
    '+34': '### ### ###', // ES
    '+39': '### ### ####', // IT
    '+90': '### ### ## ##', // TR
    '+91': '##### #####', // IN
    '+82': '##-####-####', // KR
    '+81': '##-####-####', // JP
    '+86': '### #### ####', // CN
    '+62': '### ### ####', // ID
    '+998': '## ### ## ##', // UZ
    '+996': '### ## ## ##', // KG
    '+992': '## ### ####', // TJ
    '+994': '## ### ## ##', // AZ
    '+374': '## ### ###', // AM
    '+995': '### ## ## ##', // GE
    '+971': '## ### ####', // AE
    '+966': '## ### ####', // SA
    '+20': '### ### ####', // EG
    '+55': '## ##### ####', // BR
    '+52': '### ### ####', // MX
    '+54': '## ####-####', // AR
    '+61': '### ### ###', // AU
    '+64': '## ### ####', // NZ
    '+27': '## ### ####', // ZA
    '+234': '### ### ####', // NG
    '+254': '### ### ###', // KE
    '+972': '##-###-####', // IL
    '+380': '## ### ## ##', // UA
    '+48': '### ### ###', // PL
    '+31': '# ########', // NL
    '+46': '##-### ## ##', // SE
    '+47': '### ## ###', // NO
    '+45': '## ## ## ##', // DK
    '+358': '## ### ####', // FI
    '+30': '### ### ####', // GR
    '+351': '### ### ###', // PT
    '+43': '### #######', // AT
    '+41': '## ### ## ##', // CH
    '+32': '### ## ## ##', // BE
    '+420': '### ### ###', // CZ
    '+421': '### ### ###', // SK
    '+36': '## ### ####', // HU
  };

  static String _maskFor(Country country) {
    return _masks['+${country.phoneCode}'] ?? '### ### ### ###';
  }

  int get _expectedDigits {
    return _maskFormatter.mask.split('').where((c) => c == '#').length;
  }

  void _pickCountry() {
    FocusManager.instance.primaryFocus?.unfocus();
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        flagSize: 22,
        backgroundColor: AppColor.white,
        textStyle: context.textS.titleSmall!.copyWith(
          fontWeight: FontWeight.w500,
        ),
        bottomSheetHeight: 600,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        inputDecoration: InputDecoration(
          hintText: LocaleKeys.phoneVerify_entry_searchCountry.tr(),
          hintStyle: TextStyle(color: AppColor.lightGreyBlue),
          prefixIcon: Icon(Icons.search, color: AppColor.grey),
          filled: true,
          fillColor: AppColor.lightBlue,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      onSelect: (Country country) {
        setState(() {
          _selected = country;
          _maskFormatter = _PhoneMaskFormatter(_maskFor(country));
          _phoneController.clear();
        });
      },
    );
  }

  void _onSubmit() {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < _expectedDigits) {
      AppSnackBar.showError(
        context,
        LocaleKeys.phoneVerify_entry_invalidPhone.tr(),
      );
      return;
    }
    final dialCode = '+${_selected.phoneCode}';
    final fullNumber = '$dialCode$digits';
    FocusManager.instance.primaryFocus?.unfocus();
    context.read<PhoneVerifyBloc>().add(
      SendOtpEvent(
        phoneNumber: fullNumber,
        dialCode: dialCode,
        onSuccess: () {
          if (!mounted) return;
          context.push(Pages.phoneOtp);
        },
        // Failure handling - sheet ichidagi inline banner orqali (BlocListener),
        // chunki modal sheet pastdagi snackbar'ni yopib qo'yadi.
        onError: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: AppColor.grey,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
                const SizedBox(height: 8),
                Image.asset('assets/images/phone.png', width: 53, height: 75),
                const SizedBox(height: 12),
                Text(
                  LocaleKeys.phoneVerify_entry_lastStep.tr(),
                  style: context.textS.bodyMedium!.copyWith(
                    color: AppColor.kPrimaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  LocaleKeys.phoneVerify_entry_title.tr(),
                  style: context.textS.headlineSmall!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                _PhoneInput(
                  controller: _phoneController,
                  country: _selected,
                  maskFormatter: _maskFormatter,
                  onPickCountry: _pickCountry,
                ),
                BlocBuilder<PhoneVerifyBloc, PhoneVerifyState>(
                  buildWhen: (p, c) =>
                      p.sendStatus != c.sendStatus ||
                      p.errorMessage != c.errorMessage,
                  builder: (context, state) {
                    final showError =
                        state.sendStatus == PhoneVerifyStatus.failure &&
                        state.errorMessage.isNotEmpty;
                    if (!showError) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _SheetErrorBanner(message: state.errorMessage),
                    );
                  },
                ),
                const SizedBox(height: 20),
                BlocBuilder<PhoneVerifyBloc, PhoneVerifyState>(
                  buildWhen: (p, c) => p.sendStatus != c.sendStatus,
                  builder: (context, state) {
                    return AppButton(
                      isLoading: state.sendStatus == PhoneVerifyStatus.loading,
                      title: LocaleKeys.phoneVerify_entry_next.tr(),
                      onTap: _onSubmit,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneInput extends StatelessWidget {
  const _PhoneInput({
    required this.controller,
    required this.country,
    required this.maskFormatter,
    required this.onPickCountry,
  });

  final TextEditingController controller;
  final Country country;
  final _PhoneMaskFormatter maskFormatter;
  final VoidCallback onPickCountry;

  String _hintFromMask() {
    return maskFormatter.mask.replaceAll('#', '0');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.lightBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onPickCountry,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColor.grey,
                    size: 22,
                  ),
                  const SizedBox(width: 4),
                  Text(country.flagEmoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 6),
                  Text(
                    '(+${country.phoneCode})',
                    style: context.textS.titleMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            width: 1,
            color: AppColor.lightGreyBlue,
            height: 24,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                maskFormatter,
              ],
              style: context.textS.titleMedium!.copyWith(
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: _hintFromMask(),
                hintStyle: context.textS.titleMedium!.copyWith(
                  color: AppColor.lightGreyBlue,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetErrorBanner extends StatelessWidget {
  const _SheetErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColor.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.red.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_rounded, color: AppColor.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: context.textS.bodyMedium!.copyWith(
                color: AppColor.red,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneMaskFormatter extends TextInputFormatter {
  _PhoneMaskFormatter(this.mask);
  final String mask;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    int digitIndex = 0;
    for (int i = 0; i < mask.length && digitIndex < digits.length; i++) {
      final ch = mask[i];
      if (ch == '#') {
        buffer.write(digits[digitIndex]);
        digitIndex++;
      } else {
        buffer.write(ch);
      }
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
