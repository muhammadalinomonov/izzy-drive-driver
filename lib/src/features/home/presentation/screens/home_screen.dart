import 'dart:math' as math;

import 'package:card_swiper/card_swiper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:formz/formz.dart';
import 'package:go_router/go_router.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';
import 'package:taxi_app/src/core/services/remote_config_service.dart';
import 'package:taxi_app/src/core/widgets/coming_soon_toast.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/common_scalel_animation.dart';
import 'package:taxi_app/src/features/home/presentation/bloc/bloc/home_bloc.dart';
import 'package:taxi_app/src/features/home/presentation/widgets/active_order_widget.dart';
import 'package:taxi_app/src/features/home/presentation/widgets/search_input.dart';
import 'package:taxi_app/src/features/chat/data/model/report_response.dart';
import 'package:taxi_app/src/features/notifications/presentation/widgets/notification_bell_action.dart';
import 'package:taxi_app/src/features/order_proccess/domain/entities/current_order_entity.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/bloc/orders_bloc.dart';
import 'package:taxi_app/src/features/phone_verify/presentation/widgets/phone_verify_sheet.dart';
import 'package:taxi_app/src/features/profile/presentation/bloc/history/orders_history_bloc.dart';
import 'package:taxi_app/src/routes/pages.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.showAppBar = true});

  /// Set to false when embedded under [HomeTabsScreen], whose TabBar already
  /// serves as the app bar - keeping this one would stack a second header
  /// (title + bell) directly beneath the tabs.
  final bool showAppBar;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

List<Address> _dedupedRecents(List<CurrentOrderEntity> history) {
  final seen = <String>{};
  final result = <Address>[];
  for (final order in history) {
    final addr = order.currentAddress;
    if (addr.address.isEmpty) continue;
    if (seen.add(addr.address) && result.length < 2) {
      result.add(addr);
    }
    if (result.length >= 2) break;
  }
  return result;
}

class _HomeScreenState extends State<HomeScreen> {
  late OrdersHistoryBloc historyBloc;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    historyBloc = OrdersHistoryBloc()..add(GetOrdersHistoryEvent());

    context.read<OrdersBloc>().add(GetCurrentOrderEvent());
    BlocProvider.of<HomeBloc>(context).add(GetBannersEvent());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismisser(
      child: BlocProvider.value(
        value: historyBloc,
        // Order finish bo'lgandan keyin (finished_order_screen → main'ga
        // qaytganda) OrdersBloc.currentOrder.id real ID'dan -1 ga o'tadi.
        // Shu transition'da history'ni qayta tortib olamiz — recent
        // address'lar yangi yakunlangan order bilan to'ldiriladi.
        child: BlocListener<OrdersBloc, OrdersState>(
          listenWhen: (p, c) => p.currentOrder.id > 0 && c.currentOrder.id <= 0,
          listener: (context, _) {
            historyBloc.add(GetOrdersHistoryEvent(silent: true));
          },
          child: Scaffold(
            appBar: widget.showAppBar
                ? AppBar(
                    title: Text(
                      'Home'.tr(),
                      style: context.textS.titleLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    centerTitle: false,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    actions: const [
                      NotificationBellAction(),
                      SizedBox(width: 8),
                    ],
                  )
                : null,
            body: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: RefreshIndicator.adaptive(
                onRefresh: () async {
                  // Pull-to-refresh: the RefreshIndicator spinner is the user-visible
                  // progress affordance - keep stale data on screen instead of
                  // collapsing into per-section shimmers underneath it.
                  historyBloc.add(GetOrdersHistoryEvent(silent: true));
                  context.read<OrdersBloc>().add(
                    GetCurrentOrderEvent(silent: true),
                  );
                  BlocProvider.of<HomeBloc>(
                    context,
                  ).add(GetBannersEvent(silent: true));
                  await Future.delayed(const Duration(milliseconds: 400));
                  // RefreshIndicator collapse paytida ba'zan content tepaga
                  // siljib qolishi mumkin (iOS BouncingScrollPhysics + content
                  // height o'zgarishi tufayli). 0 ga qaytarish - barqaror.
                  if (mounted && _scrollController.hasClients) {
                    _scrollController.jumpTo(0);
                  }
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  // Pull-to-refresh kuchli tortilsa content 150+px gacha
                  // pastga siljishi mumkin. Banner ekrandan chiqib ketmasligi
                  // uchun katta buffer qoldiramiz.
                  padding: const EdgeInsets.only(bottom: 180),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: BlocBuilder<OrdersBloc, OrdersState>(
                          builder: (context, state) {
                            if (state.currentOrderStatus.isInProgress ||
                                state.currentOrderStatus.isInitial) {
                              return const _HomeTopSkeleton();
                            } else if ((state.currentOrderStatus.isSuccess &&
                                    state.currentOrder.id == -1) ||
                                state.currentOrderStatus.isFailure ||
                                state.currentOrderStatus.isCanceled) {
                              return BlocBuilder<
                                OrdersHistoryBloc,
                                OrdersHistoryState
                              >(
                                builder: (context, state) {
                                  final recents = _dedupedRecents(
                                    state.ordersHistory,
                                  );
                                  return Column(
                                    children: [
                                      SearchInputWidget(
                                        isReadOnly: true,
                                        hint: 'Where should the master come?'
                                            .tr(),
                                        textInputAction: TextInputAction.search,
                                        onTap: () {
                                          context.push(Pages.searchLocation);
                                        },
                                      ),
                                      // Tarix bo'sh bo'lsa hech narsa ko'rsatmaymiz -
                                      // search inputdan keyin to'g'ridan-to'g'ri "Boshqa
                                      // imkoniyatlar" boshlanadi.
                                      if (recents.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        ...recents.map(
                                          (addr) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: LastLocationWidget(
                                              address: addr.address,
                                              onTap: () {
                                                if (!ensurePhoneVerified(
                                                  context,
                                                )) {
                                                  return;
                                                }
                                                context.push(
                                                  Pages.orderCreate,
                                                  extra: {
                                                    'address': addr.address,
                                                    'latitude': addr.latitude,
                                                    'longitude': addr.longitude,
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              );
                            } else if (state.currentOrderStatus.isSuccess) {
                              return GestureDetector(
                                onTap: () {
                                  if (state.currentOrder.status.isPending) {
                                    context.push(Pages.invatesPage);
                                  } else if (state
                                      .currentOrder
                                      .status
                                      .isMechanicDone) {
                                    context.push(Pages.finishedOrder);
                                  } else {
                                    context.push(Pages.proccessOrder);
                                  }
                                },
                                child: ActiveOrderWidget(
                                  orderId: state.currentOrder.id,
                                  status: state.currentOrder.status,
                                ),
                              );
                            } else {
                              return Center(
                                child: Text(
                                  'An error occurred'.tr(),
                                  style: context.textS.bodyLarge,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      OtherOpportunitiesWidget(),
                      const HowItWorksWidget(),
                      const SizedBox(height: 25),
                      BannerWidget(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _openBannerRouter(BuildContext context, String router) async {
  if (router.isEmpty) return;
  Uri? uri;
  try {
    uri = Uri.parse(router);
  } catch (_) {
    uri = null;
  }
  if (uri == null || (!uri.hasScheme)) {
    // Treat as plain URL without scheme - fall back to https
    try {
      uri = Uri.parse('https://$router');
    } catch (_) {
      return;
    }
  }
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Could not open link')));
  }
}

class BannerWidget extends StatelessWidget {
  const BannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state.status == HomeStatus.loading) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Shimmer.fromColors(
              baseColor: const Color(0xFFEFF3F6),
              highlightColor: const Color(0xFFF7F9FB),
              period: const Duration(milliseconds: 1400),
              child: Container(
                width: double.infinity,
                height: 137,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3F6),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );
        } else if (state.status == HomeStatus.error) {
          return SizedBox(
            height: 137,
            child: Swiper(
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 340,
                      height: 140,
                      color: Colors.grey[300],
                      child: Center(child: Text(state.errorMessage)),
                    ),
                  ),
                );
              },
              itemCount: 2,
              autoplay: true,
              viewportFraction: 1.0,
              scale: 0.95,
            ),
          );
        } else {
          return SizedBox(
            height: 137,
            child: Swiper(
              itemBuilder: (BuildContext context, int index) {
                final banner = state.banners[index];
                final router = (banner['router'] as String?)?.trim() ?? '';
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _openBannerRouter(context, router),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        banner['image'],
                        fit: BoxFit.cover,
                        width: 340,
                        errorBuilder:
                            (
                              BuildContext context,
                              Object exception,
                              StackTrace? stackTrace,
                            ) {
                              return Container(
                                width: 340,
                                height: 140,
                                color: Colors.grey[300],
                                child: Center(child: Icon(Icons.error)),
                              );
                            },
                        loadingBuilder:
                            (
                              BuildContext context,
                              Widget child,
                              ImageChunkEvent? loadingProgress,
                            ) {
                              if (loadingProgress == null) return child;
                              return Shimmer.fromColors(
                                baseColor: const Color(0xFFEFF3F6),
                                highlightColor: const Color(0xFFF7F9FB),
                                period: const Duration(milliseconds: 1400),
                                child: Container(
                                  width: double.infinity,
                                  height: 137,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF3F6),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              );
                            },
                      ),
                    ),
                  ),
                );
              },
              itemCount: state.banners.length,
              autoplay: true,
              viewportFraction: 1.0,
              scale: 0.95,
            ),
          );
        }
      },
    );
  }
}

class _HomeTopSkeleton extends StatelessWidget {
  const _HomeTopSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEFF3F6),
      highlightColor: const Color(0xFFF7F9FB),
      period: const Duration(milliseconds: 1400),
      child: Column(
        children: [
          _SkeletonBox(height: 50, radius: 50),
          const SizedBox(height: 12),
          _SkeletonBox(height: 54, radius: 12),
          const SizedBox(height: 8),
          _SkeletonBox(height: 54, radius: 12),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height, this.radius = 12});
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3F6),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class LastLocationWidget extends StatelessWidget {
  const LastLocationWidget({
    super.key,
    required this.address,
    required this.onTap,
  });

  final String address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final commaIdx = address.indexOf(',');
    final title = commaIdx > 0
        ? address.substring(0, commaIdx).trim()
        : address.trim();
    final subtitle = commaIdx > 0 ? address.substring(commaIdx + 1).trim() : '';

    return CommonScaleAnimation(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColor.grey2, width: 1),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SvgPicture.asset(AppIcons.pending, width: 20, height: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: AppColor.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Static "how it works" section shown on the home tab while the "Other
/// opportunities" section is hidden, so the home always has useful, complete
/// content (no placeholders).
class HowItWorksWidget extends StatelessWidget {
  const HowItWorksWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Only shown when "Other opportunities" is hidden, so the two never stack.
    if (RemoteConfigService.showOtherOpportunities) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.lightBlue,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How it works'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _HowItWorksStep(
              number: '1',
              title: 'Set your location'.tr(),
              subtitle: 'Tell us where you need roadside help.'.tr(),
            ),
            _HowItWorksStep(
              number: '2',
              title: 'Get matched'.tr(),
              subtitle: 'A nearby mechanic accepts your request.'.tr(),
            ),
            _HowItWorksStep(
              number: '3',
              title: 'Help arrives'.tr(),
              subtitle: 'Track the mechanic in real time until they reach you.'
                  .tr(),
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final bool isLast;

  const _HowItWorksStep({
    required this.number,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColor.kPrimaryColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: AppColor.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// New widget for 'Boshqa imkoniyatlar'
class OtherOpportunitiesWidget extends StatelessWidget {
  const OtherOpportunitiesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Gated behind a Firebase Remote Config flag (default false). The whole
    // "Other opportunities" section stays hidden until it is enabled remotely
    // — and only once the gated services are actually complete/compliant.
    if (!RemoteConfigService.showOtherOpportunities) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Other opportunities'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _OpportunityCard(
                icon: 'assets/images/food.png',
                label: 'Food'.tr(),
                soon: true,
              ),
              const SizedBox(width: 12),
              _OpportunityCard(
                icon: 'assets/images/deliver.png',
                label: 'Delivery'.tr(),
                soon: true,
              ),
              const SizedBox(width: 12),
              _OpportunityCard(
                icon: 'assets/images/grocery.png',
                label: 'Grocery'.tr(),
                soon: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _OpportunityCard(
                    icon: 'assets/images/activities.png',
                    label: 'Activities'.tr(),
                    soon: true,
                    isLarge: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _GymCard(
                        image: 'assets/images/gym.png',
                        name: 'Gym 1.8 elite'.tr(),
                        distance: '1.8 km',
                      ),
                      _GymCard(
                        image: 'assets/images/cardio.png',
                        name: 'Cardio Elite'.tr(),
                        distance: '1.8 km',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  final String icon;
  final String label;
  final bool soon;
  final bool isLarge;

  const _OpportunityCard({
    required this.icon,
    required this.label,
    this.soon = false,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: AppColor.lightBlue,
          child: InkWell(
            onTap: soon
                ? () => showComingSoonToast(context, icon: icon, label: label)
                : null,
            splashColor: AppColor.kPrimaryColor.withValues(alpha: 0.08),
            highlightColor: AppColor.kPrimaryColor.withValues(alpha: 0.04),
            child: SizedBox(
              height: isLarge ? 112 : 78,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          icon,
                          width: isLarge ? 60 : 40,
                          height: isLarge ? 50 : 32,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (soon)
                    Positioned(
                      top: 6,
                      right: -22,
                      child: Transform.rotate(
                        angle: 45 * math.pi / 180,
                        alignment: Alignment.center,
                        child: Container(
                          width: 80,
                          height: 18,
                          alignment: Alignment.center,
                          color: const Color(0xFF7BA2B9),
                          child: Text(
                            'SOON'.tr(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GymCard extends StatelessWidget {
  final String image;
  final String name;
  final String distance;

  const _GymCard({
    required this.image,
    required this.name,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showComingSoonToast(context, icon: image, label: name),
        borderRadius: BorderRadius.circular(10),
        splashColor: AppColor.kPrimaryColor.withValues(alpha: 0.08),
        highlightColor: AppColor.kPrimaryColor.withValues(alpha: 0.04),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                image,
                width: 60,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7BA2B9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'SOON'.tr(),
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    distance,
                    style: TextStyle(fontSize: 11, color: AppColor.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
