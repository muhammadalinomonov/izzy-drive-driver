import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/core/constants/color/app_icons.dart';
import 'package:taxi_app/features/home/presentation/screens/home_screen.dart';
import 'package:taxi_app/features/notifications/presentation/widgets/notification_bell_action.dart';
import 'package:taxi_app/features/trips/presentation/pages/trips_page.dart';

/// Host for the home area's top tabs (see `docs/ui/1.png`).
///
/// Tab 1 "Trips"   -> toll-route history from the Quadrix Tolling backend.
/// Tab 2 "Masters" -> the existing [HomeScreen] (search, recents, active order).
///
/// The tab row IS the app bar here, so [HomeScreen] is embedded with
/// `showAppBar: false` - otherwise its own "Home" AppBar would stack directly
/// under the tabs. `MasterScreen` is untouched and keeps its own slot in the
/// bottom navigation.
class HomeTabsScreen extends StatefulWidget {
  const HomeTabsScreen({super.key});

  @override
  State<HomeTabsScreen> createState() => _HomeTabsScreenState();
}

class _HomeTabsScreenState extends State<HomeTabsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        backgroundColor: AppColor.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: TabBar(
          controller: _controller,
          // Left-aligned, content-width tabs with the indicator hugging the
          // label - a stretched full-width TabBar doesn't match the design.
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: EdgeInsets.zero,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorWeight: 3,
          indicatorColor: AppColor.kPrimaryColor,
          dividerColor: Colors.transparent,
          labelColor: AppColor.black,
          unselectedLabelColor: AppColor.black,
          labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: [
            _TabLabel(icon: AppIcons.tabTrips, label: 'trips.tab'.tr()),
            _TabLabel(icon: AppIcons.tabMasters, label: 'Masters'.tr()),
          ],
        ),
        actions: const [NotificationBellAction(), SizedBox(width: 8)],
      ),
      body: TabBarView(
        controller: _controller,
        children: const [
          TripsPage(),
          HomeScreen(showAppBar: false),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 44,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Multi-color artwork - intentionally not tinted, matching 1.png.
          SvgPicture.asset(icon, width: 20, height: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
