import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/assets/constants/icons.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/features/main/presentation/widgets/balance_item.dart';
import 'package:mechanic/features/main/presentation/widgets/main_screen_user_widget.dart';
import 'package:mechanic/features/profile/presentation/pages/orders_history_screen.dart';
import 'package:mechanic/features/profile/presentation/widgets/profile_item.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Profile'),
        titleTextStyle: context.textTheme.headlineLarge!.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: black,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MainScreenUserWidget(fromMain: false),
            SizedBox(height: 8),
            BalanceItem(fromMain: false),
            Container(
              height: 234,
              margin: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: white,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ProfileItem(
                    icon: AppIcons.history,
                    title: 'Buyurtmalar',
                    data: '',
                    onTap: () {
                      Navigator.of(context).push(CupertinoPageRoute(builder: (context) => OrdersHistoryScreen()));

                    },
                  ),
                  Divider(color: grayLine, height: 1,thickness: 1),

                  ProfileItem(
                    icon: AppIcons.contact,
                    title: 'Mening ma’lumotlarim',
                  ),

                  Divider(color: grayLine, height: 1,thickness: 1),

                  ProfileItem(
                    icon: AppIcons.starOutline,
                    title: 'Ilovamizni baholang',
                  ),
                  Divider(color: grayLine, height: 1,thickness: 1),
                  ProfileItem(
                    icon: AppIcons.globe,
                    title: 'Til',
                    data: 'O’zbekcha',
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
