part of 'support_timeline_bloc.dart';

abstract class SupportTimelineEvent extends Equatable {
  const SupportTimelineEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the feed. Also the retry.
class SupportTimelineStarted extends SupportTimelineEvent {
  const SupportTimelineStarted();
}

/// Reconciles page 1 in place, merging into the keyed store rather than
/// replacing it. Fired by `SupportReconciler` (resume, socket resubscribe,
/// pull-to-refresh, watchdog) and internally whenever a socket signal needs
/// more than the frame itself carries - see the bloc's class doc.
class SupportTimelineRefreshed extends SupportTimelineEvent {
  const SupportTimelineRefreshed();
}

/// Scrolled back past the oldest item held - pull in the next page of
/// history (§6 pagination counts messages and cards together).
class SupportTimelineOlderRequested extends SupportTimelineEvent {
  const SupportTimelineOlderRequested();
}

/// Driver posted from the composer - always a plain message
/// (`POST mobile/support-chat/messages`), never linked to a review; replying
/// within a specific review's own thread happens on `route_support_page.dart`.
class SupportTimelineMessageSent extends SupportTimelineEvent {
  final String text;

  const SupportTimelineMessageSent(this.text);

  @override
  List<Object?> get props => [text];
}

/// A plain socket message arrived with everything needed to render it.
/// Private - only the bloc's own socket listener dispatches it.
class _SupportTimelineItemUpserted extends SupportTimelineEvent {
  final SupportTimelineItem item;

  const _SupportTimelineItemUpserted(this.item);

  @override
  List<Object?> get props => [item];
}
