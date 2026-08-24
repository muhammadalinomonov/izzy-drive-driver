# Support Chat — Mobile API

Mobile (driver-side) support chat qo'llanmasi: WebSocket ulanish, eventlar va REST endpointlar.

- **API prefix:** `/api/v1/mobile`
- **Auth:** bearer token (`mobile`) + `X-Organization-Id`
- **Kanal:** `private-support.driver.{driver_id}`

---

## Mundarija

1. [WebSocket ulanish](#1-websocket-ulanish)
2. [WebSocket eventlar](#2-websocket-eventlar)
3. [REST API — Chat](#3-rest-api--chat)
4. [Muhim eslatmalar](#4-muhim-eslatmalar)

---

## 1. WebSocket ulanish

### Reverb WebSocket sozlamalari

```text
REVERB_URL=wss://{reverb-host}/app/{REVERB_APP_KEY}?protocol=7&client=mobile&version=1.0&flash=false
```

### Private kanal auth

```http
POST /api/v1/broadcasting/auth
Authorization: Bearer {mobile_token}
X-Organization-Id: {organization_id}
Content-Type: application/json
```

Request body:

```json
{
  "socket_id": "1234.5678",
  "channel_name": "private-support.driver.{driver_id}"
}
```

Response:

```json
{
  "auth": "{REVERB_APP_KEY}:signed-channel-value"
}
```

### Subscribe frame

```json
{
  "event": "pusher:subscribe",
  "data": {
    "auth": "{REVERB_APP_KEY}:signed-channel-value",
    "channel": "private-support.driver.{driver_id}"
  }
}
```

---

## 2. WebSocket eventlar

Mobile quyidagi kanalda ikkita eventni tinglaydi:

```text
private-support.driver.{driver_id}
```

| Event | Mazmuni |
|---|---|
| `support.message.created` | Yangi chat xabari |
| `mobile.route-review.updated` | Route-review o'zgardi |

### 2.1 Yangi chat xabari — `support.message.created`

Event body:

```json
{
  "organization_id": "01JZ8ORGANIZATION000000000",
  "conversation": {
    "id": "01K0SUPPORTCHAT00000000000",
    "support_scope": "company",
    "organization": {
      "id": "01JZ8ORGANIZATION000000000",
      "name": "Example Fleet LLC",
      "type": "fleet",
      "status": "active"
    },
    "driver": {
      "id": "01JZ8DRIVER00000000000000",
      "driver_number": "DRV-1042",
      "full_name": "Alex Driver",
      "status": "active"
    },
    "message_count": 2,
    "last_message": {
      "id": "01K0SUPPORTMESSAGE000000002",
      "sender_type": "support",
      "sender_name": "Nick Rose",
      "message": "We received your request.",
      "route_review_id": null,
      "created_at": "2026-08-19T16:01:00+00:00"
    },
    "last_message_at": "2026-08-19T16:01:00+00:00",
    "created_at": "2026-08-19T16:00:00+00:00"
  },
  "message": {
    "id": "01K0SUPPORTMESSAGE000000002",
    "sender_type": "support",
    "sender_name": "Nick Rose",
    "message": "We received your request.",
    "route_review_id": null,
    "created_at": "2026-08-19T16:01:00+00:00"
  }
}
```

**Eslatmalar:**

- `sender_type`: `driver` yoki `support`
- Oddiy chatda `route_review_id: null`
- Route'ga tegishli xabarda `route_review_id` keladi
- `message.id` bilan deduplicate qilish

### 2.2 Route-review o'zgargan — `mobile.route-review.updated`

Event body:

```json
{
  "schema_version": 1,
  "event_id": "65dcac93-7f41-4fa7-aee5-bb3457a22b63",
  "organization_id": "01JZ8ORGANIZATION000000000",
  "driver_id": "01JZ8DRIVER00000000000000",
  "route_review_id": "01K0ROUTEREVIEW00000000000",
  "initiator": "driver",
  "change_type": "decision_updated",
  "status": "alternative_suggested",
  "can_drive": true,
  "requested_alternative_id": "01K0REQUESTEDALTERNATIVE000",
  "proposed_alternative_id": "01K0ALTERNATIVE200000000000",
  "approved_alternative_id": "01K0ALTERNATIVE200000000000",
  "revision": "2026-08-19T16:02:00.000000Z",
  "occurred_at": "2026-08-19T16:02:00.123456Z",
  "mobile_result_endpoint": "/api/v1/mobile/route-reviews/01K0ROUTEREVIEW00000000000",
  "organization_result_endpoint": "/api/v1/route-reviews/01K0ROUTEREVIEW00000000000",
  "platform_result_endpoint": "/api/v1/platform/organizations/01JZ8ORGANIZATION000000000/workspace/route-reviews/01K0ROUTEREVIEW00000000000",
  "support_result_endpoint": "/api/v1/route-reviews/01K0ROUTEREVIEW00000000000"
}
```

**Ishlash tartibi:**

1. `event_id` bilan deduplicate qilish
2. `organization_id` va `driver_id`ni tekshirish
3. `GET {mobile_result_endpoint}` orqali yangilangan ma'lumotni olish
4. UI state'ni yangilash

---

## 3. REST API — Chat

### 3.1 Chat history olish

```http
GET /api/v1/mobile/support-chat?page=1&per_page=50
Authorization: Bearer {mobile_token}
X-Organization-Id: {organization_id}
Accept: application/json
```

Response:

```json
{
  "status": "success",
  "success": true,
  "data": {
    "conversation": {
      "id": "01K0SUPPORTCHAT00000000000",
      "support_scope": "company",
      "organization": {
        "id": "01JZ8ORGANIZATION000000000",
        "name": "Example Fleet LLC",
        "type": "fleet",
        "status": "active"
      },
      "driver": {
        "id": "01JZ8DRIVER00000000000000",
        "driver_number": "DRV-1042",
        "full_name": "Alex Driver",
        "status": "active"
      },
      "message_count": 2,
      "last_message_at": "2026-08-19T16:01:00+00:00",
      "created_at": "2026-08-19T16:00:00+00:00"
    },
    "items": [
      {
        "id": "01K0SUPPORTMESSAGE000000002",
        "sender_type": "support",
        "sender_name": "Nick Rose",
        "message": "We received your request.",
        "route_review_id": null,
        "created_at": "2026-08-19T16:01:00+00:00"
      },
      {
        "id": "01K0SUPPORTMESSAGE000000001",
        "sender_type": "driver",
        "sender_name": "Alex Driver",
        "message": "I need help.",
        "route_review_id": null,
        "created_at": "2026-08-19T16:00:00+00:00"
      }
    ]
  },
  "pagination": {
    "current_page": 1,
    "last_page": 1,
    "per_page": 50,
    "total": 2
  },
  "message": null,
  "error": null
}
```

### 3.2 Xabar yuborish

```http
POST /api/v1/mobile/support-chat/messages
Authorization: Bearer {mobile_token}
X-Organization-Id: {organization_id}
Accept: application/json
Content-Type: application/json
```

Request body:

```json
{
  "message": "I need help."
}
```

**Eslatmalar:**

- Faqat `message` field yuboriladi
- Uzunligi: 1..2000 belgi
- `driver_id`, `conversation_id`, `sender_type`, `route_review_id` yuborilmaydi

Response:

```json
{
  "status": "success",
  "success": true,
  "data": {
    "id": "01K0SUPPORTMESSAGE000000001",
    "sender_type": "driver",
    "sender_name": "Alex Driver",
    "message": "I need help.",
    "route_review_id": null,
    "created_at": "2026-08-19T16:00:00+00:00"
  },
  "message": "Message sent successfully",
  "error": null
}
```

---

## 4. Muhim eslatmalar

### Authentication

- Barcha so'rovlarda `Authorization: Bearer {mobile_token}` majburiy
- `X-Organization-Id: {organization_id}` majburiy
- `driver_id` `GET /api/v1/mobile/bootstrap` dan olinadi

### Response envelope

```json
{
  "status": "success",
  "success": true,
  "data": {},
  "pagination": null,
  "message": "...",
  "error": null
}
```

### Socket reconnect

App foregroundga qaytganda yoki reconnect bo'lganda:

```http
GET /api/v1/mobile/support-chat?page=1&per_page=50
```

### Deduplication

- `support.message.created` eventida `message.id` orqali
- `mobile.route-review.updated` eventida `event_id` orqali