import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowPhoneVerifySheet();
    });
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
    showPhoneVerifySheet(context, bloc: _phoneVerifyBloc).whenComplete(() {
      if (_phoneSessionListener != null) {
        AuthSession.tick.removeListener(_phoneSessionListener!);
        _phoneSessionListener = null;
      }
      // Agar foydalanuvchi qandaydir tarzda sheet'ni yopib qo'ysa-yu, lekin
      // hali ham phone verify qilinmagan bo'lsa — qayta ochib qo'yamiz.
      if (mounted && !AuthSession.isPhoneVerified) {
        _phoneSheetShown = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _maybeShowPhoneVerifySheet();
        });
      }
    });
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

  final List<Map> _bottomIcons = [
    {"icon": AppIcons.home, "title": "Home"},
    {"icon": AppIcons.services, "title": "Services"},
    {"icon": AppIcons.masters, "title": "Masters"},
    {"icon": AppIcons.profile, "title": "Profile"},
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: _bottomIcons
            .map(
              (item) => BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  item['icon'],
                  color: _initialIndex == _bottomIcons.indexOf(item)
                      ? AppColor.kPrimaryColor
                      : AppColor.grey,
                ),
                label: item['title'],
              ),
            )
            .toList(),
        currentIndex: _initialIndex,
        onTap: (index) {
          setState(() {
            _initialIndex = index;
          });
        },
      ),
      tabBuilder: (context, index) {
        // CupertinoTabScaffold lays content under the tab bar by
        // default (translucent-bar pattern from iOS). Our bar is
        // opaque, so the lower strip of each page was being hidden
        // behind it. Reserve that space explicitly.
        final tabBarHeight = 50.0 + MediaQuery.viewPaddingOf(context).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: tabBarHeight),
          child: _pages[index],
        );
      },
    );
  }
}
