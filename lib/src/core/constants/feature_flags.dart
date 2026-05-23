import 'package:flutter/foundation.dart';
import 'package:taxi_app/src/core/network/token_service.dart';

// Runtime-configurable feature flags. Persists in SharedPreferences and
// exposes a [ValueNotifier] so settings UI can rebuild when toggled.
class FeatureFlags {
  static const String _wsKey = 'ws_enabled';
  static const bool _wsDefault = true;

  static ValueNotifier<bool>? _wsNotifier;

  // Watchable WebSocket toggle. Use [ValueListenableBuilder] in the UI.
  // Falls back to [_wsDefault] on first launch (no stored value yet).
  static ValueNotifier<bool> get webSocketEnabledNotifier {
    return _wsNotifier ??= ValueNotifier<bool>(
      StorageRepository.getBool(_wsKey, defValue: _wsDefault),
    );
  }

  // True when WebSocket connections are allowed app-wide.
  // Read by [OrdersBloc] / [InivitesBloc] before opening `wss://...`.
  static bool get webSocketEnabled => webSocketEnabledNotifier.value;

  // Persist + broadcast a new value. Existing open channels are NOT closed
  // here - disable takes effect on the next reconnect (or next route entry,
  // since BLoCs are scoped per route in this repo).
  static Future<void> setWebSocketEnabled(bool value) async {
    await StorageRepository.putBool(key: _wsKey, value: value);
    webSocketEnabledNotifier.value = value;
  }
}
