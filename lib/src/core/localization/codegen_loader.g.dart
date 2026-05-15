// DO NOT EDIT. This is code generated via package:easy_localization/generate.dart

// ignore_for_file: prefer_single_quotes, avoid_renaming_method_parameters, constant_identifier_names

import 'dart:ui';

import 'package:easy_localization/easy_localization.dart' show AssetLoader;

class CodegenLoader extends AssetLoader{
  const CodegenLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) {
    return Future.value(mapLocales[locale.toString()]);
  }

  static const Map<String,dynamic> _ru = {
  "common": {
    "ok": "Ок",
    "cancel": "Отмена",
    "save": "Сохранить",
    "delete": "Удалить",
    "edit": "Редактировать",
    "back": "Назад",
    "next": "Далее",
    "done": "Готово",
    "yes": "Да",
    "no": "Нет",
    "loading": "Загрузка...",
    "error": "Ошибка",
    "retry": "Повторить",
    "search": "Поиск",
    "send": "Отправить",
    "close": "Закрыть",
    "confirm": "Подтвердить",
    "skip": "Пропустить",
    "continue": "Продолжить",
    "noInternet": "Нет соединения с интернетом",
    "somethingWentWrong": "Что-то пошло не так",
    "tryAgain": "Попробуйте снова",
    "empty": "Пусто",
    "select": "Выбрать"
  },
  "language": {
    "title": "Язык",
    "uz": "Узбекский",
    "ru": "Русский",
    "en": "Английский"
  },
  "validators": {
    "required": "{field} обязателен для заполнения",
    "invalid": "{field} введён неверно",
    "passwordTooShort": "{field} должен содержать не менее {min} символов",
    "nameTooShort": "{field} должно содержать не менее 2 символов",
    "field": "Это поле",
    "fieldEmail": "Email",
    "fieldPassword": "Пароль",
    "fieldPhone": "Номер телефона",
    "fieldName": "Имя"
  },
  "auth": {
    "signIn": {
      "title": "Войти в систему",
      "googleContinue": "Продолжить через Google",
      "appleContinue": "Продолжить через Apple",
      "orWithEmail": "Или введите e-mail и пароль",
      "emailHint": "Введите e-mail",
      "emailLabel": "E-mail",
      "passwordHint": "Введите пароль",
      "passwordLabel": "Пароль",
      "forgotPassword": "Забыли пароль?",
      "notRegisteredYet": "Ещё не зарегистрированы?",
      "registerCta": "Зарегистрироваться",
      "loginFailed": "Не удалось войти в систему",
      "googleFailed": "Не удалось войти через Google",
      "appleFailed": "Не удалось войти через Apple"
    },
    "signUp": {
      "title": "Введите данные для регистрации!",
      "emailHint": "Введите e-mail",
      "emailLabel": "E-mail",
      "nameHint": "Введите имя",
      "nameLabel": "Имя",
      "passwordHint": "*********",
      "passwordLabel": "Пароль",
      "submit": "Зарегистрироваться",
      "alreadyRegistered": "Уже зарегистрированы?",
      "signInCta": "Войти в систему",
      "otpRequestFailed": "Не удалось отправить код"
    },
    "forgotPassword": {
      "title": "Восстановление пароля",
      "subtitle": "На ваш e-mail будет отправлен код подтверждения",
      "emailHint": "Введите e-mail",
      "emailLabel": "E-mail",
      "sendCode": "Отправить код",
      "otpRequestFailed": "Не удалось отправить OTP"
    },
    "resetPassword": {
      "title": "Новый пароль",
      "subtitle": "Введите и подтвердите новый пароль",
      "newPasswordHint": "Введите новый пароль",
      "newPasswordLabel": "Новый пароль",
      "confirmPasswordHint": "Введите пароль ещё раз",
      "confirmPasswordLabel": "Повторите пароль",
      "save": "Сохранить",
      "passwordMismatch": "Пароли не совпадают",
      "passwordUpdated": "Пароль обновлён. Войдите с новым паролем",
      "updateFailed": "Не удалось обновить пароль"
    },
    "otp": {
      "confirmAccountTitle": "Подтвердите аккаунт",
      "enterCodeTitle": "Введите код подтверждения",
      "sentTo": "Введите 6-значный код, отправленный на {email}",
      "confirm": "Подтвердить",
      "cancel": "Отмена",
      "didntReceive": "Не пришёл код? ",
      "resend": "Отправить ещё раз",
      "resendIn": "Отправить ещё раз ({seconds}с)",
      "resendFailed": "Не удалось повторно отправить код",
      "verifyFailed": "Код не подтверждён"
    },
    "emailConfirmation": {
      "title": "Подтвердите аккаунт",
      "body": "Активируйте аккаунт через {email}!",
      "understood": "Понятно"
    },
    "errors": {
      "otpRequestFailed": "Не удалось отправить код",
      "otpVerifyFailed": "OTP не подтверждён",
      "registerFailed": "Не удалось зарегистрироваться",
      "googleSignInFailed": "Не удалось войти через Google",
      "appleSignInFailed": "Не удалось войти через Apple",
      "passwordUpdateFailed": "Не удалось обновить пароль",
      "logoutFailed": "Не удалось выйти из системы",
      "accountDeleteFailed": "Не удалось удалить аккаунт",
      "serverError": "Ошибка сервера",
      "googleTokenEmpty": "Google идентификатор не найден",
      "appleTokenEmpty": "Apple идентификатор не найден",
      "verificationTokenEmpty": "Токен подтверждения не найден",
      "resetTokenMissing": "Токен восстановления не найден, попробуйте снова"
    }
  },
  "phoneVerify": {
    "entry": {
      "lastStep": "Последний шаг",
      "title": "Введите номер телефона",
      "next": "Далее",
      "invalidPhone": "Введите корректный номер телефона",
      "searchCountry": "Поиск страны"
    },
    "otp": {
      "title": "Подтвердите номер телефона",
      "subtitle": "6-значный код отправлен на номер {phone}. Введите его для подтверждения.",
      "writeCode": "Введите код",
      "didntReceive": "Код не пришёл?",
      "resend": "Отправить снова",
      "incorrect": "Введённый код неверный или устарел",
      "confirm": "Подтвердить",
      "verifyFailed": "Код не подтверждён",
      "resendFailed": "Не удалось отправить код повторно",
      "sendFailed": "Не удалось отправить код",
      "tooManyAttempts": "Слишком много попыток, запросите новый код"
    }
  }
};
static const Map<String,dynamic> _en = {
  "common": {
    "ok": "OK",
    "cancel": "Cancel",
    "save": "Save",
    "delete": "Delete",
    "edit": "Edit",
    "back": "Back",
    "next": "Next",
    "done": "Done",
    "yes": "Yes",
    "no": "No",
    "loading": "Loading...",
    "error": "Error",
    "retry": "Retry",
    "search": "Search",
    "send": "Send",
    "close": "Close",
    "confirm": "Confirm",
    "skip": "Skip",
    "continue": "Continue",
    "noInternet": "No internet connection",
    "somethingWentWrong": "Something went wrong",
    "tryAgain": "Try again",
    "empty": "Empty",
    "select": "Select"
  },
  "language": {
    "title": "Language",
    "uz": "Uzbek",
    "ru": "Russian",
    "en": "English"
  },
  "validators": {
    "required": "{field} is required",
    "invalid": "Please enter a valid {field}",
    "passwordTooShort": "{field} must be at least {min} characters",
    "nameTooShort": "{field} must be at least 2 characters",
    "field": "This field",
    "fieldEmail": "Email",
    "fieldPassword": "Password",
    "fieldPhone": "Phone number",
    "fieldName": "Name"
  },
  "auth": {
    "signIn": {
      "title": "Sign in",
      "googleContinue": "Continue with Google",
      "appleContinue": "Continue with Apple",
      "orWithEmail": "Or enter your e-mail and password",
      "emailHint": "Enter your e-mail",
      "emailLabel": "E-mail",
      "passwordHint": "Enter your password",
      "passwordLabel": "Password",
      "forgotPassword": "Forgot your password?",
      "notRegisteredYet": "Not registered yet?",
      "registerCta": "Sign up",
      "loginFailed": "Failed to sign in",
      "googleFailed": "Failed to sign in with Google",
      "appleFailed": "Failed to sign in with Apple"
    },
    "signUp": {
      "title": "Enter your details to register!",
      "emailHint": "Enter your e-mail",
      "emailLabel": "E-mail",
      "nameHint": "Enter your name",
      "nameLabel": "Name",
      "passwordHint": "*********",
      "passwordLabel": "Password",
      "submit": "Sign up",
      "alreadyRegistered": "Already registered?",
      "signInCta": "Sign in",
      "otpRequestFailed": "Failed to send code"
    },
    "forgotPassword": {
      "title": "Reset password",
      "subtitle": "A confirmation code will be sent to your e-mail",
      "emailHint": "Enter your e-mail",
      "emailLabel": "E-mail",
      "sendCode": "Send code",
      "otpRequestFailed": "Failed to send OTP"
    },
    "resetPassword": {
      "title": "New password",
      "subtitle": "Enter and confirm a new password",
      "newPasswordHint": "Enter new password",
      "newPasswordLabel": "New password",
      "confirmPasswordHint": "Re-enter the password",
      "confirmPasswordLabel": "Confirm password",
      "save": "Save",
      "passwordMismatch": "Passwords don't match",
      "passwordUpdated": "Password updated. Sign in with the new password",
      "updateFailed": "Failed to update password"
    },
    "otp": {
      "confirmAccountTitle": "Confirm your account",
      "enterCodeTitle": "Enter the confirmation code",
      "sentTo": "Enter the 6-digit code sent to {email}",
      "confirm": "Confirm",
      "cancel": "Cancel",
      "didntReceive": "Didn't get the code? ",
      "resend": "Resend",
      "resendIn": "Resend ({seconds}s)",
      "resendFailed": "Failed to resend the code",
      "verifyFailed": "Code not verified"
    },
    "emailConfirmation": {
      "title": "Confirm your account",
      "body": "Activate your account via {email}!",
      "understood": "Got it"
    },
    "errors": {
      "otpRequestFailed": "Failed to send code",
      "otpVerifyFailed": "OTP not verified",
      "registerFailed": "Failed to register",
      "googleSignInFailed": "Failed to sign in with Google",
      "appleSignInFailed": "Failed to sign in with Apple",
      "passwordUpdateFailed": "Failed to update password",
      "logoutFailed": "Failed to log out",
      "accountDeleteFailed": "Failed to delete account",
      "serverError": "Server error",
      "googleTokenEmpty": "Google identifier not found",
      "appleTokenEmpty": "Apple identifier not found",
      "verificationTokenEmpty": "Verification token not found",
      "resetTokenMissing": "Reset token missing, please try again"
    }
  },
  "phoneVerify": {
    "entry": {
      "lastStep": "Last step",
      "title": "Write your phone number",
      "next": "Next",
      "invalidPhone": "Please enter a valid phone number",
      "searchCountry": "Search country"
    },
    "otp": {
      "title": "Verify phone number",
      "subtitle": "A 6-digit code has been sent to {phone}. Enter this code to confirm.",
      "writeCode": "Write code",
      "didntReceive": "Didn't receive the code?",
      "resend": "Resend code",
      "incorrect": "The code entered is incorrect or has expired",
      "confirm": "Confirm",
      "verifyFailed": "Code verification failed",
      "resendFailed": "Failed to resend the code",
      "sendFailed": "Failed to send the code",
      "tooManyAttempts": "Too many attempts, request a new code"
    }
  }
};
static const Map<String,dynamic> _uz = {
  "common": {
    "ok": "Ok",
    "cancel": "Bekor qilish",
    "save": "Saqlash",
    "delete": "O'chirish",
    "edit": "Tahrirlash",
    "back": "Orqaga",
    "next": "Keyingi",
    "done": "Tayyor",
    "yes": "Ha",
    "no": "Yo'q",
    "loading": "Yuklanmoqda...",
    "error": "Xatolik",
    "retry": "Qayta urinish",
    "search": "Qidirish",
    "send": "Yuborish",
    "close": "Yopish",
    "confirm": "Tasdiqlash",
    "skip": "O'tkazib yuborish",
    "continue": "Davom etish",
    "noInternet": "Internet aloqasi yo'q",
    "somethingWentWrong": "Nimadir xato ketdi",
    "tryAgain": "Qayta urining",
    "empty": "Bo'sh",
    "select": "Tanlash"
  },
  "language": {
    "title": "Til",
    "uz": "O'zbekcha",
    "ru": "Ruscha",
    "en": "Inglizcha"
  },
  "validators": {
    "required": "{field} kiritilishi shart",
    "invalid": "{field} noto'g'ri kiritilgan",
    "passwordTooShort": "{field} kamida {min} ta belgi bo'lishi kerak",
    "nameTooShort": "{field} kamida 2 ta belgi bo'lishi kerak",
    "field": "Bu maydon",
    "fieldEmail": "Email",
    "fieldPassword": "Parol",
    "fieldPhone": "Telefon raqam",
    "fieldName": "Ism"
  },
  "auth": {
    "signIn": {
      "title": "Tizimga kirish",
      "googleContinue": "Google orqali davom ettirish",
      "appleContinue": "Apple orqali davom ettirish",
      "orWithEmail": "Yoki e-mail va parolni kiriting",
      "emailHint": "Mailni kiriting",
      "emailLabel": "E-mail",
      "passwordHint": "Parol kiriting",
      "passwordLabel": "Parol",
      "forgotPassword": "Parolni unutdingizmi?",
      "notRegisteredYet": "Ro'yxatdan o'tmaganmisiz?",
      "registerCta": "Ro'xatdan o'tish",
      "loginFailed": "Tizimga kirib bo'lmadi",
      "googleFailed": "Google orqali kirib bo'lmadi",
      "appleFailed": "Apple orqali kirib bo'lmadi"
    },
    "signUp": {
      "title": "Ro'yxatdan o'tish uchun ma'lumotlarni kiriting!",
      "emailHint": "Emailni kiriting",
      "emailLabel": "E-mail",
      "nameHint": "Ismini kiriting",
      "nameLabel": "Ism",
      "passwordHint": "*********",
      "passwordLabel": "Parol",
      "submit": "Ro'yxatdan o'tish",
      "alreadyRegistered": "Ro'yxatdan o'tib bo'lganmisiz?",
      "signInCta": "Tizimga kirish",
      "otpRequestFailed": "Kod yuborib bo'lmadi"
    },
    "forgotPassword": {
      "title": "Parolni tiklash",
      "subtitle": "Email manzilingizga tasdiqlash kodi yuboriladi",
      "emailHint": "Mailni kiriting",
      "emailLabel": "E-mail",
      "sendCode": "Kod yuborish",
      "otpRequestFailed": "OTP yuborib bo'lmadi"
    },
    "resetPassword": {
      "title": "Yangi parol",
      "subtitle": "Yangi parolni kiriting va tasdiqlang",
      "newPasswordHint": "Yangi parolni kiriting",
      "newPasswordLabel": "Yangi parol",
      "confirmPasswordHint": "Parolni qaytadan kiriting",
      "confirmPasswordLabel": "Parolni takrorlang",
      "save": "Saqlash",
      "passwordMismatch": "Parollar mos kelmadi",
      "passwordUpdated": "Parol yangilandi. Yangi parol bilan kiring",
      "updateFailed": "Parolni yangilab bo'lmadi"
    },
    "otp": {
      "confirmAccountTitle": "Akkauntni tasdiqlang",
      "enterCodeTitle": "Tasdiqlash kodini kiriting",
      "sentTo": "{email} manzilingizga yuborilgan 6 xonali kodni kiriting",
      "confirm": "Tasdiqlash",
      "cancel": "Bekor qilish",
      "didntReceive": "Kod kelmadi? ",
      "resend": "Qayta yuborish",
      "resendIn": "Qayta yuborish ({seconds}s)",
      "resendFailed": "Kodni qayta yuborib bo'lmadi",
      "verifyFailed": "Kod tasdiqlanmadi"
    },
    "emailConfirmation": {
      "title": "Akkuntni tasdiqlang",
      "body": "{email} orqali akkauntingizni aktivlashtiring!",
      "understood": "Tushunarli"
    },
    "errors": {
      "otpRequestFailed": "Kod yuborib bo'lmadi",
      "otpVerifyFailed": "OTP tasdiqlanmadi",
      "registerFailed": "Ro'yxatdan o'tib bo'lmadi",
      "googleSignInFailed": "Google orqali kirib bo'lmadi",
      "appleSignInFailed": "Apple orqali kirib bo'lmadi",
      "passwordUpdateFailed": "Parolni yangilab bo'lmadi",
      "logoutFailed": "Tizimdan chiqib bo'lmadi",
      "accountDeleteFailed": "Akkauntni o'chirib bo'lmadi",
      "serverError": "Server xatosi",
      "googleTokenEmpty": "Google identifikator topilmadi",
      "appleTokenEmpty": "Apple identifikator topilmadi",
      "verificationTokenEmpty": "Tasdiqlash tokeni topilmadi",
      "resetTokenMissing": "Tiklash tokeni topilmadi, qaytadan urinib ko'ring"
    }
  },
  "phoneVerify": {
    "entry": {
      "lastStep": "Oxirgi qadam",
      "title": "Telefon raqamingizni kiriting",
      "next": "Keyingi",
      "invalidPhone": "Telefon raqamini to'g'ri kiriting",
      "searchCountry": "Davlatni qidirish"
    },
    "otp": {
      "title": "Telefon raqamini tasdiqlang",
      "subtitle": "{phone} raqamiga 6 xonali kod yuborildi. Tasdiqlash uchun kiriting.",
      "writeCode": "Kodni kiriting",
      "didntReceive": "Kod kelmadi?",
      "resend": "Qayta yuborish",
      "incorrect": "Kiritilgan kod xato yoki muddati tugagan",
      "confirm": "Tasdiqlash",
      "verifyFailed": "Kod tasdiqlanmadi",
      "resendFailed": "Kodni qayta yuborib bo'lmadi",
      "sendFailed": "Kod yuborib bo'lmadi",
      "tooManyAttempts": "Urinishlar soni tugadi, qayta kod so'rang"
    }
  }
};
static const Map<String, Map<String,dynamic>> mapLocales = {"ru": _ru, "en": _en, "uz": _uz};
}
