import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import 'package:taxi_app/src/core/services/websocket_service.dart';
import 'package:taxi_app/src/features/home/presentation/screens/home_screen.dart';
import 'package:taxi_app/src/features/master/presentation/screens/master_screen.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/bloc/orders_bloc.dart';
import 'package:taxi_app/src/features/profile/presentation/pages/profile_page.dart';
import 'package:taxi_app/src/features/service/presentation/screens/service_screen.dart';

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
  }

  @override
  void dispose() {
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
        return _pages[index];
      },
    );
  }
}
