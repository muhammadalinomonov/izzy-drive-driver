import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/core/components/app_snack_bar.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/core/services/support_reconciler.dart';
import 'package:taxi_app/features/trips/data/model/route_support_model.dart';
import 'package:taxi_app/features/trips/presentation/bloc/route_support/route_support_bloc.dart';
import 'package:taxi_app/features/trips/presentation/pages/driving_mode_page.dart';
import 'package:taxi_app/features/trips/presentation/widgets/route_support_card.dart';
import 'package:taxi_app/features/trips/presentation/widgets/support_chat.dart';
import 'package:taxi_app/routes/pages.dart';

/// Route review thread (docs/ui/8-2.png), opened either from **Send request**
/// on the route overview screen (creates a new review) or by tapping a review
/// card in the unified support timeline (`support_timeline_page.dart`, opens
/// an existing one) - see [RouteSupportPageArgs].
///
/// The screen is a view onto one route-review object, not onto a chat. Per
/// `docs/mobile-chat-complete-api-websocket.md`, a dispatcher's decision, an
/// alternative they suggest, a fuel stop they attach and whether the route may
/// be driven are all fields on that object read back over REST - none of them
/// arrive as message content. So the pinned card, the fuel stops and the Drive
/// button here all render from `state.review`, and the messages below are only
/// the conversation around it.
///
/// The review is re-read on §14.4's reconcile triggers, owned by
/// [SupportReconciler]: socket resubscribe, app resume, and a watchdog that
/// only keeps ticking while the review is still pending - or, while the
/// socket is down, a plain poll, since REST is then the only way a
/// dispatcher's decision can reach a driver sitting on this screen.
class RouteSupportPage extends StatefulWidget {
  const RouteSupportPage({super.key, required this.args});

  /// How this page was opened - see [RouteSupportPageArgs]. Also the only
  /// source of the endpoint address labels when creating a review: the route
  /// API returns coordinates and no address text (§7).
  final RouteSupportPageArgs args;

  @override
  State<RouteSupportPage> createState() => _RouteSupportPageState();
}

class _RouteSupportPageState extends State<RouteSupportPage> {
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final SupportReconciler _reconciler;

  /// Message count the composer was cleared at - see
  /// `support_message_page.dart`'s identical guard for why this exists: a
  /// failed send must not lose what the driver typed.
  int _clearedAtMessageCount = 0;

  @override
  void initState() {
    super.initState();
    context.read<RouteSupportBloc>().add(const RouteSupportStarted());
    _reconciler = SupportReconciler(
      onReconcile: _refresh,
      // Once the review is settled - approved, declined, cancelled - nothing
      // else is coming for it over REST either, so the watchdog stands down
      // and the socket alone covers any late change.
      isPending: () => !context.read<RouteSupportBloc>().state.isClosed,
    )..start();
  }

  @override
  void dispose() {
    _reconciler.stop();
    _composer.dispose();
    _scrollController.dispose();
    super.dispose();
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

  /// Cancelling withdraws a still-`pending` request server-side and there is
  /// no undo, so it is confirmed first - same reasoning as
  /// `driving_mode_page.dart`'s identical dialog for ending a trip.
  Future<void> _onCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColor.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'routeSupport.cancelTitle'.tr(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColor.black,
          ),
        ),
        content: Text(
          'routeSupport.cancelMessage'.tr(),
          style: TextStyle(fontSize: 13, color: AppColor.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'routeSupport.cancelDismiss'.tr(),
              style: TextStyle(color: AppColor.black, fontSize: 13),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColor.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'routeSupport.cancelConfirm'.tr(),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    context.read<RouteSupportBloc>().add(const RouteSupportCancelled());
  }

  void _onStateChanged(BuildContext context, RouteSupportState state) {
    if (state.messages.isNotEmpty) _scrollToEnd();

    final session = state.session;
    if (session != null && state.driveTick > 0) {
      // Same dead-end rule as the route overview: once guidance is running,
      // backing out of driving mode must not land on a review whose route is
      // already under way. Falls back to the review's own coordinates when
      // this page was opened on an existing review rather than created from
      // a local request.
      context.pushReplacement(
        Pages.drivingMode,
        extra: DrivingModeArgs(
          session: session,
          destinationLabel: widget.args.request?.destination.fieldLabel ??
              state.review?.destination?.shortLabel ??
              '',
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
      state.cancelError,
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
      body: BlocConsumer<RouteSupportBloc, RouteSupportState>(
        listenWhen: (p, c) =>
            p.messages.length != c.messages.length ||
            p.sendError != c.sendError ||
            p.confirmError != c.confirmError ||
            p.driveError != c.driveError ||
            p.driveTick != c.driveTick ||
            p.sending != c.sending ||
            p.cancelError != c.cancelError,
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
      case RouteSupportStatus.notAvailable:
        // No retry - the entitlement isn't a transient failure, it needs the
        // driver's plan/TollTally state to change, not another request.
        return _ThreadMessage(text: 'routeSupport.notAvailable'.tr());
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
      _RequestCardBubble(request: widget.args.request, review: review),
      for (final message in state.messages) SupportMessageBubble(message: message),
      if (review != null) ..._decisionItems(review),
      if (review != null) ..._fuelItems(review, state),
      if (review?.canStartDrive ?? false) SupportDriveButton(onTap: _onDrive),
      if (state.canCancel) _CancelRequestRow(onTap: _onCancel, busy: state.cancelling),
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
/// approves a different one it becomes theirs (§4.3). [request] is only
/// non-null in create mode (`RouteSupportPageArgs.create`) - a review opened
/// from the timeline (`RouteSupportPageArgs.open`) has no local request to
/// fall back to, so both the endpoint labels and the note fall back to
/// whatever the review itself carries, never to invented text.
class _RequestCardBubble extends StatelessWidget {
  const _RequestCardBubble({required this.request, required this.review});

  final RouteSupportRequest? request;
  final RouteReviewDetail? review;

  @override
  Widget build(BuildContext context) {
    final review = this.review;
    final request = this.request;

    // The route API never returns address text (§7); a locally-known label
    // wins, a coordinate string is the honest fallback when there is none.
    final originLabel =
        request?.origin.fieldLabel ?? review?.origin?.shortLabel ?? '';
    final destinationLabel = request?.destination.fieldLabel ??
        review?.destination?.shortLabel ??
        '';

    final card = review == null
        ? request?.card
        : review.cardFor(
            originLabel: originLabel,
            destinationLabel: destinationLabel,
            perGallonNote: 'routeSupport.forGallon'.tr(),
          );
    if (card == null) return const SizedBox.shrink();

    // `request_note` is what the driver actually sent, if anything. The
    // generic fallback only applies in create mode - showing it on a review
    // this driver never wrote anything on (e.g. `initiator: support`) would
    // be a fabricated quote.
    final note = review?.requestNote.isNotEmpty ?? false
        ? review!.requestNote
        : (request != null ? 'routeSupport.reviewRequestMessage'.tr() : '');

    return SupportBubble(
      // A review support pushed unprompted reads as their message, not the
      // driver's own - everything else here (driver-initiated, or not yet
      // read back) stays on the driver's side.
      outgoing: review?.initiator != 'support',
      wide: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (note.isNotEmpty) ...[
            Text(
              note,
              style:
                  TextStyle(fontSize: 14, height: 1.35, color: AppColor.black),
            ),
            const SizedBox(height: 3),
          ],
          if (request != null) ...[
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
          ],
          RouteSupportCard(card: card),
          if (review != null) ...[
            const SizedBox(height: 8),
            RouteReviewStatusChip(status: review.status),
          ],
        ],
      ),
    );
  }
}

/// The withdraw-request affordance, shown only while the review is still
/// `pending` (`RouteSupportState.canCancel`) - once support has acted,
/// cancelling would answer 409 MOBILE_ROUTE_REVIEW_CLOSED.
class _CancelRequestRow extends StatelessWidget {
  const _CancelRequestRow({required this.onTap, required this.busy});

  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: busy ? null : onTap,
        child: busy
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator.adaptive(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColor.red),
                ),
              )
            : Text(
                'routeSupport.cancelRequest'.tr(),
                style: TextStyle(color: AppColor.red, fontSize: 13),
              ),
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
