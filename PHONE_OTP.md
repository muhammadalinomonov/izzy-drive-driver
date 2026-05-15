# Telefon raqamni OTP orqali tasdiqlash (Twilio Verify)

Bu hujjat **Usta** platformasida foydalanuvchining telefon raqamini OTP orqali
tasdiqlash oqimini tavsiflaydi. **Twilio Verify** managed xizmati ishlatiladi —
Twilio o'zi kodni generatsiya qiladi, SMS yuboradi va tekshiradi.

---

## 1. Umumiy ma'lumot

- **2 ta endpoint**: `request-otp` va `verify-otp`.
- Twilio Verify o'zi quyidagilarni boshqaradi:
  - kod uzunligi (default 6 ta raqam — Service settings'da o'zgartiriladi),
  - kod amal qilish muddati (TTL — Service settings'da),
  - maks. urinishlar soni (default 5),
  - SMS yuborish (Twilio o'zi yaxshi raqam tanlaydi).
- **Bizning tarafda** faqat: resend cooldown va soatlik limit (Redis cache).
- Telefon raqam **E.164 formatda** kutiladi: `+998901234567`.

### Twilio Console'da qilinadigan sozlash

`Verify → Services → [Service nomi] → Settings`:

| Sozlama | Qiymat |
| --- | --- |
| Code Length | 6 |
| Code TTL | **120 soniya** (2 daqiqa — siz so'ragan vaqt) |
| Max attempts | 5 (default) |
| Default Locale | `en` yoki o'z templatengiz |

> ⚠️ Kod muddati (2 daqiqa) — **Twilio Console**da konfiguratsiya qilinadi,
> kodda emas. Default 10 daqiqa, siz uni 120s ga tushiring.

---

## 2. Konfiguratsiya (.env)

Bularning **3 tasi yetarli**:

```env
# https://console.twilio.com/ -> Account Info
TWILIO_ACCOUNT_SID=AC5bcf11960bd1e8138953d123023da040
TWILIO_AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# https://console.twilio.com/ -> Verify -> Services -> Service SID
TWILIO_VERIFY_SERVICE_SID=VAad88ec1fb95ce8177115c793af30179f

# Ixtiyoriy override — bizning tarafdagi cooldown
PHONE_OTP_EXPIRE_SECONDS=120
PHONE_OTP_RESEND_COOLDOWN_SECONDS=120
PHONE_OTP_MAX_RESEND_PER_HOUR=5
```

**Faqat `TWILIO_AUTH_TOKEN` ni Twilio Console'dan olib qo'yish kifoya** — qolgan
ikkita SID allaqachon `.env` da.

---

## 3. Twilio API (ichkarida nima sodir bo'ladi)

Kod ichida `twilio` Python SDK ishlatiladi. Quyidagi cURL bilan ekvivalent:

**Yuborish:**
```bash
curl 'https://verify.twilio.com/v2/Services/VAad88ec.../Verifications' -X POST \
  --data-urlencode 'To=+998901234567' \
  --data-urlencode 'Channel=sms' \
  -u AC5bcf...:$AUTH_TOKEN
```

**Tekshirish:**
```bash
curl 'https://verify.twilio.com/v2/Services/VAad88ec.../VerificationCheck' -X POST \
  --data-urlencode 'To=+998901234567' \
  --data-urlencode 'Code=482913' \
  -u AC5bcf...:$AUTH_TOKEN
```

---

## 4. Endpointlar

Hammasi `/api/v1/accounts/` prefiksi ostida.

### 4.1. `POST /phone/request-otp/`

Telefon raqamga SMS OTP yuboradi.

**Request:**
```json
{ "phone_number": "+998901234567" }
```

**Response 200:**
```json
{
  "status": true,
  "message": "OTP yuborildi",
  "data": {
    "phone_number": "+998901234567",
    "expires_in": 120,
    "resend_after": 120
  }
}
```

**Response 400 — cooldown ichida qayta urinish:**
```json
{
  "status": false,
  "message": "Iltimos, 87 soniya kuting",
  "code": "otp_resend_cooldown"
}
```

**Response 400 — yaroqsiz raqam:**
```json
{
  "status": false,
  "message": "Telefon raqam yaroqsiz",
  "code": "phone_invalid"
}
```

**Response 503 — Twilio konfiguratsiya yo'q yoki ulanish xatosi:**
```json
{
  "status": false,
  "message": "SMS service sozlanmagan",
  "code": "sms_service_not_configured"
}
```

---

### 4.2. `POST /phone/verify-otp/`

Twilio'dan kelgan kodni tekshiradi.

**Request:**
```json
{ "phone_number": "+998901234567", "otp": "482913" }
```

**Response 200:**
```json
{
  "status": true,
  "message": "Telefon raqam tasdiqlandi",
  "data": { "phone_number": "+998901234567", "is_verified": true }
}
```

**Response 400 — xato kodlari:**

| `code`                   | Sabab                                                       |
| ------------------------ | ----------------------------------------------------------- |
| `invalid_input`          | `phone_number` yoki `otp` yo'q                              |
| `otp_invalid`            | Kod noto'g'ri (yana urinish bor)                            |
| `otp_expired`            | Twilio'da verification topilmadi (eskirgan/tugatilgan)      |
| `otp_too_many_attempts`  | Twilio max attempts (5) ga yetdi — qaytadan request kerak   |

---

## 5. Frontend uchun oqim

```
1) User telefon raqam kiritadi
   POST /phone/request-otp/   { phone_number }
   → Twilio SMS yuboradi, frontend'da 120s timer

2) User SMS'dagi kodni kiritadi
   POST /phone/verify-otp/   { phone_number, otp }
   → is_verified: true

3) Kod kelmasa, timer tugagandan keyin "Qayta yuborish" tugmasi
   (cooldown = 120s)
```

---

## 6. Backend'dan integratsiya

Boshqa joydan (masalan, registratsiya oqimida) ishlatish:

```python
from main.services.phone_otp import (
    normalize_phone,
    can_resend,
    request_otp,
    verify_otp,
)

phone = normalize_phone("+998 (90) 123-45-67")  # -> "+998901234567"

allowed, err, wait = can_resend(phone)
if allowed:
    ok, err = request_otp(phone)   # Twilio Verify'ga ketadi

# Tasdiqlash:
ok, err = verify_otp(phone, "482913")
if ok:
    # tasdiqlandi
    ...
```

---

## 7. Migration

**Hech qanday migration kerak emas** — bazaga hech narsa yozilmaydi.
Cooldown va rate-limit Redis cache'da saqlanadi.

---

## 8. Twilio trial cheklovi

Trial akkountda faqat **verified raqamlar**ga SMS ketadi. Production uchun:
`Twilio Console → Phone Numbers → Verified Caller IDs` ga test raqamlarini
qo'shing yoki to'lovli planga o'ting.
