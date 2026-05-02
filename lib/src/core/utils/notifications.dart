import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotifications {
  static bool _initialized = false;

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
