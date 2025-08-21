import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/assets/constants/icons.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/features/common/presentation/widgets/common_button.dart';
import 'package:mechanic/features/common/presentation/widgets/common_image.dart';
import 'package:mechanic/features/main/presentation/widgets/order_information_widget.dart';

class FinishedOrderSingleScreen extends StatefulWidget {
  const FinishedOrderSingleScreen({super.key});

  @override
  State<FinishedOrderSingleScreen> createState() => _FinishedOrderSingleScreenState();
}

class _FinishedOrderSingleScreenState extends State<FinishedOrderSingleScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: CommonButton(
        text: 'Asosiyga qaytish',
        margin: EdgeInsets.symmetric(horizontal: 12),
        onTap: () {
          Navigator.pop(context);
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: context.sizeOf.width,
              padding: EdgeInsets.only(top: context.padding.top + 18, right: 27, left: 27, bottom: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                color: white,
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SvgPicture.asset(
                  AppIcons.circularCheck,
                  width: 50,
                  height: 50,
                ),
                SizedBox(height: 18),
                Text(
                  'Muvaffaqiyatli yakunlandi!',
                  style: context.textTheme.bodyMedium!.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Lorem Ipsum is simply dummy text of the printing and typesetting industry',
                  style: context.textTheme.bodySmall!.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: gray4,
                  ),
                  textAlign: TextAlign.center,
                )
              ]),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Haydovchi ma’lumotlari',
                    style: context.textTheme.bodyMedium!.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      CommonImage(
                        imageUrl: 'https://example.com/driver_image.jpg',
                        width: 44,
                        height: 44,
                        borderRadius: 22,
                        fit: BoxFit.cover,
                        errorImage: SvgPicture.asset(AppIcons.avatar),
                      ),
                      SizedBox(width: 12),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Eshonov Fakhriyor',
                            style: context.textTheme.bodyMedium!.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '+998 97 628 28 82',
                            style: context.textTheme.bodySmall!.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: gray4,
                            ),
                          )
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
            OrderInformationWidget(createdAt: '', workDuration: '',address: '',),
            Container(
              margin: EdgeInsets.only(top: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xizmatlar',
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        'Balonni yamash',
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: gray4,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 8),
                          color: solitude,
                          height: 1,
                        ),
                      ),
                      Text(
                        '\$1000',
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  ...List.generate(
                    1,
                    (index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: index == 3 - 1 ? 0 : 12),
                        child: Row(
                          children: [
                            Text(
                              'Kolodkani almashtirish',
                              style: context.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                                color: gray4,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 8),
                                color: solitude,
                                height: 1,
                              ),
                            ),
                            Text(
                              '\$1000',
                              style: context.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    padding: EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: aliceBlue,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Umumiy summa',
                          style: context.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w400, fontSize: 14, color: matisse),
                        ),
                        Text(
                          '\$2000',
                          style: context.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500, fontSize: 16, color: mainColor),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 88)
          ],
        ),
      ),
    );
  }
}
