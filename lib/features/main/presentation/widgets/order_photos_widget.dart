import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/assets/constants/icons.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/features/common/presentation/widgets/common_scalel_animation.dart';

class OrderPhotosWidget extends StatefulWidget {
  const OrderPhotosWidget({super.key, required this.photos});

  final List<String> photos;

  @override
  State<OrderPhotosWidget> createState() => _OrderPhotosWidgetState();
}

class _OrderPhotosWidgetState extends State<OrderPhotosWidget> {
  bool isCollapsed = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Photos',
                style: context.textTheme.bodyMedium,
              ),
              CommonScaleAnimation(
                onTap: () {
                  setState(() {
                    isCollapsed = !isCollapsed;
                  });
                },
                child: Transform.rotate(
                  angle: isCollapsed ? 0 : 3.14,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(color: solitude, borderRadius: BorderRadius.circular(10)),
                    child: SvgPicture.asset(AppIcons.chevronDown, width: 24, height: 24),
                  ),
                ),
              )
            ],
          ),
          AnimatedCrossFade(
            firstChild: SizedBox(),
            secondChild: Container(
              decoration: BoxDecoration(
                  color: aliceBlue, borderRadius: BorderRadius.circular(18).copyWith(bottomLeft: Radius.circular(0))),
              padding: EdgeInsets.all(8),
              child: Wrap(
                children: [
                  for (int i = 0; i < widget.photos.length; i++)
                    Container(
                      margin: EdgeInsets.all(4),
                      width: 85,
                      height: 79,
                      decoration: BoxDecoration(
                          color: white,
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(image: NetworkImage(widget.photos[i]), fit: BoxFit.cover)),
                    )
                ],
              ),
            ),
            crossFadeState: isCollapsed ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: Duration(milliseconds: 300),
          )
        ],
      ),
    );
  }
}
