import 'dart:async';

import 'package:taxi_app/src/core/services/websocket_service.dart';

/// WebSocket-aware adaptive poller.
///
/// Har `tickInterval` da [_onTick] chaqiriladi va WS holatiga qarab poll
/// qiladi:
/// * WS **ulangan** — har `normalPollTicks` ta tick'da bir marta (30s default)
/// * WS **uzilgan** — har tick'da (10s default)
///
/// Backup vazifasini bajaradi: WS event yetib bormay qolsa yoki socket jim
/// turib qolsa, polling oxirgi ma'lumotlarni darrov olib keladi.
class AdaptivePoller {
  AdaptivePoller({
    required this.ws,
    required this.onPoll,
    this.onTick,
    this.tickInterval = const Duration(seconds: 10),
    this.normalPollTicks = 3,
  });

  final WebSocketService ws;

  /// Asosiy polling callback'i (masalan, `bloc.add(FetchEvent())`).
  final void Function() onPoll;

  /// Har tick'da chaqiriladigan ixtiyoriy callback (poll qilinmagan
  /// tick'lar uchun ham) — odatda time-ago label'larni yangilash uchun
  /// `setState(() {})` qilamiz.
  final void Function()? onTick;

  /// WS ulangan paytdagi tick interval'i; uzilgan paytda har tick poll.
  final Duration tickInterval;

  /// WS ulangan paytda nechta tick'dan keyin poll qilish.
  /// Default 3 × 10s = 30s.
  final int normalPollTicks;

  Timer? _timer;
  int _ticks = 0;
  bool _paused = false;

  /// Polling'ni boshlash.
  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(tickInterval, (_) => _tick());
  }

  /// To'xtatish (background-ga ketganda yoki ekran yopilganda).
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Vaqtinchalik pauza (timer ishlashda davom etadi, lekin poll qilinmaydi).
  set paused(bool value) {
    _paused = value;
  }

  void _tick() {
    if (_paused) return;
    _ticks++;
    onTick?.call();
    final shouldPoll = !ws.isConnected || _ticks >= normalPollTicks;
    if (shouldPoll) {
      _ticks = 0;
      onPoll();
    }
  }

  /// Resource'larni tozalash. State.dispose()-da chaqiring.
  void dispose() {
    stop();
  }
}
