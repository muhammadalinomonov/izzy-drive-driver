import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/core/components/app_snack_bar.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/features/trips/data/model/support_chat_model.dart';
import 'package:taxi_app/features/trips/presentation/bloc/support_chat/support_chat_bloc.dart';
import 'package:taxi_app/features/trips/presentation/widgets/support_chat.dart';

/// Normal support conversation (docs/ui/11.png), opened from the floating
/// Support button on `trip_map_page.dart`, `route_overview_page.dart` and
/// `driving_mode_page.dart` - all three share this one page and one backend
/// conversation (docs/mobile-api.md §8.1/§8.2).
///
/// Deliberately separate from the route-review thread (`route_support_page.dart`):
/// this conversation carries no route/fuel-station context of its own - the
/// real API is plain text only - so, unlike the route-review page, there is
/// no per-message card to render, only driver/support bubbles.
class SupportMessagePage extends StatefulWidget {
  const SupportMessagePage({super.key});

  @override
  State<SupportMessagePage> createState() => _SupportMessagePageState();
}

class _SupportMessagePageState extends State<SupportMessagePage> {
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// Message count the composer was cleared at, so the "clear on success"
  /// listener (see [_onStateChanged]) fires exactly once per successful send
  /// instead of on every unrelated rebuild.
  int _clearedAtMessageCount = 0;

  @override
  void initState() {
    super.initState();
    context.read<SupportChatBloc>().add(const SupportChatStarted());
  }

  @override
  void dispose() {
    _composer.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _onSend() {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    // The field is only cleared once the send actually succeeds (see
    // _onStateChanged) - clearing it here would lose the driver's message on
    // a failed request, which the task explicitly calls out to avoid.
    context.read<SupportChatBloc>().add(SupportChatMessageSent(text));
  }

  void _onRetry() {
    context.read<SupportChatBloc>().add(const SupportChatStarted());
  }

  void _onStateChanged(BuildContext context, SupportChatState state) {
    if (state.messages.isNotEmpty) _scrollToEnd();
    if (state.sendError.isNotEmpty) {
      AppSnackBar.showError(context, state.sendError);
      return;
    }
    // A successful send grew the thread while nothing is in flight and no
    // error is pending - the one moment the composer should empty itself.
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
          onPressed: () => Navigator.of(context).maybePop(),
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
      body: BlocConsumer<SupportChatBloc, SupportChatState>(
        listenWhen: (p, c) =>
            p.messages.length != c.messages.length ||
            p.sendError != c.sendError ||
            p.sending != c.sending,
        listener: _onStateChanged,
        builder: (context, state) {
          return Column(
            children: [
              Expanded(child: _buildThread(state)),
              if (state.status != SupportChatStatus.restricted)
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

  Widget _buildThread(SupportChatState state) {
    switch (state.status) {
      case SupportChatStatus.initial:
      case SupportChatStatus.loading:
        return const Center(child: CircularProgressIndicator.adaptive());
      case SupportChatStatus.restricted:
        return _ThreadMessage(text: 'routeSupport.premiumOnly'.tr());
      case SupportChatStatus.failure:
        return _ThreadMessage(
          text: state.errorMessage.isEmpty
              ? 'common.somethingWentWrong'.tr()
              : state.errorMessage,
          onRetry: _onRetry,
        );
      case SupportChatStatus.ready:
        if (state.isEmpty) {
          return _ThreadMessage(text: 'routeSupport.empty'.tr());
        }
        return ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: state.messages.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) =>
              _MessageBubble(message: state.messages[index]),
        );
    }
  }
}

/// One message: a plain driver bubble or a support reply. Neither carries a
/// card - the real conversation is text-only (docs/mobile-api.md §8.1).
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

/// Centred message filling the thread area - the load error with its retry,
/// the restricted-entitlement notice, or an empty conversation.
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
