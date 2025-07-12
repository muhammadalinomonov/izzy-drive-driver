// ! Responsive Order Detail Bottom Sheet
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/widgets/app_button.dart';

void showOrderDetailBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final mq = MediaQuery.of(context);
      return DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: AppColor.kPrimary2Color,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(
                      top: 12,
                      left: 50,
                      right: 60,
                      bottom: 18,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColor.white,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 5,
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        _ProfileSection(),
                        SizedBox(height: 18),
                        _StatsRow(),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColor.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle('ABOUT ORDER'),
                        _OrderInfoSection(),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColor.white,
                    ),
                    child: Column(
                      children: [
                        _SectionTitle('PAYMENT INFORMATION'),
                        _PaymentOptionsSection(),
                      ],
                    ),
                  ),
                  SizedBox(height: 18),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColor.white,
                    ),
                    child: Column(
                      children: [
                        _OffersRow(),
                        SizedBox(height: 18),
                        AppButton(title: 'Chiqarish', onTap: (){})
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _ProfileSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Column(
      children: [
        CircleAvatar(
          radius: mq.size.width * 0.13,
          backgroundImage: NetworkImage(
            'https://randomuser.me/api/portraits/men/1.jpg',
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Eshonov Fakhriyоr',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Registered data  15.06.2025 (35 days ago)',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColor.grey),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    TextStyle? labelStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: AppColor.grey);
    TextStyle? valueStyle = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatColumn('All orders', '658', labelStyle, valueStyle),
        _StatColumn('Success', '600', labelStyle, valueStyle),
        _StatColumn('Performance', '99%', labelStyle, valueStyle),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  const _StatColumn(this.label, this.value, this.labelStyle, this.valueStyle);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: labelStyle),
        SizedBox(height: 4),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColor.darkGrey,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OrderInfoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    TextStyle? labelStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColor.grey);
    TextStyle? valueStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Muammo', style: labelStyle),
          Text('Old balon teshilib qolgan', style: valueStyle),
          SizedBox(height: 8),
          Text('Qayerga', style: labelStyle),
          Text('3517 W. Gray St. Utica, Pennsylvania', style: valueStyle),
          Text('3 km uzoqlikda (30 daqiqada keladi)', style: labelStyle),
        ],
      ),
    );
  }
}

class _PaymentOptionsSection extends StatefulWidget {
  @override
  State<_PaymentOptionsSection> createState() => _PaymentOptionsSectionState();
}

class _PaymentOptionsSectionState extends State<_PaymentOptionsSection> {
  bool isApple = Platform.isIOS;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PaymentOptionTile(
          icon: AppIcons.apple,
          label: 'Apple Pay',
          selected: isApple,
          onTap: () => setState(() => isApple = true),
        ),
        Divider(
          endIndent: 10,
          indent: 10,
          color: AppColor.lightGrey,
          height: 0.1,
        ),
        _PaymentOptionTile(
          icon: AppIcons.google,
          label: 'Google Pay',
          selected: !isApple,
          onTap: () => setState(() => isApple = false),
        ),
      ],
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final String icon;
  final String label;
  bool selected;
  final VoidCallback onTap;
  _PaymentOptionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return ListTile(
          leading: SvgPicture.asset(icon),
          title: Text(label),
          trailing: Transform.scale(
            scale: 1.3,
            child: Checkbox(
              side: BorderSide(width: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              value: selected,
              onChanged: (bool? value) {
                setState(() {
                  selected = value!;
                });
              },
            ),
          ),
          onTap: onTap,
        );
      },
    );
  }
}

class _OffersRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    TextStyle? labelStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColor.grey);
    TextStyle? valueStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 18);
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Sizning taklifingiz', style: labelStyle),
                SizedBox(height: 4),
                Text('1500 \$', style: valueStyle),
              ],
            ),
          ),
          Container(width: 1, height: 32, color: Colors.grey[300]),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Ustani taklifi', style: labelStyle),
                SizedBox(height: 4),
                Text(
                  '1500 \$',
                  style: valueStyle?.copyWith(color: AppColor.kPrimaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
