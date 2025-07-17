import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';
import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:taxi_app/src/features/home/presentation/screens/home_screen.dart';
import 'package:taxi_app/src/features/worker_info/presentation/pages/worker_info_page.dart';
import 'package:taxi_app/src/routes/pages.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<Widget> _pages = [
    HomeScreen(),
    WorkerInfoPage(),
    Center(child: Text('Masters')),
    ProfileWidget(),
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
    return Scaffold(
      body: _pages[_initialIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          color: AppColor.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            bottom: 25,
            top: 12,
          ), // Adjust as needed
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_bottomIcons.length, (i) {
              final isSelected = i == _initialIndex;
              return GestureDetector(
                onTap: () => setState(() => _initialIndex = i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      _bottomIcons[i]['icon'],
                      colorFilter: ColorFilter.mode(
                        isSelected ? AppColor.kPrimaryColor : AppColor.grey,
                        BlendMode.srcIn,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _bottomIcons[i]['title'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColor.kPrimaryColor
                            : AppColor.grey,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class ProfileWidget extends StatelessWidget {
  const ProfileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () {
          StorageRepository.deleteString('token');
          context.go(Pages.signIn);
        },
        child: Text('Log out'),
      ),
    );
  }
}
