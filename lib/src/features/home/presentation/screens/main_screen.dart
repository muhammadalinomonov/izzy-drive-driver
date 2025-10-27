import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:taxi_app/src/features/home/presentation/screens/home_screen.dart';
import 'package:taxi_app/src/features/map/data/repo/map_repo_imp.dart';
import 'package:taxi_app/src/features/map/data/source/map_data_source.dart';
import 'package:taxi_app/src/features/map/presenation/bloc/map_bloc.dart';
import 'package:taxi_app/src/features/map/presenation/pages/map_screen.dart';
import 'package:taxi_app/src/features/master/presentation/screens/master_screen.dart';
import 'package:taxi_app/src/features/profile/presentation/pages/profile_page.dart';
import 'package:taxi_app/src/features/service/presentation/screens/service_screen.dart';
import 'package:taxi_app/src/routes/pages.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<Widget> _pages = [
    HomeScreen(),
    ServiceScreen(),
    MasterScreen(),
    ProfilePage(),
  ];

  int _initialIndex = 0;

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
