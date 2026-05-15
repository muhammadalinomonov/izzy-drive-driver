import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:taxi_app/src/core/network/api_constants.dart';
import 'package:taxi_app/src/core/network/dio_model.dart';
import 'package:taxi_app/src/core/network/token_service.dart';

class PushNotifications {
  static bool _initialized = false;
  static StreamSubscription<String>? _tokenRefreshSub;

  static Future<void> initFCM() async {
    if (_initialized) return;
    _initialized = true;

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('🔔 Permission status: ${settings.authorizationStatus}');

    // Foreground push: do not show anything. The WebSocket-driven order
    // bloc already covers the same payload — duplicating via local
    // notification would double-fire.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('💡 Foreground push (suppressed): ${message.notification?.title}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📲 Notification tapped: data=${message.data}');
      // TODO(notif-router): port NotificationRouter from mechanic-app and
      // dispatch into Routes.router from here.
    });

    // FCM token rotation — har qachon yangi token kelganda backendga
    // jo'natamiz. Tokensiz onda backend eski qiymatga push uradi va hech
    // narsa yetib bormaydi.
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub =
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print('🔄 FCM token refreshed: ${newToken.substring(0, 12)}…');
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
        print('🚀 App launched from terminated via notification');
        // TODO(notif-router): same as above for cold-start taps.
      }
    } catch (e) {
      print('⚠️ getInitialMessage failed: $e');
    }
  }

  static Future<void> _logTokenWhenReady() async {
    try {
      bool apnsReady = !Platform.isIOS;
      if (Platform.isIOS) {
        apnsReady = await _waitForApnsToken();
      }
      if (!apnsReady) {
        print('⚠️ APNS token unavailable after 10s — skipping FCM getToken()');
        return;
      }
      final token = await FirebaseMessaging.instance.getToken();
      print('🔑 FCM Token: $token');
    } catch (e) {
      print('⚠️ Failed to fetch FCM token: $e');
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
      print('Error fetching FCM token: $e');
      return '';
    }
  }

  /// Hozirgi qurilmani backend'da ro'yxatga oladi. Token berilmasa
  /// `getToken()`dan oladi. Auth bo'lmagan holatda (refresh token bo'sh)
  /// jim o'tadi — login keyin yana chaqiriladi.
  ///
  /// Main screen ochilganda va `onTokenRefresh` ishlaganda chaqiriladi.
  /// Multi-device push pipeline `UserDevice` jadvalida tokenlarni saqlaydi,
  /// shuning uchun bir user'ning bir nechta qurilmasiga push borishi mumkin.
  static Future<void> registerDeviceWithBackend({String? token}) async {
    try {
      if (StorageRepository.getString('refresh').isEmpty) {
        // Auth qilinmagan — keyinroq main screen'da qayta chaqirish kerak.
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
      print('📡 devices/register/ → ${response.statusCode}');
    } on DioException catch (e) {
      print('⚠️ devices/register/ failed: ${e.response?.statusCode} ${e.message}');
    } catch (e) {
      print('⚠️ devices/register/ unexpected error: $e');
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
      print('⚠️ devices/register/ unregister failed: $e');
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
