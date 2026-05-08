import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:taxi_app/src/core/constants/feature_flags.dart';
import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Single source of truth for the WebSocket connection. The driver app
/// connects to a per-user channel `usta_client_<wsId>` on the
/// microservice; opening more than one socket from the same client_id
/// caused messages to silently drop (the second connect knocks the
/// first off). All blocs subscribe to [stream] instead of opening
/// their own channel.
class WebSocketService {
  static const _baseUrl = 'wss://ws.quadrix.ai/ws';

  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription? _channelSub;
  bool _isConnected = false;

  /// Broadcast stream of decoded `data` payloads from `event=='direct'`
  /// frames. Each subscriber receives every event independently.
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  bool get isConnected => _isConnected;

  void connect() {
    if (!FeatureFlags.webSocketEnabled) {
      log('WS disabled by feature flag — skipping connect');
      return;
    }
    if (_isConnected && _channel != null) {
      return;
    }
    final wsId = StorageRepository.getInt('ws_id');
    if (wsId <= 0) {
      log('WS connect skipped: ws_id missing');
      return;
    }
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('$_baseUrl?user_id=usta_client_$wsId&tab_id=1&browser_id=browser_1'),
      );
      _isConnected = true;
      log('WS connected as usta_client_$wsId');
      _channelSub?.cancel();
      _channelSub = _channel!.stream.listen(
        _handleFrame,
        onError: (Object error) {
          log('WS error: $error');
          _isConnected = false;
        },
        onDone: () {
          log('WS closed');
          _isConnected = false;
        },
        cancelOnError: true,
      );
    } catch (e) {
      log('WS connect failed: $e');
      _isConnected = false;
    }
  }

  void disconnect() {
    _channelSub?.cancel();
    _channelSub = null;
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  /// Force a fresh socket. iOS often suspends the WS during background
  /// without firing onDone, so [_isConnected] can be a lie. Call this
  /// from app lifecycle resume.
  void reconnect() {
    disconnect();
    connect();
  }

  /// WS frames look like:
  ///   {"event":"direct","data":{"event-status":"new-proposal", ...}}
  /// Non-`direct` envelopes are ignored. Decoded payloads land on
  /// [stream].
  void _handleFrame(dynamic raw) {
    try {
      final decoded = jsonDecode(raw as String);
      if (decoded is! Map<String, dynamic>) return;
      if (decoded['event'] != 'direct') return;
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        _controller.add(data);
      }
    } catch (e) {
      log('WS frame decode failed: $e');
    }
  }

  Future<void> dispose() async {
    disconnect();
    await _controller.close();
  }
}
