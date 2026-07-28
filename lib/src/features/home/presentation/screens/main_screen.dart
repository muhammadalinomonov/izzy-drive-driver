import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/network/auth_session.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import 'package:taxi_app/src/core/services/websocket_service.dart';
import 'package:taxi_app/src/core/utils/adaptive_poller.dart';
import 'package:taxi_app/src/core/utils/notifications.dart';
import 'package:taxi_app/src/features/home/presentation/screens/home_tabs_screen.dart';
import 'package:taxi_app/src/features/master/presentation/screens/master_screen.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/bloc/orders_bloc.dart';
import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:taxi_app/src/features/phone_verify/presentation/bloc/phone_verify_bloc.dart';
// ignore: unused_import
import 'package:taxi_app/src/features/phone_verify/presentation/widgets/phone_verify_sheet.dart';
import 'package:taxi_app/src/features/profile/data/model/profile_model.dart';
import 'package:taxi_app/src/features/profile/data/source/profile_data_source.dart';
import 'package:taxi_app/src/features/profile/presentation/pages/profile_page.dart';
import 'package:taxi_app/src/routes/app_router.dart';
import 'package:taxi_app/src/routes/pages.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  static const _resumeDebounce = Duration(seconds: 10);
  DateTime? _lastResumeRefresh;

  // NOTE: the "Services" tab (ServiceScreen) is temporarily removed from the
  // bottom navigation while its marketplace content is still in development.
  //
  // Slot 0 is the top-tab host (Trips + the former HomeScreen), not HomeScreen
  // directly - see HomeTabsScreen. MasterScreen keeps its own slot untouched.
  final List<Widget> _pages = [HomeTabsScreen(), MasterScreen(), ProfilePage()];

  int _initialIndex = 0;

  bool _phoneSheetShown = false;
  // ignore: unused_field
  late final PhoneVerifyBloc _phoneVerifyBloc;
  VoidCallback? _phoneSessionListener;
  late final AdaptivePoller _poller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // WS faqat active order paytida ulanadi — main_screen.init'da
    // unconditional connect olib tashlandi. OrdersBloc.GetCurrentOrderEvent
    // qaytib kelganda, currentOrder.id != -1 bo'lsa o'zi `_ws.connect()`
    // chaqiradi (ref-counted retain).
    context.read<OrdersBloc>().add(GetCurrentOrderEvent());
    // WS uzilib qolgan vaziyatlarda backup polling - silent fetch UI'ni
    // o'zgartirmaydi, foydalanuvchi sezmaydi.
    _poller = AdaptivePoller(
      ws: serviceLocator<WebSocketService>(),
      onPoll: () {
        if (!mounted) return;
        context.read<OrdersBloc>().add(GetCurrentOrderEvent(silent: true));
      },
    )..start();
    // FCM tokenni backendga yangilab qo'yamiz. Token rotation yoki yangi
    // qurilma bo'lsa, shu yerda yangilanadi - backend doimo amaldagi token
    // bilan push yuboradi.
    PushNotifications.registerDeviceWithBackend();
    _phoneVerifyBloc = Routes.resolvePhoneVerifyBloc();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Truck info is optional ("recommended"), so we no longer force-redirect
      // users to the truck screen on entry — that looped with the truck
      // screen's "Skip" button (Skip -> main -> redirected back to truck).
      // The phone sheet below is dismissible; phone verification is enforced
      // only when the user actually creates an order.
      _maybeShowPhoneVerifySheet();
      _handlePendingNotificationDeepLink();
    });
  }

  /// Cold-start yoki background tap orqali kelgan notification ID bo'lsa,
  /// /notifications page'ni ochib qo'yamiz. Detail emas list - chunki
  /// foydalanuvchi keyingi notificatsiyalarni ham ko'rishi mumkin.
  void _handlePendingNotificationDeepLink() {
    final pendingId = PushNotifications.pendingDeepLinkNotificationId;
    if (pendingId == null) return;
    PushNotifications.pendingDeepLinkNotificationId = null;
    if (!mounted) return;
    context.push(Pages.notifications);
  }

  Future<void> _maybeShowPhoneVerifySheet() async {
    if (_phoneSheetShown) return;
    // Source of truth - backend. Cached storage flag'ga ishonmaymiz, chunki
    // boshqa qurilmada o'chirib yuborilgan yoki admin tomonidan tozalangan
    // bo'lishi mumkin. get-me dan phone_number kelsa va u bo'sh bo'lmasa -
    // verified deb hisoblaymiz.
    final response = await ProfileDataSource().fetchProfile();
    if (!mounted) return;
    if (response.errorText.isEmpty && response.data is ProfileModel) {
      final phone = (response.data as ProfileModel).phoneNumber.trim();
      if (phone.isNotEmpty) {
        await StorageRepository.putBool(key: 'phone_verified', value: true);
        return;
      }
    }
    // Phone bo'sh yoki fetch xato berdi - sheet'ni ko'rsatamiz va eski cache'ni
    // tozalaymiz. (Xato keladigan bo'lsa user OTP yuborolmaydi - fallback safer
    // - yangi qurilmada paydo bo'lgan unverified user'ni ushlab qolish uchun.)
    await StorageRepository.deleteBool('phone_verified');
    _phoneSheetShown = true;
    // OTP muvaffaqiyatli tugaganda AuthSession.tick'ga listener qo'shamiz,
    // shunda OTP page'dan qaytib bu sheet ham yopiladi.
    _phoneSessionListener = () {
      if (!mounted) return;
      if (AuthSession.isPhoneVerified && Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    };
    AuthSession.tick.addListener(_phoneSessionListener!);
    if (!context.mounted) return;
    if (2.isOdd) return;
    showPhoneVerifySheet(context, bloc: _phoneVerifyBloc).whenComplete(() {
      if (_phoneSessionListener != null) {
        AuthSession.tick.removeListener(_phoneSessionListener!);
        _phoneSessionListener = null;
      }
      // Sheet is dismissible: if the user closes it without verifying, we let
      // them keep using the rest of the app. Phone verification is requested
      // again only when they try to create an order.
    });
  }

  @override
  void dispose() {
    _poller.dispose();
    if (_phoneSessionListener != null) {
      AuthSession.tick.removeListener(_phoneSessionListener!);
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final now = DateTime.now();
    if (_lastResumeRefresh != null &&
        now.difference(_lastResumeRefresh!) < _resumeDebounce) {
      return;
    }
    _lastResumeRefresh = now;
    // Force a fresh socket - iOS often suspends the WS during background
    // without firing onDone, so the cached _isConnected can be a lie.
    serviceLocator<WebSocketService>().reconnect();
    // Silent refresh: avoid flashing the shimmer over the active-order card
    // that's already on screen when the user returns to the app.
    context.read<OrdersBloc>().add(GetCurrentOrderEvent(silent: true));
  }

  static const List<_NavItemData> _navItems = [
    _NavItemData(icon: AppIcons.home, label: 'Home'),
    _NavItemData(icon: AppIcons.masters, label: 'Masters'),
    _NavItemData(icon: AppIcons.profile, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      // IndexedStack keeps every tab alive - switching tabs preserves their
      // state (scroll position, blocs, etc.), matching the previous
      // CupertinoTabScaffold behavior.
      body: IndexedStack(index: _initialIndex, children: _pages),
      bottomNavigationBar: _AppBottomNav(
        items: _navItems,
        currentIndex: _initialIndex,
        onTap: (index) {
          setState(() {
            _initialIndex = index;
          });
        },
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({required this.icon, required this.label});
  final String icon;
  final String label;
}

class _AppBottomNav extends StatelessWidget {
  const _AppBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_NavItemData> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -4),
            blurRadius: 18,
            color: Colors.black.withAlpha(20),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = i == currentIndex;
              final color = isActive ? AppColor.kPrimaryColor : AppColor.grey;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        item.icon,
                        width: 18,
                        height: 18,
                        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: color,
                          letterSpacing: 0,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
