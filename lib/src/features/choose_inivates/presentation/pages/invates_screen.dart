import 'package:easy_localization/easy_localization.dart';
// ignore: unnecessary_import — material.dart does NOT re-export
// CupertinoSliverRefreshControl/RefreshIndicatorMode.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import 'package:taxi_app/src/core/services/websocket_service.dart';
import 'package:taxi_app/src/core/utils/adaptive_poller.dart';
import 'package:taxi_app/src/features/cancel_reasons/presentation/widgets/cancel_reason_sheet.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/common_image.dart';
import 'package:taxi_app/src/features/choose_inivates/presentation/widgets/profile_order_model_sheet.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/common_scalel_animation.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/bloc/orders_bloc.dart';
import 'package:taxi_app/src/routes/pages.dart';

import '../../data/model/active_order.dart';
import '../bloc/inivites_bloc.dart';

// Figma design tokens (Quadrix Ai design system).
const Color _kBg = Color(0xFFEFF3F6); // Gray/BG - page background
const Color _kBorder = Color(0xFFE3E8EB);
const Color _kSubtitle = Color(0xFF6B7073);
const Color _kCaption = Color(0xFF43484B);
const Color _kDivider = Color(0xFFECF0F3);
const Color _kInputBg = Color(0xFFEFF3F6);
const Color _kPrimary = Color(0xFF0866FF);
const Color _kMuted = Color(0xFF93989B);
const Color _kCancelBg = Color(0x19FC0000);
const Color _kCancelText = Color(0xFFFC0000);
const Color _kPositiveBg = Color(0x1404A516);
const Color _kPositiveText = Color(0xFF009011);
const Color _kNegativeBg = Color(0x14FF1212);
const Color _kNegativeText = Color(0xFFFF1212);

class InvatesScreen extends StatefulWidget {
  const InvatesScreen({super.key});

  @override
  State<InvatesScreen> createState() => _InvatesScreenState();
}

class _InvatesScreenState extends State<InvatesScreen> with WidgetsBindingObserver {
  static const _resumeDebounce = Duration(seconds: 10);

  DateTime? _lastResumeRefresh;
  late final AdaptivePoller _poller;

  late InivitesBloc inivitesBloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    inivitesBloc = context.read<InivitesBloc>()..add(FetchActiveOrderEvent());
    // Adaptiv polling: WS ulangan paytda har 30s, uzilgan paytda har 10s.
    // Tick'larda setState - time-ago labellarini yangilab turish uchun.
    _poller = AdaptivePoller(
      ws: serviceLocator<WebSocketService>(),
      onPoll: () {
        if (!mounted) return;
        context.read<InivitesBloc>().add(FetchActiveOrderEvent());
      },
      onTick: () {
        if (mounted) setState(() {});
      },
    )..start();
  }

  @override
  void dispose() {
    _poller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    inivitesBloc.add(DisconnectFromWebSocketEvent());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final now = DateTime.now();
    if (_lastResumeRefresh != null && now.difference(_lastResumeRefresh!) < _resumeDebounce) {
      return;
    }
    _lastResumeRefresh = now;
    // iOS often suspends the WS during background without firing onDone, so
    // the cached `_isConnected` can be a lie - force a fresh socket.
    serviceLocator<WebSocketService>().reconnect();
    if (!mounted) return;
    context.read<InivitesBloc>().add(FetchActiveOrderEvent());
  }

  Future<void> _onRefresh() async {
    context.read<InivitesBloc>().add(FetchActiveOrderEvent());
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _backToMain() {
    context.read<InivitesBloc>().add(DisconnectFromWebSocketEvent());
    context.go(Pages.main);
  }

  Future<void> _confirmCancel() async {
    final bloc = context.read<InivitesBloc>();
    final choice = await showCancelReasonSheet(context);
    if (choice == null) return;
    bloc.add(CancelActiveOrderEvent(
      reasonId: choice.reasonId,
      reasonText: choice.customText,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _backToMain();
        },
        child: Scaffold(
          backgroundColor: _kBg,
          body: Column(
            children: [
              // Status bar + TopBar - fixed white area, doesn't scroll on refresh.
              Container(
                color: Colors.white,
                child: SafeArea(
                  bottom: false,
                  child: _TopBar(onBack: _backToMain, onCancel: _confirmCancel),
                ),
              ),
              Expanded(
                child: BlocConsumer<InivitesBloc, InivitesState>(
                  listenWhen: (prev, curr) =>
                      curr is InivitesCancelled || curr is InivitesError,
                  listener: (context, state) {
                    if (state is InivitesCancelled) {
                      // Cancel API faqat shu bloc orqali chaqiriladi - OrdersBloc
                      // shu paytda eski "active" state'da qotirib qoladi. WS dan
                      // `order-cancelled` event har doim yetib bormasligi mumkin
                      // (broadcast vs targeted), shu sababli aniq signal yuboramiz.
                      context.read<OrdersBloc>().add(ResetCurrentOrderEvent());
                      context.go(Pages.main);
                      return;
                    }
                    if (state is InivitesError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.message)),
                      );
                    }
                  },
                  // Pull-to-refresh paytida bloc Loading → Loaded chiqaradi.
                  // Loaded UI'ni Loading bilan almashtirmaymiz - refresh
                  // indicator o'zi yetarli signal beradi.
                  buildWhen: (prev, curr) {
                    if (curr is InivitesLoading && prev is InivitesLoaded) {
                      return false;
                    }
                    return true;
                  },
                  builder: (context, state) {
                    if (state is InivitesLoaded) {
                      return _Loaded(
                        orderResponse: state.orderResponse,
                        onRefresh: _onRefresh,
                      );
                    } else if (state is InivitesError) {
                      return _ErrorView(message: state.message);
                    } else {
                      // Initial + Loading (first load): skeleton placeholder.
                      return const _LoadingSkeleton();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Loaded extends StatefulWidget {
  const _Loaded({required this.orderResponse, required this.onRefresh});

  final OrderResponse orderResponse;
  final Future<void> Function() onRefresh;

  @override
  State<_Loaded> createState() => _LoadedState();
}

class _LoadedState extends State<_Loaded> {
  @override
  Widget build(BuildContext context) {
    final order = widget.orderResponse.order;
    final offers = widget.orderResponse.data;
    final hasOffers = offers.isNotEmpty;

    return NotificationListener<OverscrollIndicatorNotification>(
      // Android'dagi glow indikatorni o'chiramiz — CupertinoSliverRefreshControl
      // o'zining spinneri va content-shift animatsiyasini ko'rsatadi.
      onNotification: (n) {
        n.disallowIndicator();
        return true;
      },
      child: CustomScrollView(
        // BouncingScrollPhysics — pull qilganda content vizual ravishda pastga
        // cho'ziladi, Cupertino sliver shu cho'zilish balandligida joy ochib
        // spinner ko'rsatadi. AlwaysScrollableScrollPhysics — list bo'sh
        // (offers yo'q) bo'lsa ham scroll bilan refresh qilinadi.
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: widget.onRefresh,
            // Default thresholds his qulay — minimum joy 60, refresh trigger 100.
            builder: _buildRefreshIndicator,
          ),
          SliverToBoxAdapter(
            child: _HeaderCard(order: order, hasOffers: hasOffers),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          // Offerlar bo'lmasa — viewport'ning qolgan qismini to'ldirib bo'sh
          // holatni markazda ko'rsatamiz. Offerlar bo'lsa tabiiy balandlikda
          // ro'yxat shaklida (ko'p bo'lsa scroll qilinadi).
          if (hasOffers)
            SliverToBoxAdapter(
              child: _OffersCard(
                offers: offers,
                orderCreatedAt: order.createdAt,
                orderPrice: order.totalPrice,
              ),
            )
          else
            SliverFillRemaining(
              hasScrollBody: false,
              child: _OffersCard(
                offers: offers,
                orderCreatedAt: order.createdAt,
                orderPrice: order.totalPrice,
              ),
            ),
        ],
      ),
    );
  }

  /// Custom refresh indicator — Cupertino default spinneri o'rniga loyiha
  /// rangiga mos circular progress ko'rsatamiz. Pull masofasiga qarab faded
  /// (drag) yoki spinning (refreshing) holatda chiqadi.
  ///
  /// Builder qaytargan widget sliver'ning butun pulled-extent area'sini
  /// to'ldiradi — shu sababli ColoredBox(white) bilan o'rasak, pull qilganda
  /// ochilgan joy Scaffold'ning gray foni o'rniga oq bo'lib chiqadi (HeaderCard
  /// bilan vizual ravishda bog'lanadi).
  Widget _buildRefreshIndicator(
    BuildContext context,
    RefreshIndicatorMode refreshState,
    double pulledExtent,
    double refreshTriggerPullDistance,
    double refreshIndicatorExtent,
  ) {
    final progress =
        (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);
    final isSpinning = refreshState == RefreshIndicatorMode.refresh ||
        refreshState == RefreshIndicatorMode.armed;
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: isSpinning
                    ? const CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(_kPrimary),
                      )
                    : CircularProgressIndicator(
                        strokeWidth: 2.4,
                        value: progress,
                        valueColor:
                            const AlwaysStoppedAnimation(_kPrimary),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, required this.onCancel});

  final VoidCallback onBack;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          CommonScaleAnimation(
            onTap: onBack,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: SvgPicture.asset(AppIcons.back, width: 20, height: 20),
              ),
            ),
          ),
          const Spacer(),
          CommonScaleAnimation(
            onTap: onCancel,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _kCancelBg,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                'Cancel'.tr(),
                style: const TextStyle(
                  color: _kCancelText,
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.order, required this.hasOffers});

  final Order order;
  final bool hasOffers;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatTimeAgo(order.createdAt),
            style: const TextStyle(
              color: _kCaption,
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              letterSpacing: -0.30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            order.orderTitle,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              letterSpacing: -0.30,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SvgPicture.asset(AppIcons.location, width: 18, height: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.currentAddress.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kSubtitle,
                    fontSize: 15,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.30,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _OfferAmountBox(order: order, canAdjust: !hasOffers),
        ],
      ),
    );
  }
}

class _OfferAmountBox extends StatefulWidget {
  const _OfferAmountBox({required this.order, required this.canAdjust});

  final Order order;
  final bool canAdjust;

  @override
  State<_OfferAmountBox> createState() => _OfferAmountBoxState();
}

class _OfferAmountBoxState extends State<_OfferAmountBox> {
  static const TextStyle _priceStyle = TextStyle(
    color: Colors.black,
    fontSize: 15,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: -0.30,
  );

  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.order.totalPrice.toStringAsFixed(0),
    );
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _OfferAmountBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Narx tashqaridan o'zgargan bo'lsa (+/- tugma yoki WS update) - controllerni
    // sinxronlaymiz. User shu paytda TextFieldda tahrirlamayotgan bo'lsa.
    if (!_focusNode.hasFocus &&
        widget.order.totalPrice != oldWidget.order.totalPrice) {
      final newText = widget.order.totalPrice.toStringAsFixed(0);
      if (_controller.text != newText) {
        _controller.text = newText;
      }
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _submit();
  }

  void _submit() {
    final parsed = double.tryParse(_controller.text.trim());
    if (parsed == null || parsed < 1) {
      _controller.text = widget.order.totalPrice.toStringAsFixed(0);
      return;
    }
    if (parsed == widget.order.totalPrice) return;
    context.read<InivitesBloc>().add(UpdateOrderPriceEvent(price: parsed));
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: _kBorder),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Offer amount'.tr(),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              height: 1.2,
              letterSpacing: -0.30,
            ),
          ),
          const Spacer(),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: _kInputBg,
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 1, color: _kBorder),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: widget.canAdjust
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('\$', style: _priceStyle),
                      SizedBox(
                        width: 64,
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          textAlignVertical: TextAlignVertical.center,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: _priceStyle,
                          cursorColor: _kPrimary,
                          onTapOutside: (_) => _focusNode.unfocus(),
                          onSubmitted: (_) {
                            _submit();
                            _focusNode.unfocus();
                          },
                        ),
                      ),
                    ],
                  )
                : Text(
                    '\$${widget.order.totalPrice.toStringAsFixed(0)}',
                    style: _priceStyle,
                  ),
          ),
          if (widget.canAdjust) ...[
            const SizedBox(width: 8),
            _PriceAdjustButton(
              color: const Color(0x19FB0000),
              icon: AppIcons.down,
              onTap: () {
                if (widget.order.price > 1) {
                  context
                      .read<InivitesBloc>()
                      .add(UpdateOrderPriceEvent(price: widget.order.price - 1));
                }
              },
            ),
            const SizedBox(width: 8),
            _PriceAdjustButton(
              color: const Color(0x1904A516),
              icon: AppIcons.up,
              onTap: () {
                context
                    .read<InivitesBloc>()
                    .add(UpdateOrderPriceEvent(price: widget.order.price + 1));
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceAdjustButton extends StatelessWidget {
  const _PriceAdjustButton({
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final Color color;
  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CommonScaleAnimation(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        padding: const EdgeInsets.all(7),
        decoration: ShapeDecoration(
          color: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: SvgPicture.asset(icon),
      ),
    );
  }
}

class _OffersCard extends StatelessWidget {
  const _OffersCard({
    required this.offers,
    required this.orderCreatedAt,
    required this.orderPrice,
  });

  final List<OrderData> offers;
  final String orderCreatedAt;
  final double orderPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
            child: Text(
              '${'Offers'.tr()}: ${offers.length}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                letterSpacing: -0.30,
              ),
            ),
          ),
          if (offers.isEmpty)
            Expanded(child: _EmptyOffers(orderCreatedAt: orderCreatedAt))
          else
            Padding(
              // ListView.separated(shrinkWrap) IntrinsicHeight ichida crash beradi -
              // bu yerda outer SingleChildScrollView allaqachon scrollni boshqaryapti,
              // shuning uchun oddiy Column ishlatamiz.
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < offers.length; i++) ...[
                    _OfferTile(offer: offers[i], orderPrice: orderPrice),
                    if (i < offers.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1, thickness: 1, color: _kDivider),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyOffers extends StatelessWidget {
  const _EmptyOffers({required this.orderCreatedAt});

  final String orderCreatedAt;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _kInputBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_empty, size: 30, color: _kSubtitle),
            ),
            const SizedBox(height: 16),
            Text(
              'Waiting for offers...'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                letterSpacing: -0.30,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Mechanics are reviewing your order'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _kSubtitle,
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                letterSpacing: -0.30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({required this.offer, required this.orderPrice});

  final OrderData offer;
  final double orderPrice;

  void _openDetail(BuildContext context) {
    showOrderDetailBottomSheet(context, offer.id.toString(), () {
      context.push(Pages.proccessOrder);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mexanik narxi haydovchining narxidan QIMMAT bo'lsa - qizil (haydovchi
    // uchun yomon). ARZON bo'lsa - yashil. Figma'dagi mantiq.
    final isExpensive = offer.proposedPrice > orderPrice;
    final isCheaper = offer.proposedPrice < orderPrice;
    final showStrike = orderPrice > 0 && offer.proposedPrice != orderPrice;

    final changeBg = isExpensive
        ? _kNegativeBg
        : (isCheaper ? _kPositiveBg : const Color(0x14C5CACD));
    final changeText = isExpensive
        ? _kNegativeText
        : (isCheaper ? _kPositiveText : _kSubtitle);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _buildContent(
            context,
            changeBg,
            changeText,
            isExpensive,
            showStrike,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Color changeBg,
    Color changeText,
    bool isExpensive,
    bool showStrike,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _AvatarWithDistance(
              imageUrl: offer.avatar,
              name: offer.mechanicName,
              distance: offer.distance,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.mechanicName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      letterSpacing: -0.30,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    offer.shopAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _kSubtitle,
                      fontSize: 11,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      letterSpacing: -0.30,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Figma: original (haydovchi) narxi strikethrough, keyin mexanik
            // narxi qalin, keyin foiz chip.
            if (showStrike) ...[
              Text(
                '\$${orderPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: _kMuted,
                  fontSize: 11,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.30,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              '\$${offer.proposedPrice.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                letterSpacing: -0.30,
              ),
            ),
            const SizedBox(width: 6),
            _ChangeChip(
              isExpensive: isExpensive,
              percent: offer.changePercent,
              backgroundColor: changeBg,
              textColor: changeText,
            ),
            if (offer.workTimeEstimateMin != null && offer.workTimeEstimateMin! > 0) ...[
              const SizedBox(width: 6),
              _MinutesChip(minutes: offer.workTimeEstimateMin!),
            ],
            const Spacer(),
            Text(
              _formatTimeAgo(offer.createdAt),
              style: const TextStyle(
                color: _kSubtitle,
                fontSize: 11,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                letterSpacing: -0.30,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Choose tugmasi - figma'da bor. Butun card ham InkWell bilan
        // tap qilinadigan; bu tugma alohida visual CTA sifatida qoladi.
        // Height 48 — loyihadagi asosiy AppButton bilan bir xil baland.
        SizedBox(
          width: double.infinity,
          height: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(width: 1, color: _kBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Choose'.tr(),
                style: const TextStyle(
                  color: _kPrimary,
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  letterSpacing: -0.30,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarWithDistance extends StatelessWidget {
  const _AvatarWithDistance({
    required this.imageUrl,
    required this.name,
    required this.distance,
  });

  final String? imageUrl;
  final String name;
  final double distance;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AvatarImage(imageUrl: imageUrl, name: name, size: 44),
          if (distance > 0)
            Positioned(
              left: 5,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Text(
                  '${distance.toStringAsFixed(distance < 10 ? 1 : 0)} km',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.30,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChangeChip extends StatelessWidget {
  const _ChangeChip({
    required this.isExpensive,
    required this.percent,
    required this.backgroundColor,
    required this.textColor,
  });

  // QIMMAT bo'lsa - ↑ qizil. ARZON bo'lsa - ↓ yashil.
  final bool isExpensive;
  final double percent;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpensive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 10,
            color: textColor,
          ),
          const SizedBox(width: 2),
          Text(
            '${percent.abs().toStringAsFixed(percent.abs() < 10 ? 1 : 0)}%',
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              letterSpacing: -0.30,
            ),
          ),
        ],
      ),
    );
  }
}

class _MinutesChip extends StatelessWidget {
  const _MinutesChip({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: _kInputBg,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, size: 11, color: _kCaption),
          const SizedBox(width: 3),
          Text(
            '~$minutes min',
            style: const TextStyle(
              color: _kCaption,
              fontSize: 10,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              letterSpacing: -0.30,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 50, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'An error occurred'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '${'Error'.tr()}: $message',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          MaterialButton(
            onPressed: () =>
                context.read<InivitesBloc>().add(FetchActiveOrderEvent()),
            color: _kPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: Text(
              'Try again'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top white card (header) skeleton.
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _SkeletonBox(width: 100, height: 13),
              SizedBox(height: 10),
              _SkeletonBox(width: 240, height: 20),
              SizedBox(height: 10),
              _SkeletonBox(width: 200, height: 15),
              SizedBox(height: 16),
              _SkeletonBox(width: double.infinity, height: 58, radius: 12),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SkeletonBox(width: 120, height: 16),
                const SizedBox(height: 18),
                for (int i = 0; i < 3; i++) ...[
                  Row(
                    children: const [
                      _SkeletonBox(width: 44, height: 44, radius: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SkeletonBox(width: 140, height: 14),
                            SizedBox(height: 6),
                            _SkeletonBox(width: 200, height: 11),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _SkeletonBox(width: double.infinity, height: 48, radius: 50),
                  if (i < 2) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1, thickness: 1, color: _kDivider),
                    const SizedBox(height: 16),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 6,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

String _formatTimeAgo(String createdAt) {
  try {
    final dateTime = DateTime.parse(createdAt).toLocal();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Now'.tr();
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${'minutes ago'.tr()}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${'hours ago'.tr()}';
    } else {
      return '${difference.inDays} ${'days ago'.tr()}';
    }
  } catch (_) {
    return 'Unknown time'.tr();
  }
}
