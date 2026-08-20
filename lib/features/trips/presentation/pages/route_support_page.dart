import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/core/components/app_snack_bar.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/features/trips/data/model/route_support_model.dart';
import 'package:taxi_app/features/trips/data/model/support_chat_model.dart';
import 'package:taxi_app/features/trips/presentation/bloc/route_support/route_support_bloc.dart';
import 'package:taxi_app/features/trips/presentation/pages/driving_mode_page.dart';
import 'package:taxi_app/features/trips/presentation/widgets/route_support_card.dart';
import 'package:taxi_app/features/trips/presentation/widgets/support_chat.dart';
import 'package:taxi_app/routes/pages.dart';

/// Route review thread (docs/ui/8-2.png), opened from **Send request** on the
/// route overview screen by Premium drivers.
///
/// The screen is a view onto one route-review object, not onto a chat. Per
/// `docs/mobile-chat-route-fuel-drive.md`, a dispatcher's decision, an
/// alternative they suggest, a fuel stop they attach and whether the route may
/// be driven are all fields on that object read back over REST - none of them
/// arrive as message content. So the pinned card, the fuel stops and the Drive
/// button here all render from `state.review`, and the messages below are only
/// the conversation around it.
///
/// The review is re-read on a timer and whenever the app comes back to the
/// foreground. That stands in for the Reverb `mobile.route-review.updated`
/// event, which this app has no client for yet - the event is only ever a
/// signal to re-fetch anyway (§2.2), so polling reaches the same state, just
/// later. Wiring the socket up later replaces [_refreshInterval] and changes
/// nothing else on this screen.
class RouteSupportPage extends StatefulWidget {
  const RouteSupportPage({super.key, required this.request});

  /// The route the conversation is about. Also the body the create call
  /// carries, and the only source of the endpoint address labels - the route
  /// API returns coordinates and no address text (§7).
  final RouteSupportRequest request;

  @override
  State<RouteSupportPage> createState() => _RouteSupportPageState();
}

class _RouteSupportPageState extends State<RouteSupportPage>
    with WidgetsBindingObserver {
  /// Slow enough not to hammer an endpoint that mostly answers "nothing
  /// changed", quick enough that a dispatcher's approval doesn't feel lost.
  /// The driver is looking at this screen while they wait, so a resume
  /// refresh alone would not be enough.
  static const Duration _refreshInterval = Duration(seconds: 15);

  final TextEditingController _composer = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _refreshTimer;

  /// Message count the composer was cleared at - see
  /// `support_message_page.dart`'s identical guard for why this exists: a
  /// failed send must not lose what the driver typed.
  int _clearedAtMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<RouteSupportBloc>().add(const RouteSupportStarted());
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _composer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the background is exactly the case the contract calls
    // out for a REST catch-up (§7) - anything that changed while away has to
    // be re-read, since nothing was buffered for us.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    context.read<RouteSupportBloc>().add(const RouteSupportRefreshed());
  }

  /// Keeps the newest message in view. Posted to the end of the frame so the
  /// list has already been laid out with the message that triggered it.
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

  void _onSend() {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    context.read<RouteSupportBloc>().add(RouteSupportMessageSent(text));
  }

  void _onRetry() {
    context.read<RouteSupportBloc>().add(const RouteSupportStarted());
  }

  void _onConfirmFuel(String recommendationId) {
    context
        .read<RouteSupportBloc>()
        .add(RouteSupportFuelConfirmed(recommendationId));
  }

  void _onDrive() {
    context.read<RouteSupportBloc>().add(const RouteSupportDrivePressed());
  }

  void _onStateChanged(BuildContext context, RouteSupportState state) {
    if (state.messages.isNotEmpty) _scrollToEnd();

    final session = state.session;
    if (session != null && state.driveTick > 0) {
      // Same dead-end rule as the route overview: once guidance is running,
      // backing out of driving mode must not land on a review whose route is
      // already under way.
      context.pushReplacement(
        Pages.drivingMode,
        extra: DrivingModeArgs(
          session: session,
          destinationLabel: widget.request.destination.fieldLabel,
        ),
      );
      return;
    }

    // Failed mutations are snack bars, never page states - the thread stays
    // readable through all of them.
    for (final error in [
      state.sendError,
      state.confirmError,
      state.driveError,
    ]) {
      if (error.isNotEmpty) {
        AppSnackBar.showError(context, error);
        return;
      }
    }

    if (!state.sending &&
        state.messages.length > _clearedAtMessageCount &&
        _composer.text.trim().isNotEmpty) {
      _clearedAtMessageCount = state.messages.length;
      _composer.clear();
    }
  }

  // ── Placeholder actions - out of scope for this task ────────────────────

  void _onAttach() {}

  void _onVoice() {}

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
      body: BlocConsumer<RouteSupportBloc, RouteSupportState>(
        listenWhen: (p, c) =>
            p.messages.length != c.messages.length ||
            p.sendError != c.sendError ||
            p.confirmError != c.confirmError ||
            p.driveError != c.driveError ||
            p.driveTick != c.driveTick ||
            p.sending != c.sending,
        listener: _onStateChanged,
        builder: (context, state) {
          return Column(
            children: [
              Expanded(child: _buildThread(state)),
              if (state.status == RouteSupportStatus.ready)
                if (state.isClosed)
                  _ClosedNotice()
                else
                  SupportComposer(
                    controller: _composer,
                    onAttach: _onAttach,
                    onVoice: _onVoice,
                    onSend: _onSend,
                    enabled: !state.sending,
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThread(RouteSupportState state) {
    switch (state.status) {
      case RouteSupportStatus.initial:
      case RouteSupportStatus.loading:
        return const Center(child: CircularProgressIndicator.adaptive());
      case RouteSupportStatus.failure:
        return _ThreadMessage(
          text: state.errorMessage.isEmpty
              ? 'common.somethingWentWrong'.tr()
              : state.errorMessage,
          onRetry: _onRetry,
        );
      case RouteSupportStatus.ready:
        final items = _threadItems(state);
        return ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) => items[index],
        );
    }
  }

  /// The thread, in the order the driver reads it: what the review is about,
  /// the conversation, then whatever the review currently asks the driver to
  /// act on.
  List<Widget> _threadItems(RouteSupportState state) {
    final review = state.review;

    return [
      _RequestCardBubble(request: widget.request, review: review),
      for (final message in state.messages) _MessageBubble(message: message),
      if (review != null) ..._decisionItems(review),
      if (review != null) ..._fuelItems(review, state),
      if (review?.canStartDrive ?? false) SupportDriveButton(onTap: _onDrive),
    ];
  }

  /// The dispatcher's verdict text.
  ///
  /// Skipped when a message already says it: a decision normally arrives as
  /// both `decision_note` on the review and a support message (§4.3), and
  /// showing both would read as the dispatcher repeating themselves.
  List<Widget> _decisionItems(RouteReviewDetail review) {
    final note = review.decisionText;
    if (note.isEmpty) return const [];
    final alreadySaid = review.messages.any(
      (m) => !m.isDriver && m.message.trim() == note.trim(),
    );
    if (alreadySaid) return const [];
    return [
      SupportAgentBubble(
        sender: 'routeSupport.supportFallbackName'.tr(),
        body: note,
      ),
    ];
  }

  /// Fuel stops still waiting on the driver.
  ///
  /// Confirmed ones are deliberately absent: they already show inside the
  /// route card with a check, and there is nothing left to do about them.
  List<Widget> _fuelItems(RouteReviewDetail review, RouteSupportState state) {
    return [
      for (final recommendation in review.fuelRecommendations)
        if (!recommendation.confirmed)
          SupportBubble(
            outgoing: false,
            wide: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'routeSupport.fuelStopTitle'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: AppColor.black,
                  ),
                ),
                const SizedBox(height: 10),
                RouteFuelStopCard(
                  recommendation: recommendation,
                  confirming: state.confirmingRecommendationId ==
                      recommendation.id,
                  onConfirm: () => _onConfirmFuel(recommendation.id),
                ),
              ],
            ),
          ),
    ];
  }
}

/// The driver's opening context, pinned above the thread, matching
/// docs/ui/8-2-1.png.
///
/// The card follows the review once it has been read: on `pending` that is
/// still the route the driver asked about, but after a dispatcher suggests or
/// approves a different one it becomes theirs (§4.3). Until the first read
/// lands it falls back to the request the page was pushed with, so the driver
/// never waits on a spinner to see what they just sent.
class _RequestCardBubble extends StatelessWidget {
  const _RequestCardBubble({required this.request, required this.review});

  final RouteSupportRequest request;
  final RouteReviewDetail? review;

  @override
  Widget build(BuildContext context) {
    final review = this.review;
    final card = review == null
        ? request.card
        : review.cardFor(
            // Address labels are local state by necessity - see the page doc.
            originLabel: request.origin.fieldLabel,
            destinationLabel: request.destination.fieldLabel,
            perGallonNote: 'routeSupport.forGallon'.tr(),
          );

    // `request_note` is what the driver actually sent, if anything; the
    // default copy stands in when the review was opened without one.
    final note = review?.requestNote.isNotEmpty ?? false
        ? review!.requestNote
        : 'routeSupport.reviewRequestMessage'.tr();

    return SupportBubble(
      outgoing: true,
      wide: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            note,
            style: TextStyle(fontSize: 14, height: 1.35, color: AppColor.black),
          ),
          const SizedBox(height: 3),
          Text(
            'routeSupport.selectedRoute'.tr(args: [request.alternativeLabel]),
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: AppColor.black,
            ),
          ),
          const SizedBox(height: 10),
          RouteSupportCard(card: card),
          if (review != null) ...[
            const SizedBox(height: 8),
            _StatusChip(status: review.status),
          ],
        ],
      ),
    );
  }
}

/// Where the review stands, under the card it applies to.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final RouteReviewStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      RouteReviewStatus.pending => 'routeSupport.statusPending',
      RouteReviewStatus.approved => 'routeSupport.statusApproved',
      RouteReviewStatus.alternativeSuggested =>
        'routeSupport.statusAlternativeSuggested',
      RouteReviewStatus.declined => 'routeSupport.statusDeclined',
      RouteReviewStatus.cancelled => 'routeSupport.statusCancelled',
      // An unrecognised status says nothing rather than guessing wrong.
      RouteReviewStatus.unknown => '',
    };
    if (label.isEmpty) return const SizedBox.shrink();

    return Text(
      label.tr(),
      style: TextStyle(fontSize: 12, color: AppColor.grey),
    );
  }
}

/// One follow-up message - the driver's or support's. Plain text only: the
/// contract carries no per-message card or action (see the page doc comment).
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final SupportChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (!message.isDriver) {
      return SupportAgentBubble(
        sender: message.senderName.isEmpty
            ? 'routeSupport.supportFallbackName'.tr()
            : message.senderName,
        body: message.message,
      );
    }

    final timestamp = message.sentAtLabel;
    return SupportBubble(
      outgoing: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.message,
            style: TextStyle(fontSize: 14, height: 1.35, color: AppColor.black),
          ),
          if (timestamp.isNotEmpty) ...[
            const SizedBox(height: 4),
            SupportTimestamp(text: timestamp),
          ],
        ],
      ),
    );
  }
}

/// Replaces the composer on a declined or cancelled review: posting there
/// answers 409 MOBILE_ROUTE_REVIEW_CLOSED, so the field is removed rather
/// than left to fail on send.
class _ClosedNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Text(
        'routeSupport.closedNotice'.tr(),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: AppColor.grey),
      ),
    );
  }
}

/// Centred message filling the thread area - the load error with its retry.
class _ThreadMessage extends StatelessWidget {
  const _ThreadMessage({required this.text, this.onRetry});

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
