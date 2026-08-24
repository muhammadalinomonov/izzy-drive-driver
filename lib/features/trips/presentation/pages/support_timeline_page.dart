import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/core/components/app_snack_bar.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/core/services/support_reconciler.dart';
import 'package:taxi_app/features/trips/data/model/route_support_model.dart';
import 'package:taxi_app/features/trips/data/model/support_timeline_model.dart';
import 'package:taxi_app/features/trips/presentation/bloc/support_timeline/support_timeline_bloc.dart';
import 'package:taxi_app/features/trips/presentation/widgets/route_support_card.dart';
import 'package:taxi_app/features/trips/presentation/widgets/support_chat.dart';
import 'package:taxi_app/routes/pages.dart';

/// The driver's single support screen (docs/ui/10.png, docs/ui/11.png,
/// docs/ui/8-2.png) - a merged feed of plain messages and route-review cards,
/// newest server-side write reflected the moment `view=timeline` says so
/// (docs/mobile-chat-complete-api-websocket.md §6). Replaces the old split
/// between a plain-message-only page and a separate per-review page: every
/// "Support Message" and "Send request" entry point in the app opens here.
///
/// A route-review card is a summary, not the whole interaction - tapping one
/// opens `route_support_page.dart` for that review's own thread (replying,
/// confirming a fuel stop, cancelling, Drive). This page only owns the merged
/// feed and the plain-message composer.
///
/// Reload triggers are §14.4's, owned by [SupportReconciler]: socket
/// resubscribe, app resume, pull-to-refresh, and a watchdog that only runs
/// while the socket is down or a review is still pending. Scrolling to the
/// top pulls older history a page at a time.
class SupportTimelinePage extends StatefulWidget {
  const SupportTimelinePage({super.key});

  @override
  State<SupportTimelinePage> createState() => _SupportTimelinePageState();
}

class _SupportTimelinePageState extends State<SupportTimelinePage> {
  /// Distance from the top of the feed at which the next page is requested -
  /// far enough ahead that history is usually there before the driver
  /// reaches the end of what's loaded.
  static const double _loadOlderThreshold = 200;

  final TextEditingController _composer = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final SupportReconciler _reconciler;

  /// Item count the composer was cleared at - see `route_support_page.dart`'s
  /// identical guard for why this exists: a failed send must not lose what
  /// the driver typed.
  int _clearedAtItemCount = 0;

  /// Distance from the bottom of the feed captured when an older page was
  /// requested. Prepending shifts everything down, so the viewport is pinned
  /// relative to the bottom instead of the top - otherwise the driver's
  /// reading position jumps by a whole page.
  double? _anchorFromBottom;

  @override
  void initState() {
    super.initState();
    context.read<SupportTimelineBloc>().add(const SupportTimelineStarted());
    _scrollController.addListener(_onScroll);
    _reconciler = SupportReconciler(
      onReconcile: _refresh,
      // The merged feed has no single "pending" subject - a plain message
      // thread is never settled, so while push is live the watchdog stays
      // armed for it.
      isPending: () => true,
    )..start();
  }

  @override
  void dispose() {
    _reconciler.stop();
    _scrollController.removeListener(_onScroll);
    _composer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    context.read<SupportTimelineBloc>().add(const SupportTimelineRefreshed());
  }

  /// Pull-to-refresh - §14.4's manual reconcile trigger. Returns as soon as
  /// the request is dispatched: the reload is silent on failure, so there is
  /// no outcome for the indicator to wait on.
  Future<void> _onPullToRefresh() async {
    _reconciler.manual();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels > _loadOlderThreshold) return;

    final state = context.read<SupportTimelineBloc>().state;
    if (state.loadingMore || !state.hasMore) return;

    _anchorFromBottom =
        _scrollController.position.maxScrollExtent - _scrollController.position.pixels;
    context
        .read<SupportTimelineBloc>()
        .add(const SupportTimelineOlderRequested());
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  /// Puts the viewport back where it was relative to the newest item, after
  /// an older page has been prepended.
  void _restoreAnchor() {
    final anchor = _anchorFromBottom;
    _anchorFromBottom = null;
    if (anchor == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(
        (_scrollController.position.maxScrollExtent - anchor)
            .clamp(0.0, _scrollController.position.maxScrollExtent),
      );
    });
  }

  void _onSend() {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    context.read<SupportTimelineBloc>().add(SupportTimelineMessageSent(text));
  }

  void _onRetry() {
    context.read<SupportTimelineBloc>().add(const SupportTimelineStarted());
  }

  /// A review card is a summary; the full thread (reply, fuel confirm,
  /// cancel, Drive) lives on `route_support_page.dart`.
  void _onOpenReview(String reviewId) {
    context.push(Pages.routeSupport, extra: RouteSupportPageArgs.open(reviewId));
  }

  void _onStateChanged(BuildContext context, SupportTimelineState state) {
    // An older page must not drag the feed to the bottom - neither when the
    // request starts (the spinner is prepended) nor when it lands. The driver
    // is reading history, not waiting on the newest message.
    if (_anchorFromBottom != null) {
      if (!state.loadingMore) _restoreAnchor();
    } else if (state.items.isNotEmpty) {
      _scrollToEnd();
    }

    if (state.sendError.isNotEmpty) {
      AppSnackBar.showError(context, state.sendError);
      return;
    }

    if (!state.sending &&
        state.items.length > _clearedAtItemCount &&
        _composer.text.trim().isNotEmpty) {
      _clearedAtItemCount = state.items.length;
      _composer.clear();
    }
  }

  /// The composer's paperclip and mic. The backend has no attachment, image
  /// or voice support at all
  /// (docs/mobile-chat-complete-api-websocket.md §15.2), which says mobile
  /// must either hide these or say "coming soon" - the Figma keeps both icons
  /// in the input, so they stay visible and say so when tapped rather than
  /// silently doing nothing.
  void _onUnsupportedAttachment() {
    AppSnackBar.showWarning(context, 'routeSupport.comingSoon'.tr());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        backgroundColor: AppColor.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColor.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'routeSupport.title'.tr(),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColor.black,
          ),
        ),
      ),
      body: BlocConsumer<SupportTimelineBloc, SupportTimelineState>(
        listenWhen: (p, c) =>
            p.items.length != c.items.length ||
            p.sendError != c.sendError ||
            p.sending != c.sending ||
            p.loadingMore != c.loadingMore,
        listener: _onStateChanged,
        builder: (context, state) {
          return Column(
            children: [
              Expanded(child: _buildFeed(state)),
              if (state.status == SupportTimelineStatus.ready)
                SupportComposer(
                  controller: _composer,
                  onAttach: _onUnsupportedAttachment,
                  onVoice: _onUnsupportedAttachment,
                  onSend: _onSend,
                  enabled: !state.sending,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeed(SupportTimelineState state) {
    switch (state.status) {
      case SupportTimelineStatus.initial:
      case SupportTimelineStatus.loading:
        return const Center(child: CircularProgressIndicator.adaptive());
      case SupportTimelineStatus.restricted:
        return _FeedMessage(text: 'routeSupport.premiumOnly'.tr());
      case SupportTimelineStatus.failure:
        return _FeedMessage(
          text: state.errorMessage.isEmpty
              ? 'common.somethingWentWrong'.tr()
              : state.errorMessage,
          onRetry: _onRetry,
        );
      case SupportTimelineStatus.ready:
        if (state.isEmpty) {
          // Still pull-to-refreshable: an empty feed is exactly where a
          // driver waiting on support's first reply will tug.
          return RefreshIndicator(
            onRefresh: _onPullToRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.5,
                  child: _FeedMessage(text: 'routeSupport.empty'.tr()),
                ),
              ],
            ),
          );
        }
        // One leading slot for the older-page spinner, so prepending doesn't
        // reshuffle item indices mid-scroll.
        final leading = state.loadingMore ? 1 : 0;
        return RefreshIndicator(
          onRefresh: _onPullToRefresh,
          child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: state.items.length + leading,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (leading == 1 && index == 0) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    ),
                  ),
                );
              }
              return _FeedItem(
                item: state.items[index - leading],
                onOpenReview: _onOpenReview,
              );
            },
          ),
        );
    }
  }
}

/// One row in the feed - a plain message bubble, or a compact route-review
/// card. [SupportTimelineItemType.unknown] never reaches here:
/// `SupportTimelinePage.fromJson` drops it on the way in.
class _FeedItem extends StatelessWidget {
  const _FeedItem({required this.item, required this.onOpenReview});

  final SupportTimelineItem item;
  final void Function(String reviewId) onOpenReview;

  @override
  Widget build(BuildContext context) {
    final message = item.message;
    if (message != null) return SupportMessageBubble(message: message);

    final card = item.routeReviewCard;
    if (card != null) {
      return _RouteReviewCardBubble(
        card: card,
        onTap: () => onOpenReview(card.id),
      );
    }

    return const SizedBox.shrink();
  }
}

/// The compact route-review card, matching docs/ui/8-2-1.png but without the
/// opening note or "Selected Route" line - the timeline deliberately doesn't
/// repeat `request_note`/`decision_note` on the card
/// (docs/mobile-chat-complete-api-websocket.md §6.3); that text lives in the
/// real `message` items sitting next to it in the feed. Tapping anywhere on
/// it - including the `Drive` pill - opens the full thread; starting a
/// navigation session is `route_support_page.dart`'s job, not this feed's.
class _RouteReviewCardBubble extends StatelessWidget {
  const _RouteReviewCardBubble({required this.card, required this.onTap});

  final RouteReviewCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final routeCard = card.cardFor(
      originLabel: card.origin?.shortLabel ?? '',
      destinationLabel: card.destination?.shortLabel ?? '',
      perGallonNote: 'routeSupport.forGallon'.tr(),
    );

    return GestureDetector(
      onTap: onTap,
      child: SupportBubble(
        // A review support pushed unprompted reads as their card, not the
        // driver's own.
        outgoing: card.initiator != 'support',
        wide: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RouteSupportCard(card: routeCard),
            const SizedBox(height: 8),
            RouteReviewStatusChip(status: card.status),
            if (card.canStartDrive) ...[
              const SizedBox(height: 10),
              SupportDriveButton(onTap: onTap),
            ],
          ],
        ),
      ),
    );
  }
}

/// Centred message filling the feed area - loading error with retry, the
/// Premium gate, or an empty conversation.
class _FeedMessage extends StatelessWidget {
  const _FeedMessage({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColor.grey),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onRetry,
                child: Text('common.retry'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
