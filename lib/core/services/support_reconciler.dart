import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:taxi_app/core/service_locater.dart';
import 'package:taxi_app/core/services/toll_reverb_service.dart';

/// The reconcile cadence both support screens run
/// (docs/mobile-chat-complete-api-websocket.md §14.4), extracted so
/// `support_timeline_page.dart` and `route_support_page.dart` share one
/// policy instead of each keeping its own timer.
///
/// §14.4 names four triggers and rules out constant polling: reconcile when
/// the socket (re)subscribes, when the app resumes, on a manual refresh, and
/// on a watchdog for a review still waiting on a decision. This class owns
/// all four:
///
///   - **socket resubscribe** - [TollReverbService.connectionStream] flipping
///     to ready. Anything that happened while the socket was down was never
///     delivered, so page 1 has to be re-read.
///   - **resume** - `AppLifecycleState.resumed`, which also forces a fresh
///     socket, since iOS can suspend one without closing it.
///   - **manual** - [manual], wired to pull-to-refresh.
///   - **watchdog** - see [_shouldTick] for why it has two speeds.
///
/// Individual socket frames do *not* come through here: each bloc listens to
/// them itself and decides whether the frame is enough on its own or needs a
/// refetch.
class SupportReconciler with WidgetsBindingObserver {
  SupportReconciler({required this.onReconcile, required this.isPending});

  /// Re-read page 1. Called on every trigger above; expected to be cheap and
  /// silent on failure (the screen already holds a correct-enough state).
  final VoidCallback onReconcile;

  /// Whether the screen is still waiting on something the server has to say -
  /// a `pending` review, an unanswered request. Only consulted while the
  /// socket is live: it decides whether the slow watchdog runs at all.
  final bool Function() isPending;

  /// §14.4's `reconcile_after_seconds`. A backstop for a dropped event, not a
  /// data source, so it only runs while something is actually pending.
  static const Duration watchdogInterval = Duration(seconds: 180);

  /// Used *instead of* the watchdog while the socket is not delivering -
  /// which today is always, since `QUADRIX_REVERB_HOST` is still unset (see
  /// [TollReverbService]). Without a socket, REST is the only way an approval
  /// ever reaches the driver looking at the screen, so §14.4's "no constant
  /// polling" rule cannot apply: it presumes working push. The moment the
  /// socket does subscribe, this stops and the watchdog takes over.
  static const Duration offlinePollInterval = Duration(seconds: 15);

  /// How often the schedule is re-evaluated. Well under both intervals above
  /// so a socket dropping mid-interval is noticed promptly, and cheap: a tick
  /// that decides "not yet" does no work.
  static const Duration _tick = Duration(seconds: 5);

  final TollReverbService _reverb = serviceLocator<TollReverbService>();

  StreamSubscription<bool>? _connectionSub;
  Timer? _timer;
  DateTime _lastReconcileAt = DateTime.now();
  bool _socketReady = false;
  bool _started = false;

  /// Begins observing. Call from `initState`, after dispatching the screen's
  /// own initial load - that load counts as the first reconcile.
  void start() {
    if (_started) return;
    _started = true;
    _socketReady = _reverb.isConnected;
    WidgetsBinding.instance.addObserver(this);
    _connectionSub = _reverb.connectionStream.listen(_onConnectionChanged);
    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  /// Call from `dispose`.
  void stop() {
    if (!_started) return;
    _started = false;
    _timer?.cancel();
    _timer = null;
    _connectionSub?.cancel();
    _connectionSub = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Pull-to-refresh. Reconciles immediately and restarts the interval, so a
  /// driver who just pulled isn't refreshed again a second later.
  void manual() => _reconcile();

  /// Lets a screen tell the reconciler it has just re-read page 1 for its own
  /// reasons (a socket frame it handled, a mutation that returned fresh
  /// state), so the watchdog doesn't immediately repeat that work.
  void markReconciled() => _lastReconcileAt = DateTime.now();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _reconcile();
    // iOS can silently suspend the WS in the background without closing it -
    // force a fresh socket rather than waiting on the health timer to notice.
    _reverb.reconnect();
  }

  void _onConnectionChanged(bool ready) {
    final wasReady = _socketReady;
    _socketReady = ready;
    // Only the down -> up edge matters: §14.4's first trigger. Going down
    // needs nothing now; the offline poll picks up on the next tick.
    if (ready && !wasReady) _reconcile();
  }

  void _onTick() {
    if (_shouldTick()) _reconcile();
  }

  /// Two speeds, decided by whether push is actually working:
  ///
  ///   - socket live: the watchdog only, and only while [isPending] - a
  ///     settled review has nothing left to arrive for it.
  ///   - socket down: the offline poll, unconditionally - see
  ///     [offlinePollInterval].
  bool _shouldTick() {
    final elapsed = DateTime.now().difference(_lastReconcileAt);
    if (!_socketReady) return elapsed >= offlinePollInterval;
    return isPending() && elapsed >= watchdogInterval;
  }

  void _reconcile() {
    _lastReconcileAt = DateTime.now();
    onReconcile();
  }
}
