import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:injectable/injectable.dart';
import 'package:taxi_app/core/extensions/status_code_extension.dart';
import 'package:taxi_app/core/network/toll_api_constants.dart';
import 'package:taxi_app/core/network/toll_dio.dart';
import 'package:taxi_app/core/network/toll_session.dart';
import 'package:taxi_app/core/service_locater.dart';
import 'package:taxi_app/core/utils/json_safe.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Reverb (Pusher protocol 7) client for the Quadrix support/route-review
/// push channel (docs/support-chat-api.md §1/§2).
///
/// Separate from [WebSocketService] on purpose: that one speaks a bespoke
/// `{"event":"direct","data":{...}}` envelope against `ws.quadrix.ai` for the
/// order-matching flow. This one speaks real Pusher frames
/// (`pusher:connection_established`, `pusher:subscribe`, `pusher:ping/pong`)
/// against the tolling backend's Reverb host, and needs a signed
/// per-connection auth from `POST broadcasting/auth` before it can subscribe
/// to anything - a plain WS connect is not enough on its own.
///
/// Same retain/release + auto-reconnect shape as [WebSocketService] (see that
/// file for the reasoning): [connect]/[disconnect] are paired per-caller,
/// [forceDisconnect] is for logout, [reconnect] forces a fresh socket after
/// an app resume iOS may have silently suspended.
///
/// Two business events, two broadcast streams:
///   - [supportMessageCreated] - `support.message.created`, decoded payload
///     as-is (`{"conversation": {...}, "message": {...}}`).
///   - [routeReviewUpdated] - `mobile.route-review.updated`, decoded payload
///     as-is. Per §2.2 this is ONLY a signal - callers must re-fetch the
///     review from `mobile_result_endpoint`, never read state off the event.
///
/// No-ops (skips connecting, never retries) while `QUADRIX_REVERB_HOST` /
/// `QUADRIX_REVERB_APP_KEY` are unset in `.env` - those are backend-supplied
/// values this app doesn't have yet, and a connect loop against an empty URL
/// would just burn battery. The rest of the app already works without this
/// service (REST polling), so an unconfigured socket must fail silent, not
/// loud.
@lazySingleton
class TollReverbService {
  TollReverbService();

  static const _maxReconnectDelay = Duration(seconds: 30);

  /// No frame (including the ping/pong Reverb sends on its own activity
  /// timeout) for this long while marked connected -> the socket is almost
  /// certainly dead without having told us. Mirrors [WebSocketService]'s
  /// silent-suspend detector, just a shorter threshold: Reverb's default
  /// `activity_timeout` is 30s and it pings before that, so 90s of total
  /// silence is already three missed beats.
  static const _staleThreshold = Duration(seconds: 90);
  static const _healthCheckInterval = Duration(seconds: 15);

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _routeReviewController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription? _channelSub;
  String? _channelName;
  bool _isConnected = false;
  bool _subscribed = false;
  bool _desiredConnected = false;
  int _retainCount = 0;
  int _retryCount = 0;
  Timer? _retryTimer;
  Timer? _healthTimer;
  DateTime? _lastFrameAt;

  /// `support.message.created` frames, decoded. Not deduplicated here -
  /// dedup is per-consumer (a message can matter to two different screens
  /// for two different reasons), so callers keep their own seen-id set.
  Stream<Map<String, dynamic>> get supportMessageCreated =>
      _messageController.stream;

  /// `mobile.route-review.updated` frames, decoded. Signal only - see the
  /// class doc.
  Stream<Map<String, dynamic>> get routeReviewUpdated =>
      _routeReviewController.stream;

  /// Broadcasts whenever the subscribed-and-ready state flips. Not just
  /// socket-open: a raw WS connection with no successful channel
  /// subscription yet cannot deliver either event.
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected && _subscribed;

  /// Retain: register a need for the socket. Opens on the first retainer.
  void connect() {
    _retainCount++;
    log('Reverb retain -> $_retainCount');
    if (_retainCount == 1) {
      _desiredConnected = true;
      _startHealthTimer();
      unawaited(_openSocket());
    }
  }

  /// Release: unregister a need for the socket. Closes once the last
  /// retainer has gone.
  void disconnect() {
    if (_retainCount <= 0) return;
    _retainCount--;
    log('Reverb release -> $_retainCount');
    if (_retainCount == 0) _teardown();
  }

  /// Zeroes the retain count and tears down regardless of who still holds
  /// it - logout.
  void forceDisconnect() {
    _retainCount = 0;
    _teardown();
  }

  /// Forces a fresh socket without touching the retain count - app resume.
  /// No-op while nobody currently retains the connection.
  void reconnect() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryCount = 0;
    _closeChannel();
    if (_desiredConnected) unawaited(_openSocket());
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

  Future<void> _openSocket() async {
    if (!_desiredConnected) return;
    if (_isConnected && _channel != null) return;

    final host = dotenv.env['QUADRIX_REVERB_HOST'] ?? '';
    final appKey = dotenv.env['QUADRIX_REVERB_APP_KEY'] ?? '';
    if (host.isEmpty || appKey.isEmpty) {
      log('Reverb connect skipped: QUADRIX_REVERB_HOST/APP_KEY not set');
      return;
    }

    final driverId = await TollSession.ensureDriverId();
    if (driverId.isEmpty) {
      log('Reverb connect skipped: driver id unresolved');
      _scheduleReconnect();
      return;
    }
    if (!_desiredConnected) return; // dropped while awaiting driver id
    _channelName = 'private-support.driver.$driverId';

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse(
          'wss://$host/app/$appKey?protocol=7&client=mobile&version=1.0&flash=false',
        ),
      );
      _lastFrameAt = DateTime.now();
      _subscribed = false;
      _channelSub?.cancel();
      _channelSub = _channel!.stream.listen(
        _handleFrame,
        onError: (Object error) {
          log('Reverb error: $error');
          _closeChannel();
          _scheduleReconnect();
        },
        onDone: () {
          log('Reverb closed');
          _closeChannel();
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
      await _channel!.ready;
      log('Reverb socket open, awaiting connection_established');
    } catch (e) {
      log('Reverb connect failed: $e');
      _closeChannel();
      _scheduleReconnect();
    }
  }

  void _closeChannel() {
    _channelSub?.cancel();
    _channelSub = null;
    _channel?.sink.close();
    _channel = null;
    _subscribed = false;
    _setConnected(false);
  }

  void _setConnected(bool value) {
    if (_isConnected == value) return;
    _isConnected = value;
    _emitConnectionState();
  }

  void _emitConnectionState() {
    if (!_connectionController.isClosed) {
      _connectionController.add(isConnected);
    }
  }

  void _scheduleReconnect() {
    if (!_desiredConnected) return;
    _retryTimer?.cancel();
    _retryCount = math.min(_retryCount + 1, 8);
    final seconds = math.min(
      _maxReconnectDelay.inSeconds,
      1 << (_retryCount - 1),
    );
    log('Reverb scheduling reconnect in ${seconds}s (attempt $_retryCount)');
    _retryTimer = Timer(Duration(seconds: seconds), () {
      if (_desiredConnected) unawaited(_openSocket());
    });
  }

  void _startHealthTimer() {
    _healthTimer?.cancel();
    _healthTimer = Timer.periodic(_healthCheckInterval, (_) {
      if (!_desiredConnected) return;
      final last = _lastFrameAt;
      if (_isConnected &&
          last != null &&
          DateTime.now().difference(last) > _staleThreshold) {
        log('Reverb stale (no frame for ${_staleThreshold.inSeconds}s); reconnecting');
        _closeChannel();
        unawaited(_openSocket());
        return;
      }
      if (!_isConnected && _retryTimer == null) {
        unawaited(_openSocket());
      }
    });
  }

  void _handleFrame(dynamic raw) {
    _lastFrameAt = DateTime.now();
    final Map<String, dynamic> frame;
    try {
      final decoded = jsonDecode(raw as String);
      if (decoded is! Map<String, dynamic>) return;
      frame = decoded;
    } catch (e) {
      log('Reverb frame decode failed: $e');
      return;
    }

    switch (toStr(frame['event'])) {
      case 'pusher:connection_established':
        _retryCount = 0;
        _setConnected(true);
        final socketId = toStr(_decodeData(frame['data'])['socket_id']);
        unawaited(_subscribeToChannel(socketId));
        break;

      case 'pusher:ping':
        _send({'event': 'pusher:pong', 'data': <String, dynamic>{}});
        break;

      // Reverb sends this both as a standalone frame and as the payload of
      // certain internal errors; either way there's nothing to reply to.
      case 'pusher:pong':
        break;

      case 'pusher:error':
        final info = _decodeData(frame['data']);
        final code = toInt(info['code']);
        log('Reverb fatal error $code: ${info['message']}');
        _closeChannel();
        // 4000-4099 are Pusher's non-retryable connection errors (bad app
        // key, app disabled, etc.) - retrying those forever would just spam
        // the backend with the same rejected handshake.
        if (code < 4000 || code > 4099) _scheduleReconnect();
        break;

      case 'pusher_internal:subscription_succeeded':
        _subscribed = true;
        log('Reverb subscribed to $_channelName');
        _emitConnectionState();
        break;

      case 'pusher:subscription_error':
        log('Reverb subscription failed: ${frame['data']}');
        break;

      case 'support.message.created':
        final data = _decodeData(frame['data']);
        if (data.isNotEmpty && _belongsToSession(data)) {
          _messageController.add(data);
        }
        break;

      case 'mobile.route-review.updated':
        final data = _decodeData(frame['data']);
        if (data.isNotEmpty && _belongsToSession(data, checkDriver: true)) {
          _routeReviewController.add(data);
        }
        break;

      default:
        break;
    }
  }

  /// Both business frames carry `organization_id`, and the route-review one
  /// also `driver_id` (docs/mobile-chat-complete-api-websocket.md §13.4/§13.5).
  /// A frame belonging to another organization - the driver switched while a
  /// socket opened for the previous one was still draining - or to another
  /// driver must be ignored rather than rendered (§14.3, and the QA
  /// checklist's cross-organization/cross-driver line).
  ///
  /// An id this session has not resolved yet is not treated as a mismatch:
  /// there is nothing to compare it against, and dropping every frame until
  /// bootstrap answers would lose real events.
  bool _belongsToSession(Map<String, dynamic> data, {bool checkDriver = false}) {
    final org = toStr(data['organization_id']);
    final sessionOrg = TollSession.organizationId;
    if (org.isNotEmpty && sessionOrg.isNotEmpty && org != sessionOrg) {
      log('Reverb frame for organization $org ignored (session $sessionOrg)');
      return false;
    }
    if (!checkDriver) return true;

    final driver = toStr(data['driver_id']);
    final sessionDriver = TollSession.driverId;
    if (driver.isNotEmpty &&
        sessionDriver.isNotEmpty &&
        driver != sessionDriver) {
      log('Reverb frame for driver $driver ignored (session $sessionDriver)');
      return false;
    }
    return true;
  }

  Future<void> _subscribeToChannel(String socketId) async {
    final channel = _channelName;
    if (channel == null || channel.isEmpty || socketId.isEmpty) return;
    final auth = await _authenticate(socketId: socketId, channel: channel);
    if (auth == null) {
      log('Reverb subscribe skipped: broadcasting/auth failed');
      _closeChannel();
      _scheduleReconnect();
      return;
    }
    _send({
      'event': 'pusher:subscribe',
      'data': {'auth': auth, 'channel': channel},
    });
  }

  /// `POST broadcasting/auth` (docs/support-chat-api.md §1). Goes through
  /// the normal toll Dio client - it already attaches the bearer token and
  /// `X-Organization-Id`, and this call, unlike `auth/me`, is not on the
  /// path [TollDioSettings]'s interceptor resolves those from, so there is
  /// no recursion risk in using it here.
  Future<String?> _authenticate({
    required String socketId,
    required String channel,
  }) async {
    try {
      final client = serviceLocator.get<TollDioSettings>().dio;
      final response = await client.post(
        TollApiConstants.broadcastingAuth,
        data: {'socket_id': socketId, 'channel_name': channel},
      );
      if (!response.isSuccess) return null;
      final body = toMap(response.data);
      final auth = toStrNullable(body['auth']);
      if (auth != null) return auth;
      // Defensive: every other endpoint on this backend wraps its payload in
      // `data`, so accept that shape too in case this one follows suit later.
      return toStrNullable(toMap(body['data'])['auth']);
    } catch (e) {
      log('Reverb broadcasting/auth failed: $e');
      return null;
    }
  }

  void _send(Map<String, dynamic> frame) {
    final channel = _channel;
    if (channel == null) return;
    channel.sink.add(jsonEncode(frame));
  }

  /// Pusher nests a sub-payload as a JSON-encoded **string**, not a raw
  /// object (`"data":"{\"socket_id\":\"...\"}"`). Decode that; also accept an
  /// already-decoded map, since some Reverb builds send channel events as a
  /// literal object instead.
  Map<String, dynamic> _decodeData(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        // Not JSON - fall through to empty.
      }
    }
    return const <String, dynamic>{};
  }

  Future<void> dispose() async {
    forceDisconnect();
    await _messageController.close();
    await _routeReviewController.close();
    await _connectionController.close();
  }
}
