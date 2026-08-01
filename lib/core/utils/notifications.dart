import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:taxi_app/core/network/api_constants.dart';
import 'package:taxi_app/core/network/dio_model.dart';
import 'package:taxi_app/core/network/token_service.dart';
import 'package:taxi_app/routes/app_router.dart';
import 'package:taxi_app/routes/pages.dart';

class PushNotifications {
  static bool _initialized = false;
  static StreamSubscription<String>? _tokenRefreshSub;

  /// Notification event keldi - global ping. NotificationsBloc shu notifierga
  /// listener qo'shadi va o'qilmagan soni yangilanadi. Counter sifatida
  /// ishlatamiz - value har safar incrementga uchraydi.
  static final ValueNotifier<int> notificationPing = ValueNotifier<int>(0);

  /// Background/cold-start tap'da ochilishi kerak bo'lgan notification ID.
  /// MainScreen `initState`'da o'qib navigate qiladi va clear qilib qo'yadi.
  static int? pendingDeepLinkNotificationId;

  // ---- Local notifications plugin (foreground banner) ----
  static final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _localInited = false;

  /// Android notification channel — high importance, sound + vibration.
  /// iOS uchun alohida sozlamani initFCM `requestPermission`'da qilamiz.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'driver_order_events',
    'Order events',
    description: 'Order lifecycle, new proposals, admin announcements',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  static void _handleIncomingMessage(RemoteMessage message, {required bool fromTap}) {
    final event = (message.data['event'] ?? '').toString();
    // Admin xabarlari uchun ro'yxat / badge ping — har vaqt.
    if (event == 'notification') {
      notificationPing.value = notificationPing.value + 1;
      if (fromTap) {
        final idStr = (message.data['notification_id'] ?? '').toString();
        final id = int.tryParse(idStr);
        if (id != null) pendingDeepLinkNotificationId = id;
      }
    }
    // Foreground banner:
    //  • Android — FCM foreground'da bannerni AVTOMATIK chiqarmaydi, shuning
    //    uchun uni o'zimiz `flutter_local_notifications` orqali chizamiz.
    //  • iOS — bannerni FCM native chiqaradi (initFCM'dagi
    //    `setForegroundNotificationPresentationOptions(alert: true)`). Local
    //    plugin bu yerda umuman ko'rsata olmaydi, chunki `UNUserNotificationCenter`
    //    delegate'ini `firebase_messaging` egallab turadi — local `show()` jimgina
    //    tashlab yuboriladi. iOS'da uni o'tkazib yuborish no-op'dan (va delegate
    //    egaligi kelajakda o'zgarsa, ikki banner chiqishidan) qutqaradi.
    // background / terminated holatda OS `notification` payload bo'lsa bannerni
    // o'zi chiqargan bo'ladi, biz dublyaj qilmaymiz.
    if (!fromTap && !Platform.isIOS) {
      _showLocalBanner(message);
    }
    // Tap (foreground'dagi local banner yoki background'dagi tap) keyin
    // event'ga qarab deep-link navigate qiladi.
    if (fromTap) {
      _deepLinkFromMessage(message);
    }
  }

  // ---- Foreground banner via flutter_local_notifications ----

  /// FCM payload'idan title/body olib local notification chiqaradi. Backend
  /// odatda `notification` payload (title+body) yuboradi — undan foydalanamiz;
  /// faqat `data` bo'lsa, event turi bo'yicha mahalliy fallback matnlarni
  /// ko'rsatamiz.
  static Future<void> _showLocalBanner(RemoteMessage message) async {
    if (!_localInited) return;
    final event = (message.data['event'] ?? '').toString();
    if (event.isEmpty && message.notification == null) return;

    final fallback = _fallbackTextFor(event, message.data);
    final title = message.notification?.title ?? fallback.title;
    final body = message.notification?.body ?? fallback.body;
    if (title.isEmpty && body.isEmpty) return;

    // Notification ID — bir xil event qayta-qayta kelganda eski banner
    // o'rniga yangisi chiqishi uchun event-asoslangan stable hash.
    final id = (event.hashCode & 0x7fffffff) % 100000;

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      ticker: title,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.active,
    );
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Tap callback uchun event + data ni payload qilamiz.
    final payload = jsonEncode({
      'event': event,
      'data': message.data,
    });

    try {
      await _localPlugin.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('local notification show failed: $e');
    }
  }

  static ({String title, String body}) _fallbackTextFor(
      String event, Map<String, dynamic> data) {
    switch (event) {
      case 'order-accepted-at-mechanic':
        final name = (data['mechanic_name'] ?? '').toString();
        return (
          title: 'Mechanic accepted your order',
          body: name.isEmpty ? 'Tap to view details' : '$name accepted',
        );
      case 'mechanic-arrived':
        return (title: 'Mechanic arrived', body: 'Tap to view details');
      case 'mechanic-inprogress':
        return (title: 'Work in progress', body: 'Mechanic started the job');
      case 'mechanic-done':
      case 'order-completed':
        return (title: 'Order completed', body: 'Tap to leave a review');
      case 'new-suborder':
        final title = (data['title'] ?? 'Extra work').toString();
        final price = (data['price'] ?? '').toString();
        return (
          title: 'New extra work proposal',
          body: price.isEmpty ? title : '$title — \$$price',
        );
      case 'new-proposal':
        final name = (data['mechanic_name'] ?? '').toString();
        final price = (data['proposed_price'] ?? '').toString();
        return (
          title: 'New offer received',
          body: name.isEmpty
              ? (price.isEmpty ? 'Tap to view' : '\$$price')
              : '$name — \$$price',
        );
      case 'update-order-price':
        return (title: 'Order price updated', body: 'Tap to view');
      default:
        return (title: '', body: '');
    }
  }

  /// Local banner tap callback (foreground). FCM tap (background/terminated)
  /// alohida yo'l bilan boradi — `_handleIncomingMessage(fromTap: true)`.
  static void _onLocalTap(NotificationResponse resp) {
    final payload = resp.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      final event = (decoded['event'] ?? '').toString();
      final data = (decoded['data'] as Map?)?.cast<String, dynamic>() ?? {};
      _deepLinkFromMessage(RemoteMessage(data: data), eventOverride: event);
    } catch (e) {
      debugPrint('local tap payload decode failed: $e');
    }
  }

  /// Event'ga qarab deep-link route. GoRouter `Routes.router` orqali navigate
  /// qilamiz — kontekstga bog'liq emas (notification tap har qaerdan kelishi
  /// mumkin).
  static void _deepLinkFromMessage(RemoteMessage message,
      {String? eventOverride}) {
    final event = eventOverride ?? (message.data['event'] ?? '').toString();
    switch (event) {
      case 'notification':
        final idStr = (message.data['notification_id'] ?? '').toString();
        final id = int.tryParse(idStr);
        if (id != null) {
          // MainScreen `initState`'da ham, foreground tap'da ham bir xil
          // path: pendingDeepLinkNotificationId orqali detail screen'ga.
          pendingDeepLinkNotificationId = id;
          // Foreground holatida darhol navigate qila olamiz:
          Routes.router.go(Pages.notificationDetail, extra: id);
        } else {
          Routes.router.go(Pages.notifications);
        }
        break;
      case 'order-accepted-at-mechanic':
      case 'mechanic-arrived':
      case 'mechanic-inprogress':
      case 'mechanic-done':
      case 'order-completed':
      case 'new-suborder':
      case 'update-order-price':
        Routes.router.go(Pages.processOrder);
        break;
      case 'new-proposal':
        Routes.router.go(Pages.invitesPage);
        break;
      default:
        break;
    }
  }

  static Future<void> _initLocalNotifications() async {
    if (_localInited) return;
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      // ^ Permissionlarni `FirebaseMessaging.requestPermission` allaqachon
      // so'ragan; ikki marta so'rab foydalanuvchini bezovta qilmaymiz.
    );
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _localPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onLocalTap,
    );
    // Android channel'ni oldindan ro'yxatga olamiz (sound/vibrate sozlamasi
    // channel darajasida qulflanadi — keyinroq AndroidNotificationDetails'da
    // qayta ko'rsatishimiz shart emas).
    final androidImpl = _localPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_channel);
    _localInited = true;
  }

  static Future<void> initFCM() async {
    if (_initialized) return;
    _initialized = true;

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('🔔 Permission status: ${settings.authorizationStatus}');

    // iOS: foreground'da bannerni FCM NATIVE chiqarsin (alert: true).
    // `firebase_messaging` `UNUserNotificationCenter` delegate'ini egallab
    // turadi, shuning uchun `flutter_local_notifications` iOS foreground'da
    // banner ko'rsata olmaydi (local `show()` jimgina tashlanadi). Yagona
    // ishonchli yo'l — FCM'ning o'zi `notification` payload'ini ko'rsatishi.
    // Android'da bu chaqiruv ta'sir qilmaydi; u yerda foreground bannerni
    // local plugin chizadi.
    if (Platform.isIOS) {
      try {
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (e) {
        debugPrint('⚠️ setForegroundNotificationPresentationOptions: $e');
      }
    }

    // Local plugin Android foreground banneri va tap callback'i uchun kerak.
    // Eslatma: iOS'da `UNUserNotificationCenter.delegate` baribir
    // `firebase_messaging`niki bo'lib qoladi (swizzling), shuning uchun bu
    // yerda init tartibi iOS foreground prezentatsiyasiga ta'sir qilmaydi —
    // iOS bannerni FCM native chiqaradi (yuqoridagi presentation options).
    await _initLocalNotifications();

    // Foreground: Android'da local banner ko'rsatamiz (event turi bo'yicha matn
    // tanlanadi, tap qilinsa event-asoslangan deep-link qiladi). iOS'da
    // _handleIncomingMessage local bannerni o'tkazib yuboradi.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('💡 Foreground push: data=${message.data}');
      _handleIncomingMessage(message, fromTap: false);
    });

    // Background/terminated push tap → app foreground.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📲 Notification tapped (background → fg): data=${message.data}');
      _handleIncomingMessage(message, fromTap: true);
    });

    // FCM token rotation - har qachon yangi token kelganda backendga
    // jo'natamiz. Tokensiz onda backend eski qiymatga push uradi va hech
    // narsa yetib bormaydi.
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub =
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM token refreshed: ${newToken.substring(0, 12)}…');
      registerDeviceWithBackend(token: newToken);
    });

    // Fire-and-forget: getInitialMessage() can block on iOS cold start when
    // APNS isn't ready, which would freeze the splash on a white screen.
    // Resolve it after runApp() instead.
    _consumeInitialMessage();

    _logTokenWhenReady();
  }

  static Future<void> _consumeInitialMessage() async {
    try {
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🚀 App launched from terminated via notification');
        _handleIncomingMessage(initialMessage, fromTap: true);
      }
    } catch (e) {
      debugPrint('⚠️ getInitialMessage failed: $e');
    }
  }

  static Future<void> _logTokenWhenReady() async {
    try {
      bool apnsReady = !Platform.isIOS;
      if (Platform.isIOS) {
        apnsReady = await _waitForApnsToken();
      }
      if (!apnsReady) {
        debugPrint('⚠️ APNS token unavailable after 10s - skipping FCM getToken()');
        return;
      }
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('🔑 FCM Token: $token');
    } catch (e) {
      debugPrint('⚠️ Failed to fetch FCM token: $e');
    }
  }

  static Future<String> getToken() async {
    try {
      if (Platform.isIOS) {
        await _waitForApnsToken();
      }
      final token = await FirebaseMessaging.instance.getToken();
      return token ?? '';
    } catch (e) {
      debugPrint('Error fetching FCM token: $e');
      return '';
    }
  }

  /// Hozirgi qurilmani backend'da ro'yxatga oladi. Token berilmasa
  /// `getToken()`dan oladi. Auth bo'lmagan holatda (refresh token bo'sh)
  /// jim o'tadi - login keyin yana chaqiriladi.
  ///
  /// Main screen ochilganda va `onTokenRefresh` ishlaganda chaqiriladi.
  /// Multi-device push pipeline `UserDevice` jadvalida tokenlarni saqlaydi,
  /// shuning uchun bir user'ning bir nechta qurilmasiga push borishi mumkin.
  static Future<void> registerDeviceWithBackend({String? token}) async {
    try {
      if (StorageRepository.getString('refresh').isEmpty) {
        // Auth qilinmagan - keyinroq main screen'da qayta chaqirish kerak.
        return;
      }
      final fcmToken = (token ?? await getToken()).trim();
      if (fcmToken.isEmpty) return;

      final platform = Platform.isIOS
          ? 'ios'
          : Platform.isAndroid
              ? 'android'
              : 'web';

      final dio = DioSettings().dio;
      final response = await dio.post(
        ApiConstants.devicesRegister,
        data: {'token': fcmToken, 'platform': platform},
      );
      debugPrint('📡 devices/register/ → ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('⚠️ devices/register/ failed: ${e.response?.statusCode} ${e.message}');
    } catch (e) {
      debugPrint('⚠️ devices/register/ unexpected error: $e');
    }
  }

  /// Logout vaqtida hozirgi qurilmani backend'dan o'chiradi. Boshqa
  /// qurilmalardagi sessiyalar va push'lar ishlayveradi.
  static Future<void> unregisterDeviceFromBackend({String? token}) async {
    try {
      if (StorageRepository.getString('refresh').isEmpty) return;
      final fcmToken = (token ?? await getToken()).trim();
      if (fcmToken.isEmpty) return;
      final dio = DioSettings().dio;
      await dio.delete(
        ApiConstants.devicesRegister,
        data: {'token': fcmToken},
      );
    } catch (e) {
      debugPrint('⚠️ devices/register/ unregister failed: $e');
    }
  }

  /// Polls FirebaseMessaging.getAPNSToken() until non-null or timeout.
  /// Without this, getToken() throws `apns-token-not-set` on iOS at
  /// cold start.
  static Future<bool> _waitForApnsToken({
    Duration timeout = const Duration(seconds: 10),
    Duration pollInterval = const Duration(milliseconds: 300),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final apns = await FirebaseMessaging.instance.getAPNSToken();
      if (apns != null && apns.isNotEmpty) return true;
      await Future.delayed(pollInterval);
    }
    return false;
  }
}