import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/features/home/presentation/widgets/profile_order_model_sheet.dart';
import 'package:taxi_app/src/features/worker_info/presentation/pages/worker_info_page.dart';
import 'package:taxi_app/src/routes/pages.dart';
import 'package:taxi_app/src/utils/local.dart';

class InvatesScreen extends StatefulWidget {
  const InvatesScreen({super.key});

  @override
  State<InvatesScreen> createState() => _InvatesScreenState();
}

class _InvatesScreenState extends State<InvatesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.greyBg,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '15 minutes ago',
                    style: TextStyle(
                      color: const Color(0xFF43484B),
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.30,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Old balon teshilib qolgan',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 23,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.30,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      SvgPicture.asset(
                        width: 20,
                        height: 20,
                        AppIcons.location,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 25.0),
                          child: Text(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            currentAddress,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF6B7073),
                              fontSize: 15,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.30,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.5),
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          color: const Color(0xFFE2E7EB),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 12),
                        Text(
                          'Taklif summasi',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            height: 1.20,
                            letterSpacing: -0.30,
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 13,
                          ),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFEFF2F5),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                color: const Color(0xFFE2E7EB),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '\$3000',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                height: 1.40,
                                letterSpacing: -0.30,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.all(3),
                          width: 35,
                          height: 35,
                          decoration: ShapeDecoration(
                            color: const Color(0x19FB0000),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: SvgPicture.asset(AppIcons.down),
                        ),
                        SizedBox(width: 10),
                        Container(
                          width: 38,
                          padding: const EdgeInsets.all(3),
                          height: 38,
                          decoration: ShapeDecoration(
                            color: const Color(0x1904A516),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: SvgPicture.asset(AppIcons.up),
                        ),
                        SizedBox(width: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 18),
                  Text(
                    'Takliflar: 25',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.30,
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      var percentageChange = index % 2 == 0 ? 5 : -3;
                      Color changeColor = percentageChange >= 0
                          ? Colors.green
                          : Colors.red;
                      String changeText = percentageChange >= 0
                          ? '↑${percentageChange}%'
                          : '↓${percentageChange.abs()}%';
                      return _buildOfferItem(
                        context: context,
                        index: index,
                        percentageChange: percentageChange,
                        changeColor: changeColor,
                        changeText: changeText,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferItem({
    required BuildContext context,
    required int index,
    required int percentageChange,
    required Color changeColor,
    required String changeText,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColor.white),
      child: Column(
        children: [
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: const NetworkImage(
                  "https://images.uzmovi.tv/ii/1589618967/49d815f3/30526867.jpg",
                ),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Eshonov Fakhriyor',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      height: 1.40,
                      letterSpacing: -0.30,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '3517 W. Gray St. Utica, Pennsylvania',
                    style: TextStyle(
                      color: const Color(0xFF6B7073),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.40,
                      letterSpacing: -0.30,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 13),
          Row(
            children: [
              const SizedBox(width: 6),
              Text(
                '\$2400',
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '\$2300',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  changeText,
                  style: TextStyle(color: changeColor, fontSize: 11.5),
                ),
              ),
            ],
          ),
          SizedBox(height: 13),
          MaterialButton(
            minWidth: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: () {
              showOrderDetailBottomSheet(context, () {
                context.push(Pages.workerInfo);
              });
            },
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 1, color: const Color(0xFFE2E7EB)),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              'Tanlash',
              style: TextStyle(
                color: const Color(0xFF0866FF),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                height: 1.40,
                letterSpacing: -0.30,
              ),
            ),
          ),
          SizedBox(height: 15),
          Container(
            width: double.infinity,
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  strokeAlign: BorderSide.strokeAlignCenter,
                  color: const Color(0xFFECF0F3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
