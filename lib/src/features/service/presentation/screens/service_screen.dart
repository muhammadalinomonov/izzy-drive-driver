import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';
import 'package:taxi_app/src/core/widgets/coming_soon_toast.dart';
import 'package:taxi_app/src/features/notifications/presentation/widgets/notification_bell_action.dart';

class ServiceScreen extends StatelessWidget {
  const ServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Services',
          style: context.textS.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w500),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: const [
          NotificationBellAction(),
          SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category tiles
            Row(
              children: const [
                _CategoryTile(icon: 'assets/images/food.png', label: 'Food'),
                SizedBox(width: 12),
                _CategoryTile(icon: 'assets/images/deliver.png', label: 'Delivery'),
                SizedBox(width: 12),
                _CategoryTile(icon: 'assets/images/activities.png', label: 'Activities'),
                SizedBox(width: 12),
                _CategoryTile(icon: 'assets/images/grocery.png', label: 'Grocery'),
              ],
            ),
            const SizedBox(height: 18),
            // Search pill
            const _SearchPill(),
            const SizedBox(height: 24),
            // Service cards
            const _ServiceCard(
              category: 'Food',
              categoryColor: Color(0xFFE73E3E),
              image: 'assets/images/kfc.jpg',
              title: 'KFC California',
              rating: '4.6',
              time: '20-25 min.',
            ),
            const SizedBox(height: 24),
            _ServiceCard(
              category: 'Activities',
              categoryColor: AppColor.blueMain,
              image: 'assets/images/gym.png',
              title: 'Gym 1.8 elite',
              rating: '4.6',
              time: '20-25 min.',
            ),
            const SizedBox(height: 24),
            // const _ServiceCard(
            //   category: 'Grocery',
            //   categoryColor: Color(0xFF00C23D),
            //   image: 'assets/images/grocery.png',
            //   title: 'Fresh Market',
            //   rating: '4.6',
            //   time: '20-25 min.',
            // ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String icon;
  final String label;
  const _CategoryTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: AppColor.lightBlue,
          child: InkWell(
            onTap: () =>
                showComingSoonToast(context, icon: icon, label: label),
            splashColor: AppColor.kPrimaryColor.withValues(alpha: 0.08),
            highlightColor: AppColor.kPrimaryColor.withValues(alpha: 0.04),
            child: SizedBox(
              height: 78,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(icon, width: 38, height: 35, fit: BoxFit.contain),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColor.lightBlue,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          SvgPicture.asset(AppIcons.search, width: 24, height: 24),
          const SizedBox(width: 16),
          const Text(
            'Search',
            style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String category;
  final Color categoryColor;
  final String image;
  final String title;
  final String rating;
  final String time;

  const _ServiceCard({
    required this.category,
    required this.categoryColor,
    required this.image,
    required this.title,
    required this.rating,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showComingSoonToast(context, icon: image, label: title),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                image,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  width: double.infinity,
                  color: AppColor.lightBlue,
                  alignment: Alignment.center,
                  child: Icon(Icons.image_outlined, color: AppColor.grey, size: 40),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            SvgPicture.asset(AppIcons.star, width: 18, height: 18),
            const SizedBox(width: 2),
            Text(
              rating,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
            ),
            const SizedBox(width: 10),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.grey,
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.directions_walk, size: 18, color: AppColor.grey),
            const SizedBox(width: 6),
            Text(
              time,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF303130)),
            ),
          ],
        ),
      ],
      ),
    );
  }
}
