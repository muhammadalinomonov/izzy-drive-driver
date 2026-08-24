import 'dart:async';
import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:taxi_app/core/service_locater.dart';
import 'package:taxi_app/core/services/toll_reverb_service.dart';
import 'package:taxi_app/core/session/premium_session.dart';
import 'package:taxi_app/core/utils/json_safe.dart';
import 'package:taxi_app/features/trips/data/model/support_chat_model.dart';
import 'package:taxi_app/features/trips/data/model/support_timeline_model.dart';
import 'package:taxi_app/features/trips/domain/repo/support_chat_repo.dart';

part 'support_timeline_event.dart';
part 'support_timeline_state.dart';

/// Backs `support_timeline_page.dart` - the driver's single merged support
/// screen (docs/mobile-chat-complete-api-websocket.md §6), which replaced the
/// old split between a plain-message page and a per-review page. Every
/// "Support Message" and "Send request" entry point in the app opens here
/// now; opening one route-review card still goes to `route_support_page.dart`
/// for the deeper interaction (replying within that review, confirming a
/// fuel stop, cancelling, Drive) - this bloc only owns the merged feed itself
/// and the plain-message composer.
///
/// State is a **keyed store**, exactly as §14.1 prescribes: every item is
/// upserted under its server-assigned `message:{id}` / `route_review:{id}`
/// key and the feed is re-derived from it. That is what makes a page-1
/// reconcile safe to run at any time without discarding older pages the
/// driver has scrolled back to, and what makes a redelivered socket frame a
/// no-op rather than a duplicate row.
///
/// Same "replace, don't patch" discipline as `RouteSupportBloc`: a socket
/// frame is only ever a reason to reload page 1, never a source of state by
/// itself, with one deliberate exception - a plain `support.message.created`
/// (no `route_review_id`) already carries the full message, so it is
/// upserted directly instead of paying for a round trip to fetch what the
/// event already handed over.
@injectable
class SupportTimelineBloc
    extends Bloc<SupportTimelineEvent, SupportTimelineState> {
  final SupportChatRepo repo;

  static const int _perPage = 50;

  final TollReverbService _reverb = serviceLocator<TollReverbService>();
  StreamSubscription<Map<String, dynamic>>? _reverbMessageSub;
  StreamSubscription<Map<String, dynamic>>? _reverbReviewSub;
  bool _reverbRetained = false;

  /// The keyed store behind [SupportTimelineState.items] - see the class doc.
  /// Insertion-ordered so items the server gave no `occurred_at` still land
  /// somewhere stable rather than jumping between rebuilds.
  final LinkedHashMap<String, SupportTimelineItem> _byKey = LinkedHashMap();

  /// Message ids already seen on the socket. Separate from [_byKey] on
  /// purpose: a review-linked frame triggers a refetch instead of an upsert,
  /// so its id is not in the store yet when a reconnect redelivers it, and
  /// without this it would trigger the same refetch again.
  final Set<String> _seenSocketMessageIds = {};

  /// `mobile.route-review.updated` `event_id`s already turned into a reload.
  final Set<String> _seenReviewEventIds = {};

  SupportTimelineBloc({required this.repo})
      : super(const SupportTimelineState()) {
    on<SupportTimelineStarted>(_onStarted);
    on<SupportTimelineRefreshed>(_onRefreshed);
    on<SupportTimelineOlderRequested>(_onOlderRequested);
    on<SupportTimelineMessageSent>(_onMessageSent);
    on<_SupportTimelineItemUpserted>(_onItemUpserted);
  }

  Future<void> _onStarted(
    SupportTimelineStarted event,
    Emitter<SupportTimelineState> emit,
  ) async {
    if (!PremiumSession.isPremium) {
      emit(state.copyWith(status: SupportTimelineStatus.restricted));
      return;
    }

    emit(state.copyWith(
      status: SupportTimelineStatus.loading,
      errorMessage: '',
    ));

    final response = await repo.fetchTimeline(perPage: _perPage);
    if (response.errorText.isNotEmpty || response.data == null) {
      emit(state.copyWith(
        status: SupportTimelineStatus.failure,
        errorMessage: response.errorText,
      ));
      return;
    }

    // A retry after a failure re-reads from scratch; anything held from an
    // earlier attempt is stale by definition.
    _byKey.clear();
    final page = response.data!;
    _upsertAll(page.items);
    emit(state.copyWith(
      status: SupportTimelineStatus.ready,
      items: _feed(),
      loadedPage: page.page,
      lastPage: page.lastPage,
    ));

    _retainReverb();
  }

  /// Silent reload of page 1 - the reconcile step behind a resume, a manual
  /// pull-to-refresh, a socket resubscribe, and every socket signal that
  /// needs more than the frame itself carries (§14.4). Upserts rather than
  /// replaces, so older pages already pulled in by
  /// [SupportTimelineOlderRequested] survive it.
  ///
  /// Failure is invisible: the feed already on screen stays correct, and the
  /// next trigger tries again.
  Future<void> _onRefreshed(
    SupportTimelineRefreshed event,
    Emitter<SupportTimelineState> emit,
  ) async {
    if (state.status != SupportTimelineStatus.ready || state.sending) return;

    final response = await repo.fetchTimeline(perPage: _perPage);
    if (response.errorText.isNotEmpty || response.data == null) return;

    final page = response.data!;
    _upsertAll(page.items);
    emit(state.copyWith(items: _feed(), lastPage: page.lastPage));
  }

  /// Scrolling back past the oldest item loaded so far. §6's pagination
  /// counts messages and cards together in one newest-first sequence, so an
  /// older page is simply the next page number - no per-type cursor.
  Future<void> _onOlderRequested(
    SupportTimelineOlderRequested event,
    Emitter<SupportTimelineState> emit,
  ) async {
    if (state.status != SupportTimelineStatus.ready) return;
    if (state.loadingMore || !state.hasMore) return;

    emit(state.copyWith(loadingMore: true));

    final next = state.loadedPage + 1;
    final response = await repo.fetchTimeline(page: next, perPage: _perPage);
    if (response.errorText.isNotEmpty || response.data == null) {
      // Silent, like a failed reconcile: the driver can pull again. Nothing
      // was removed, so there is nothing to explain.
      emit(state.copyWith(loadingMore: false));
      return;
    }

    final page = response.data!;
    _upsertAll(page.items);
    emit(state.copyWith(
      items: _feed(),
      loadingMore: false,
      loadedPage: page.page,
      lastPage: page.lastPage,
    ));
  }

  Future<void> _onMessageSent(
    SupportTimelineMessageSent event,
    Emitter<SupportTimelineState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty || state.sending) return;

    emit(state.copyWith(sending: true, sendError: ''));

    final response = await repo.sendMessage(text);
    if (response.errorText.isNotEmpty || response.data == null) {
      emit(state.copyWith(sending: false, sendError: response.errorText));
      return;
    }

    // HTTP success is upserted immediately rather than waiting on the socket
    // (§7/§14.2) - the socket may not even be connected, and either way this
    // is the same message, under the same key, so the echo that follows is a
    // no-op.
    final message = response.data!;
    _seenSocketMessageIds.add(message.id);
    _upsert(_itemFor(message));
    emit(state.copyWith(
      sending: false,
      status: SupportTimelineStatus.ready,
      items: _feed(),
    ));
  }

  void _onItemUpserted(
    _SupportTimelineItemUpserted event,
    Emitter<SupportTimelineState> emit,
  ) {
    _upsert(event.item);
    emit(state.copyWith(items: _feed()));
  }

  // ---- keyed store ----

  void _upsert(SupportTimelineItem item) {
    if (item.key.isEmpty) return;
    _byKey[item.key] = item;
  }

  void _upsertAll(Iterable<SupportTimelineItem> items) {
    for (final item in items) {
      _upsert(item);
    }
  }

  /// The store as the page renders it: oldest-first, for a top-to-bottom
  /// thread read. The API answers newest-first (§6.3) and older pages arrive
  /// after newer ones, so display order is derived here from `occurred_at`
  /// rather than from arrival order. Ties break on the key, which is ULID-
  /// suffixed and therefore itself time-ordered.
  List<SupportTimelineItem> _feed() {
    final items = _byKey.values.toList();
    items.sort((a, b) {
      final at = a.occurredAt;
      final bt = b.occurredAt;
      if (at == null || bt == null) {
        if (at != bt) return at == null ? -1 : 1;
      } else {
        final byTime = at.compareTo(bt);
        if (byTime != 0) return byTime;
      }
      return a.key.compareTo(b.key);
    });
    return items;
  }

  SupportTimelineItem _itemFor(SupportChatMessage message) {
    return SupportTimelineItem(
      key: 'message:${message.id}',
      type: SupportTimelineItemType.message,
      occurredAt: message.createdAt,
      message: message,
    );
  }

  // ---- socket ----

  void _retainReverb() {
    if (_reverbRetained) return;
    _reverbRetained = true;
    _reverb.connect();
    _reverbMessageSub ??= _reverb.supportMessageCreated.listen(_onReverbMessage);
    _reverbReviewSub ??= _reverb.routeReviewUpdated.listen(_onReverbReviewUpdated);
  }

  /// A `support.message.created` frame (§13.4). A plain message carries
  /// everything needed to render it, so it is upserted directly; a
  /// review-linked one may belong to a card this bloc has never loaded (e.g.
  /// support just pushed a brand new review), so that case reloads page 1
  /// instead of guessing. Cross-organization frames never reach here -
  /// [TollReverbService] drops them at the socket.
  void _onReverbMessage(Map<String, dynamic> data) {
    final raw = toMap(data['message']);
    final id = toStr(raw['id']);
    if (id.isEmpty) return;
    if (!_seenSocketMessageIds.add(id)) return;

    final message = SupportChatMessage.fromJson(raw);
    if (message.routeReviewId == null || message.routeReviewId!.isEmpty) {
      add(_SupportTimelineItemUpserted(_itemFor(message)));
    } else {
      add(const SupportTimelineRefreshed());
    }
  }

  /// A `mobile.route-review.updated` frame (§13.5) - signal only, per that
  /// section: reload page 1 rather than reading anything off the payload.
  void _onReverbReviewUpdated(Map<String, dynamic> data) {
    final eventId = toStr(data['event_id']);
    if (eventId.isEmpty || !_seenReviewEventIds.add(eventId)) return;
    add(const SupportTimelineRefreshed());
  }

  @override
  Future<void> close() {
    _reverbMessageSub?.cancel();
    _reverbReviewSub?.cancel();
    if (_reverbRetained) {
      _reverb.disconnect();
      _reverbRetained = false;
    }
    return super.close();
  }
}
