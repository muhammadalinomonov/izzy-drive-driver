import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:taxi_app/src/core/constants/feature_flags.dart';
import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Single source of truth for the WebSocket connection. The driver app
/// connects to a per-user channel `usta_client_<wsId>` on the
/// microservice; opening more than one socket from the same client_id
/// caused messages to silently drop (the second connect knocks the
/// first off). All blocs subscribe to [stream] instead of opening
/// their own channel.
///
/// Resilience baked in:
///   * **Auto-reconnect on onDone / onError** with exponential backoff
///     (1s → 2s → 4s … capped at 30s). Survives transient network blips
///     without anyone calling [reconnect] manually.
///   * **Silent-suspend detector**: a 15s health timer checks
///     [_lastFrameAt]. iOS often suspends sockets in background without
///     firing onDone, so `_isConnected` keeps lying. If no frame arrived
///     in [_staleThreshold] we tear the channel down and re-open it.
///   * **Reference counting**: [connect] / [disconnect] are now retain /
///     release. The socket actually opens on the first retainer and
///     actually closes once the last retainer has gone. This lets
///     OrdersBloc and InivitesBloc independently signal "I need WS"
///     without stepping on each other — and means WS only stays open
///     while there's an active order.
///   * **Connection stream**: [connectionStream] emits whenever the
///     underlying `_isConnected` flips, so consumers (like the
///     AdaptivePoller) can escalate immediately on disconnect.
class WebSocketService {
  static const _baseUrl = 'wss://ws.quadrix.ai/ws';
  static const _maxReconnectDelay = Duration(seconds: 30);
  static const _staleThreshold = Duration(seconds: 120);
  static const _healthCheckInterval = Duration(seconds: 15);

  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription? _channelSub;
  bool _isConnected = false;
  bool _desiredConnected = false;
  int _retainCount = 0;
  int _retryCount = 0;
  Timer? _retryTimer;
  Timer? _healthTimer;
  DateTime? _lastFrameAt;

  /// Broadcast stream of decoded `data` payloads from `event=='direct'`
  /// frames. Each subscriber receives every event independently.
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  /// Broadcasts `true` when the underlying socket becomes alive, `false`
  /// when it drops. Used by AdaptivePoller to switch to fast-poll mode
  /// instantly instead of waiting for the next tick.
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected;

  /// Retain: register a need for the socket. The socket actually opens
  /// on the first retainer. Idempotent in the sense that every call
  /// must be balanced by a matching [disconnect].
  void connect() {
    if (!FeatureFlags.webSocketEnabled) {
      log('WS disabled by feature flag - skipping connect');
      return;
    }
    _retainCount++;
    log('WS retain → $_retainCount');
    if (_retainCount == 1) {
      _desiredConnected = true;
      _startHealthTimer();
      _openSocket();
    }
  }

  /// Release: unregister a need for the socket. When the last retainer
  /// drops, the channel is closed and auto-reconnect is stopped.
  void disconnect() {
    if (_retainCount <= 0) return;
    _retainCount--;
    log('WS release → $_retainCount');
    if (_retainCount == 0) {
      _teardown();
    }
  }

  /// Hard disconnect — zeroes the retain count and tears down. Use on
  /// logout, when we explicitly want all retainers cleared regardless
  /// of who's still holding.
  void forceDisconnect() {
    _retainCount = 0;
    _teardown();
  }

  /// Force a fresh socket (keeps current retain count). Useful from
  /// app-lifecycle resume — iOS may have silently killed the socket and
  /// `_isConnected` can still be lying. No-op if nobody currently
  /// retains the connection.
  void reconnect() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryCount = 0;
    _closeChannel();
    if (_desiredConnected) {
      _openSocket();
    }
  }

  // ---- internals ----

  void _teardown() {
    _desiredConnected = false;
    _retryTimer?.cancel();
    _retryTimer = null;
    _healthTimer?.cancel();
    _healthTimer = null;
    _closeChannel();
  }

  void _openSocket() {
    if (!_desiredConnected) return;
    if (_isConnected && _channel != null) return;
    final wsId = StorageRepository.getInt('ws_id');
    if (wsId <= 0) {
      log('WS connect skipped: ws_id missing');
      // Schedule a retry so ws_id being briefly missing doesn't strand us.
      _scheduleReconnect();
      return;
    }
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse(
          '$_baseUrl?user_id=usta_client_$wsId&tab_id=1&browser_id=browser_1',
        ),
      );
      _lastFrameAt = DateTime.now();
      log('WS connecting as usta_client_$wsId');
      _channelSub?.cancel();
      _channelSub = _channel!.stream.listen(
        _handleFrame,
        onError: (Object error) {
          log('WS error: $error');
          _closeChannel();
          _scheduleReconnect();
        },
        onDone: () {
          log('WS closed');
          _closeChannel();
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
      // Set connected only after the handshake completes — avoids the
      // health-timer stale check being fooled by a half-open channel.
      _channel!.ready.then(
        (_) {
          if (_desiredConnected && _channel != null) {
            _setConnected(true);
            log('WS connected as usta_client_$wsId');
          }
        },
        onError: (_) {/* stream's onError fires too; nothing to do here */},
      );
    } catch (e) {
      log('WS connect failed: $e');
      _closeChannel();
      _scheduleReconnect();
    }
  }

  void _closeChannel() {
    _channelSub?.cancel();
    _channelSub = null;
    _channel?.sink.close();
    _channel = null;
    _setConnected(false);
  }

  void _setConnected(bool value) {
    if (_isConnected == value) return;
    _isConnected = value;
    if (!_connectionController.isClosed) {
      _connectionController.add(value);
    }
  }

  /// Backoff retry: 1s, 2s, 4s, 8s, … capped at 30s. Stops once
  /// [_desiredConnected] flips false.
  void _scheduleReconnect() {
    if (!_desiredConnected) return;
    _retryTimer?.cancel();
    _retryCount = math.min(_retryCount + 1, 8);
    final seconds = math.min(
      _maxReconnectDelay.inSeconds,
      1 << (_retryCount - 1),
    );
    log('WS scheduling reconnect in ${seconds}s (attempt $_retryCount)');
    _retryTimer = Timer(Duration(seconds: seconds), () {
      if (_desiredConnected) _openSocket();
    });
  }

  void _startHealthTimer() {
    _healthTimer?.cancel();
    _healthTimer = Timer.periodic(_healthCheckInterval, (_) {
      if (!_desiredConnected) return;
      final last = _lastFrameAt;
      // Silent-suspend: socket says connected but no traffic for ages
      // → kill and re-open. iOS background suspension hits this path.
      // 120s — long enough that an event-driven socket without keepalive
      // frames doesn't get torn down mid-idle, short enough to recover
      // before the user notices.
      if (_isConnected &&
          last != null &&
          DateTime.now().difference(last) > _staleThreshold) {
        log('WS stale (no frame for ${_staleThreshold.inSeconds}s); reconnecting');
        _closeChannel();
        _openSocket();
        return;
      }
      // Should be connected but somehow isn't (and no retry pending) — try.
      if (!_isConnected && _retryTimer == null) {
        _openSocket();
      }
    });
  }

  /// WS frames look like:
  ///   {"event":"direct","data":{"event-status":"new-proposal", ...}}
  /// Non-`direct` envelopes are ignored. Decoded payloads land on
  /// [stream]. Every frame (regardless of envelope) bumps [_lastFrameAt]
  /// so the silent-suspend detector sees liveness.
  void _handleFrame(dynamic raw) {
    _lastFrameAt = DateTime.now();
    _retryCount = 0; // reset backoff only on confirmed live traffic
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
    forceDisconnect();
    await _controller.close();
    await _connectionController.close();
  }
}
