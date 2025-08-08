import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/assets/constants/icons.dart';
import 'package:mechanic/assets/constants/images.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/features/common/presentation/widgets/common_button.dart';
import 'package:mechanic/features/common/presentation/widgets/common_text_field.dart';
import 'package:mechanic/features/main/presentation/screens/main_screen.dart';

class FillUserDataScreen extends StatefulWidget {
  const FillUserDataScreen({super.key});

  @override
  State<FillUserDataScreen> createState() => _FillUserDataScreenState();
}

class _FillUserDataScreenState extends State<FillUserDataScreen> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: KeyboardDismisser(
            child: Stack(
              children: [
                Image.asset(AppImages.appBarGradient),
                Padding(
                  padding: EdgeInsets.only(
                    left: 10,
                    right: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: MediaQuery.paddingOf(context).top + 24),
                      Text(
                        'Shaxsiy ma’lumotlar',
                        style: context.textTheme.titleLarge,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Iltimos kasbingiz haqida ma’lumot bering!',
                        style: context.textTheme.titleSmall!.copyWith(color: gray5),
                      ),
                      // Align(
                      //   alignment: Alignment.centerLeft,
                      //   child: GestureDetector(
                      //     onTap: () => Navigator.pop(context),
                      //     child: SvgPicture.asset(AppIcons.arrowBack),
                      //   ),
                      // ),
                      // SizedBox(height: 16),
                      // SocialAuthItem(icon: AppIcons.google, title: 'Google orqali davom ettirish'),
                      // SizedBox(height: 18),
                      // SocialAuthItem(icon: AppIcons.apple, title: 'Apple orqali davom ettirish'),
                    ],
                  ),
                ),
                Positioned(
                  top: 150,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: 24,
                      left: 12,
                      right: 12,
                      bottom: MediaQuery.paddingOf(context).bottom,
                    ),
                    width: MediaQuery.sizeOf(context).width,
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kasbingiz qanday?', style: context.textTheme.titleSmall),
                        SizedBox(height: 26),
                        CommonTextField(
                          title: 'E-mail',
                          hint: 'E-mail manzilingizni kiriting',
                          onChanged: (value) {},
                        ),
                        SizedBox(height: 24),
                        CommonTextField(
                          title: 'Ish joyingiz qayerda?',
                          hint: 'Ismni kiriting',
                          onChanged: (value) {},
                        ),
                        SizedBox(height: 24),
                        CommonTextField(
                          title: 'Necha yildan beri ushbu kasbda faoliyat olib borasiz?',
                          hint: 'Passwordingizni kiriting',
                          suffixIcon: Text(
                            'Yil',
                            style: context.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w500),
                          ),
                          onChanged: (value) {},
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Hujjatlar',
                          style: context.textTheme.bodyMedium,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Kasbingizni tasdiqlovchi hujjatlar bo’lsa, yuklang. Bu sizni haydovchilarga tavsiya qilishimizga yordam beradi.',
                          style: context.textTheme.bodySmall!.copyWith(color: gray5),
                        ),
                        SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(0),
                          child: DottedBorder(
                            borderType: BorderType.RRect,
                            radius: Radius.circular(12),
                            strokeWidth: 1,
                            dashPattern: [4, 4],
                            color: gray3,
                            child: Container(
                              width: MediaQuery.sizeOf(context).width,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: 1.isEven
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(height: 26),
                                        SvgPicture.asset(AppIcons.addFile),
                                        SizedBox(height: 6),
                                        Text(
                                          'Yuklash uchun bosing',
                                          style: context.textTheme.bodySmall!.copyWith(
                                            color: gray4,
                                            fontSize: 14,
                                          ),
                                        ),
                                        SizedBox(height: 26),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Container(
                                              height: 38,
                                              width: 38,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                color: solitude,
                                              ),
                                              child: SvgPicture.asset(AppIcons.file),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Hujjat nomi',
                                                    style: context.textTheme.bodySmall!.copyWith(
                                                      fontSize: 14,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    '258 kb',
                                                    style: context.textTheme.bodySmall!.copyWith(
                                                      color: gray6,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SvgPicture.asset(AppIcons.trash)
                                          ],
                                        ),
                                        SizedBox(height: 18),
                                        CommonButton(
                                          height: 38,
                                          color: solitude,
                                          onTap: () {
                                          },
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SvgPicture.asset(AppIcons.plus),
                                              SizedBox(width: 8),
                                              Text(
                                                'Add more',
                                                style:
                                                    context.textTheme.bodySmall!.copyWith( fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        CommonButton(
                          text: 'Kirish',
                          onTap: () {
                            Navigator.of(context).push(CupertinoPageRoute(builder: (context) => MainScreen()));

                          },
                          isLoading: false,
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
