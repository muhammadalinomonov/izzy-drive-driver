# Avatar yuklash — Frontend Guide

Driver va Mechanic profil rasmini yuklash uchun ikkita yangi endpoint.
Bularning natijasi — **absolute URL** (host bilan birga) qaytariladi, mobile/web
client'lar to'g'ridan-to'g'ri shu URL'ni `<Image src=...>` ga berishi mumkin.

**Base URL:** `https://<host>/api/v1/`
**Auth:** `Authorization: Bearer <access_token>` (tegishli rolga ega user — driver yoki mechanic)

---

## 1. Driver avatar yuklash

```http
POST /api/v1/drivers/avatar/
Content-Type: multipart/form-data
```

**Auth:** `IsDriver` — faqat haydovchi rolida bo'lgan foydalanuvchi.

**Body (multipart):**

| Field    | Type | Required | Izoh                                  |
|----------|------|----------|---------------------------------------|
| `avatar` | file | ha       | JPG/PNG/WEBP rasm. Bitta fayl.        |

**Muvaffaqiyatli javob (200):**

```json
{
  "status": true,
  "message": "Avatar muvaffaqiyatli yuklandi",
  "data": {
    "avatar": "https://api.usta.local/media/drivers/avatar/photo_abc123.jpg"
  }
}
```

**Xato javob (400):**

```json
{ "status": false, "message": "avatar fayli yuborilmadi" }
```

**Frontend (Flutter, `http` + `MultipartRequest`):**

```dart
final request = http.MultipartRequest(
  'POST',
  Uri.parse('$baseUrl/drivers/avatar/'),
)
  ..headers['Authorization'] = 'Bearer $accessToken'
  ..files.add(await http.MultipartFile.fromPath('avatar', file.path));

final resp = await request.send();
final body = await resp.stream.bytesToString();
// body.data.avatar — absolute URL, darhol UI'ga set qilsa bo'ladi.
```

**Frontend (Web, `fetch` + `FormData`):**

```js
const form = new FormData();
form.append('avatar', file);
const res = await fetch(`${baseUrl}/drivers/avatar/`, {
  method: 'POST',
  headers: { 'Authorization': `Bearer ${accessToken}` },
  body: form,
});
const json = await res.json();
// json.data.avatar — absolute URL
```

---

## 2. Mechanic avatar yuklash

```http
POST /api/v1/mechanics/avatar/
Content-Type: multipart/form-data
```

**Auth:** `IsMechanic` — faqat mexanik rolida bo'lgan foydalanuvchi.

**Body (multipart):**

| Field    | Type | Required | Izoh                                                                |
|----------|------|----------|---------------------------------------------------------------------|
| `avatar` | file | ha       | JPG/PNG/WEBP rasm. Backend'da `Mechanic.photo` field'ga yoziladi.   |

> Eslatma: backend `photo` kalitini ham qabul qiladi (legacy frontend uchun), lekin **yangi kod `avatar` yuborsin**.

**Muvaffaqiyatli javob (200):**

```json
{
  "status": true,
  "message": "Avatar muvaffaqiyatli yuklandi",
  "data": {
    "avatar": "https://api.usta.local/media/mechanic_photos/photo_xyz789.jpg"
  }
}
```

**Xato javob (400):**

```json
{ "status": false, "message": "avatar fayli yuborilmadi" }
```

---

## 3. Absolute URL — boshqa endpointlarda ham

Avval ba'zi joylarda `avatar` / `photo` **relative path** sifatida qaytarilar edi (masalan, `"/media/drivers/avatar/x.jpg"`). Endi **barcha** driver/mechanic info qaytariladigan endpointlarda **absolute URL** (`"https://host/media/..."`) keladi.

Quyidagi endpointlar yangilandi (oldin relative path edi):

| Endpoint                                      | Field                          |
|-----------------------------------------------|--------------------------------|
| `PUT  /api/v1/drivers/driverprofile/`         | `avatar`, `truck_image`        |
| `PUT  /api/v1/mechanics/profil-update/`       | `photo`                        |
| `GET  /api/v1/mechanics/get-me/`              | `photo`                        |
| `GET  /api/v1/drivers/masters-view/`          | `photo` (har bir mexanik uchun) |
| `GET  /api/v1/drivers/mechanic-view/`         | `photo`                        |
| `GET  /api/v1/drivers/mechanic-revies/`       | `driver_avatar` (sharh muallifi) |

Quyidagilar oldindan ham absolute URL qaytarar edi (o'zgarmagan):

- `GET /api/v1/drivers/get-me/` — `photo`, `truck_image`
- `GET /api/v1/drivers/get-proposal/` — `mechanic_info.mechanic_photo`
- `GET /api/v1/drivers/active-order/` (proposals list) — `mechanic.photo`

**Null holatlar:** agar rasm yuklanmagan bo'lsa, `avatar`/`photo` qiymati `null` bo'ladi (bo'sh string emas).

---

## 4. Eski avatarni almashtirish va o'chirish

- **Almashtirish:** xuddi shu `POST /avatar/` endpointiga yangi rasm yuboring — eskisi qayta yozib qo'yiladi.
- **Tozalash (avatar yo'q qilish):** hozircha alohida endpoint yo'q — agar kerak bo'lsa, `PUT /driverprofile/` (yoki mechanic uchun `/profil-update/`) orqali `avatar` / `photo` field'ga `null` yuborib bo'ladi (model `null=True, blank=True`).

---

## 5. Diqqat

- **Fayl o'lchami / format validatsiyasi yo'q.** Hozir backend yuborilgan har qanday faylni qabul qiladi. Agar frontend tomon limit qo'ymasangiz, foydalanuvchi katta fayl yuborishi mumkin. Tavsiya: client tomonda **2 MB** dan kichik, JPG/PNG/WEBP ga cheklang.
- **Static fayl serving:** ishlab chiqishda Django o'zi `/media/` xizmat qiladi (`config/urls.py` ichidagi `static(...)`). Prodda Nginx orqali servirovka qilinishi kutiladi — `MEDIA_URL = '/media/'` va `MEDIA_ROOT` ga e'tibor bering.
- **CORS:** absolute URL javobda yuboriladi, lekin rasm yuklab olish uchun client `<img src>` orqali to'g'ridan-to'g'ri murojaat qiladi — bu CORS tekshiruviga tushmaydi (img tag exempt).
