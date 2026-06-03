import Flutter
import UIKit
import UserNotifications
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    print("🚀 AppDelegate: didFinishLaunchingWithOptions")

    // Become the UNUserNotificationCenter delegate explicitly. With the new
    // UIScene + implicit-engine lifecycle, Firebase's app-delegate-proxy does
    // NOT reliably wire this up, so `setForegroundNotificationPresentationOptions`
    // never takes effect and foreground pushes are silently dropped. Setting it
    // here (Firebase swizzling still wraps us, so `onMessage` keeps firing) makes
    // our `willPresent` below the source of truth for foreground presentation.
    UNUserNotificationCenter.current().delegate = self

    // Explicit notification authorization + APNS registration. Without this,
    // FirebaseMessaging.getInitialMessage() can block in main() waiting for an
    // APNS token that never arrives.
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .badge, .sound]
    ) { granted, error in
      print("🔔 AppDelegate: notification auth granted=\(granted) error=\(String(describing: error))")
      DispatchQueue.main.async {
        print("📡 AppDelegate: calling registerForRemoteNotifications()")
        application.registerForRemoteNotifications()
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenHex = deviceToken.map { String(format: "%02x", $0) }.joined()
    print("✅ APNS device token received: \(tokenHex)")
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("❌ Failed to register for remote notifications")
    print("   Error: \(error.localizedDescription)")
    print("   Full: \(error)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  // Foreground presentation. iOS asks the notification-center delegate whether
  // to show a banner while the app is open. Without an explicit delegate +
  // present options under the new UIScene/implicit-engine lifecycle, iOS hands
  // the push to the app silently (no banner) — exactly the "only background
  // works" symptom.
  //
  // FlutterAppDelegate already implements this (it forwards to plugins), so we
  // `override`. We first forward to super so firebase_messaging still processes
  // the message and `onMessage` keeps firing in Dart (unread-counter, tap setup)
  // — but we swallow the plugins' completion with a no-op and then call the real
  // completion ourselves with banner/list/sound/badge. iOS presents per the real
  // handler only, so there is exactly one banner (no duplicate) and the app is
  // guaranteed to show the foreground notification.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    super.userNotificationCenter(center, willPresent: notification) { _ in }
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
