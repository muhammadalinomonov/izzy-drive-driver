import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/core/components/app_snack_bar.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/features/trips/data/model/route_support_model.dart';
import 'package:taxi_app/features/trips/data/model/support_chat_model.dart';
import 'package:taxi_app/features/trips/presentation/bloc/route_support/route_support_bloc.dart';
import 'package:taxi_app/features/trips/presentation/widgets/route_support_card.dart';
import 'package:taxi_app/features/trips/presentation/widgets/support_chat.dart';

/// Route review thread (docs/ui/8-2.png), opened from **Send request** on the
/// route overview screen by Premium drivers.
///
/// The route card the driver asked about is shown once, pinned above the
/// thread - it comes from [request], not from the API, since the real review
/// object carries no per-message card (docs/mobile-api.md §8.3's `messages`
/// are plain text). Below it, `POST /mobile/route-reviews` creates the review
/// on open and `POST /mobile/route-reviews/{id}/messages` posts follow-ups;
/// both are documented across docs/mobile-api.md §8.3 and
/// docs/mobile-fuel-api-websocket.md §4.1 - see `RouteSupportBloc`.
class RouteSupportPage extends StatefulWidget {
  const RouteSupportPage({super.key, required this.request});

  /// The route the conversation is about. Also the body the create call
  /// carries.
  final RouteSupportRequest request;

  @override
  State<RouteSupportPage> createState() => _RouteSupportPageState();
}

class _RouteSupportPageState extends State<RouteSupportPage> {
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// Message count the composer was cleared at - see
  /// `support_message_page.dart`'s identical guard for why this exists: a
  /// failed send must not lose what the driver typed.
  int _clearedAtMessageCount = 0;

  @override
  void initState() {
    super.initState();
    context.read<RouteSupportBloc>().add(const RouteSupportStarted());
  }

  @override
  void dispose() {
    _composer.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _onStateChanged(BuildContext context, RouteSupportState state) {
    if (state.messages.isNotEmpty) _scrollToEnd();
    if (state.sendError.isNotEmpty) {
      // The thread itself is still readable, so a failed send is a snack bar
      // rather than a page-level error.
      AppSnackBar.showError(context, state.sendError);
      return;
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
            p.sending != c.sending,
        listener: _onStateChanged,
        builder: (context, state) {
          return Column(
            children: [
              Expanded(child: _buildThread(state)),
              if (state.status == RouteSupportStatus.ready)
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
        return ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          // +1 for the pinned route card, which always leads the thread.
          itemCount: state.messages.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _RequestCardBubble(request: widget.request);
            }
            return _MessageBubble(message: state.messages[index - 1]);
          },
        );
    }
  }
}

/// The driver's opening context, pinned above the thread: the route they
/// asked about, matching docs/ui/8-2-1.png. Not a server message - see the
/// page-level doc comment.
class _RequestCardBubble extends StatelessWidget {
  const _RequestCardBubble({required this.request});

  final RouteSupportRequest request;

  @override
  Widget build(BuildContext context) {
    return SupportBubble(
      outgoing: true,
      wide: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'routeSupport.reviewRequestMessage'.tr(),
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
          RouteSupportCard(card: request.card),
        ],
      ),
    );
  }
}

/// One follow-up message - the driver's or support's. Plain text only: the
/// real conversation carries no per-message card or action (see the
/// page-level doc comment).
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
