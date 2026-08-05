import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/core/components/app_snack_bar.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/features/trips/data/model/route_support_model.dart';
import 'package:taxi_app/features/trips/presentation/bloc/route_support/route_support_bloc.dart';
import 'package:taxi_app/features/trips/presentation/widgets/route_support_card.dart';
import 'package:taxi_app/features/trips/presentation/widgets/support_chat.dart';

/// Route review thread (docs/ui/8-2.png), opened from **Send request** on the
/// route overview screen by Premium drivers.
///
/// The driver's opening message quotes the route they picked - endpoints, fuel,
/// toll and distance - and support answers, sometimes with a different route
/// to take instead.
///
/// **No backend yet.** The thread comes from `RouteSupportRepo`, which is
/// currently served by a placeholder data source; the chat is fully live
/// against that mock, so only the data source changes when the API lands. The
/// Drive action on a suggested route is still a placeholder callback: there is
/// no real alternative behind a mocked suggestion to start navigation for.
class RouteSupportPage extends StatefulWidget {
  const RouteSupportPage({super.key, required this.request});

  /// The route the conversation is about. Also the body the future `POST`
  /// will carry.
  final RouteSupportRequest request;

  @override
  State<RouteSupportPage> createState() => _RouteSupportPageState();
}

class _RouteSupportPageState extends State<RouteSupportPage> {
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
    _composer.clear();
  }

  void _onRetry() {
    context.read<RouteSupportBloc>().add(const RouteSupportStarted());
  }

  // ── Placeholder actions, ready for backend integration ──────────────────

  void _onAttach() {}

  void _onVoice() {}

  void _onDrive() {}

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
            p.messages.length != c.messages.length || p.sendError != c.sendError,
        listener: (context, state) {
          if (state.messages.isNotEmpty) _scrollToEnd();
          // The thread itself is still readable, so a failed send is a snack
          // bar rather than a page-level error.
          if (state.sendError.isNotEmpty) {
            AppSnackBar.showError(context, state.sendError);
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Expanded(child: _buildThread(state)),
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
        if (state.isEmpty) {
          return _ThreadMessage(text: 'routeSupport.empty'.tr());
        }
        return ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: state.messages.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _MessageBubble(
              message: state.messages[index],
              onDrive: _onDrive,
            );
          },
        );
    }
  }
}

/// One message: the driver's request or a support reply, with whatever route
/// card and action came attached.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.onDrive});

  final RouteSupportMessage message;
  final VoidCallback onDrive;

  @override
  Widget build(BuildContext context) {
    final card = message.card;

    if (!message.isDriver) {
      return SupportAgentBubble(
        sender: message.senderName,
        body: message.body,
        highlight: message.highlight.isEmpty ? null : message.highlight,
        attachment: card == null ? null : RouteSupportCard(card: card),
        action: message.showDriveAction
            ? SupportDriveButton(onTap: onDrive)
            : null,
      );
    }

    final timestamp = message.sentAtLabel;
    return SupportBubble(
      outgoing: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.body.isNotEmpty)
            Text(
              message.body,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColor.black,
              ),
            ),
          // "Selected Route: Recommended" - which alternative the driver is
          // asking about, emphasised under the question.
          if (message.highlight.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              message.highlight,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: AppColor.black,
              ),
            ),
          ],
          if (card != null) ...[
            const SizedBox(height: 12),
            RouteSupportCard(card: card),
          ],
          if (timestamp.isNotEmpty) ...[
            const SizedBox(height: 6),
            SupportTimestamp(text: timestamp),
          ],
        ],
      ),
    );
  }
}

/// Centred message filling the thread area - the load error with its retry, or
/// a conversation that has not started yet.
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
