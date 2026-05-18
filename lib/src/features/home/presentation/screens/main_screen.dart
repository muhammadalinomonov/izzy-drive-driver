import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/network/auth_session.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import 'package:taxi_app/src/core/services/websocket_service.dart';
import 'package:taxi_app/src/core/utils/notifications.dart';
import 'package:taxi_app/src/features/home/presentation/screens/home_screen.dart';
import 'package:taxi_app/src/features/master/presentation/screens/master_screen.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/bloc/orders_bloc.dart';
import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:taxi_app/src/features/phone_verify/presentation/bloc/phone_verify_bloc.dart';
import 'package:taxi_app/src/features/phone_verify/presentation/widgets/phone_verify_sheet.dart';
import 'package:taxi_app/src/features/profile/data/model/profile_model.dart';
import 'package:taxi_app/src/features/profile/data/source/profile_data_source.dart';
import 'package:taxi_app/src/features/profile/presentation/pages/profile_page.dart';
import 'package:taxi_app/src/features/service/presentation/screens/service_screen.dart';
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

  final List<Widget> _pages = [
    HomeScreen(),
    ServiceScreen(),
    MasterScreen(),
    ProfilePage(),
  ];

  int _initialIndex = 0;

  bool _phoneSheetShown = false;
  late final PhoneVerifyBloc _phoneVerifyBloc;
  VoidCallback? _phoneSessionListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Open the shared WS once on enter; OrdersBloc & InivitesBloc attach
    // listeners on demand. Safe to call repeatedly — service is idempotent.
    serviceLocator<WebSocketService>().connect();
    context.read<OrdersBloc>()
      ..add(ConnectToWebSocketEvent())
      ..add(GetCurrentOrderEvent());
    // FCM tokenni backendga yangilab qo'yamiz. Token rotation yoki yangi
    // qurilma bo'lsa, shu yerda yangilanadi — backend doimo amaldagi token
    // bilan push yuboradi.
    PushNotifications.registerDeviceWithBackend();
    _phoneVerifyBloc = Routes.resolvePhoneVerifyBloc();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final redirected = await _maybeRedirectToTruckInfo();
      if (!redirected) {
        _maybeShowPhoneVerifySheet();
      }
      _handlePendingNotificationDeepLink();
    });
  }

  /// Cold-start yoki background tap orqali kelgan notification ID bo'lsa,
  /// /notifications page'ni ochib qo'yamiz. Detail emas list — chunki
  /// foydalanuvchi keyingi notificatsiyalarni ham ko'rishi mumkin.
  void _handlePendingNotificationDeepLink() {
    final pendingId = PushNotifications.pendingDeepLinkNotificationId;
    if (pendingId == null) return;
    PushNotifications.pendingDeepLinkNotificationId = null;
    if (!mounted) return;
    context.push(Pages.notifications);
  }

  /// Yangi user social-auth orqali kirgan bo'lsa yoki avval tackScreen'gacha
  /// yetmasdan chiqib ketgan bo'lsa, fura malumotlari hali to'ldirilmagan.
  /// Profile'dan truck_mark/truck_model tortib olib, bo'sh bo'lsa user'ni
  /// tackScreen'ga jo'natamiz. Returns true if redirected.
  Future<bool> _maybeRedirectToTruckInfo() async {
    final response = await ProfileDataSource().fetchProfile();
    if (!mounted) return false;
    if (response.errorText.isNotEmpty || response.data is! ProfileModel) {
      // Fetch xato bersa — gate'ni ochiq qoldiramiz. Onki keyingi navigatsiyada
      // baribir token bilan tekshiriladi.
      return false;
    }
    final profile = response.data as ProfileModel;
    final truckFilled = profile.truckMark.trim().isNotEmpty &&
        profile.truckmodel.trim().isNotEmpty;
    if (truckFilled) return false;
    context.go(Pages.tackScreen);
    return true;
  }

  Future<void> _maybeShowPhoneVerifySheet() async {
    if (_phoneSheetShown) return;
    // Source of truth — backend. Cached storage flag'ga ishonmaymiz, chunki
    // boshqa qurilmada o'chirib yuborilgan yoki admin tomonidan tozalangan
    // bo'lishi mumkin. get-me dan phone_number kelsa va u bo'sh bo'lmasa —
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
    // Phone bo'sh yoki fetch xato berdi — sheet'ni ko'rsatamiz va eski cache'ni
    // tozalaymiz. (Xato keladigan bo'lsa user OTP yuborolmaydi — fallback safer
    // — yangi qurilmada paydo bo'lgan unverified user'ni ushlab qolish uchun.)
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
    // showPhoneVerifySheet(context, bloc: _phoneVerifyBloc).whenComplete(() {
    //   if (_phoneSessionListener != null) {
    //     AuthSession.tick.removeListener(_phoneSessionListener!);
    //     _phoneSessionListener = null;
    //   }
    //   // Agar foydalanuvchi qandaydir tarzda sheet'ni yopib qo'ysa-yu, lekin
    //   // hali ham phone verify qilinmagan bo'lsa — qayta ochib qo'yamiz.
    //   if (mounted && !AuthSession.isPhoneVerified) {
    //     _phoneSheetShown = false;
    //     WidgetsBinding.instance.addPostFrameCallback((_) {
    //       _maybeShowPhoneVerifySheet();
    //     });
    //   }
    // });
  }

  @override
  void dispose() {
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
    if (_lastResumeRefresh != null && now.difference(_lastResumeRefresh!) < _resumeDebounce) {
      return;
    }
    _lastResumeRefresh = now;
    // Force a fresh socket — iOS often suspends the WS during background
    // without firing onDone, so the cached _isConnected can be a lie.
    serviceLocator<WebSocketService>().reconnect();
    // Silent refresh: avoid flashing the shimmer over the active-order card
    // that's already on screen when the user returns to the app.
    context.read<OrdersBloc>().add(GetCurrentOrderEvent(silent: true));
    // App resume bo'lganda ham FCM tokenni yangilab qo'yamiz — FCM bazan
    // background turishda tokenni o'zgartiradi va onTokenRefresh
    // boshlanish vaqtida ishlamasa, shu yerda tutib olamiz.
    PushNotifications.registerDeviceWithBackend();
  }

  static const List<_NavItemData> _navItems = [
    _NavItemData(icon: AppIcons.home, label: 'Home'),
    _NavItemData(icon: AppIcons.services, label: 'Services'),
    _NavItemData(icon: AppIcons.masters, label: 'Masters'),
    _NavItemData(icon: AppIcons.profile, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      // IndexedStack keeps every tab alive — switching tabs preserves their
      // state (scroll position, blocs, etc.), matching the previous
      // CupertinoTabScaffold behavior.
      body: IndexedStack(
        index: _initialIndex,
        children: _pages,
      ),
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
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = i == currentIndex;
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
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          isActive ? AppColor.kPrimaryColor : AppColor.grey,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive
                              ? AppColor.black
                              : const Color(0xFF6B7073),
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
