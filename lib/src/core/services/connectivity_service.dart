import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Singleton wrapper around `connectivity_plus`. Tracks whether the
/// device currently has any network transport (wifi/mobile/ethernet/vpn)
/// and broadcasts boolean changes on [onlineStream]. The app uses this
/// to gate the splash screen, drive the no-internet bottom sheet, and
/// auto-reconnect the WebSocket once connectivity returns.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService _instance = ConnectivityService._();
  factory ConnectivityService() => _instance;

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _isOnline = true;
  bool _initialized = false;

  Stream<bool> get onlineStream => _controller.stream;

  bool get isOnline => _isOnline;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final initial = await _connectivity.checkConnectivity();
    _isOnline = _resultsAreOnline(initial);
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      final online = _resultsAreOnline(results);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(online);
      }
    });
  }

  /// Resolves when [isOnline] flips to true. Returns immediately when
  /// already online.
  Future<void> waitUntilOnline() async {
    if (_isOnline) return;
    await onlineStream.firstWhere((online) => online);
  }

  /// Force a fresh platform-level connectivity check and propagate any
  /// change through [onlineStream]. Returns the freshly determined flag.
  Future<bool> recheck() async {
    final results = await _connectivity.checkConnectivity();
    final online = _resultsAreOnline(results);
    if (online != _isOnline) {
      _isOnline = online;
      _controller.add(online);
    }
    return online;
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    await _controller.close();
  }

  bool _resultsAreOnline(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }
}
