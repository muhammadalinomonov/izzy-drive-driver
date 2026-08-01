import 'package:flutter/material.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/features/master/data/model/review_model.dart';
import 'package:taxi_app/features/master/presentation/widgets/review_item.dart';

/// Barcha sharhlar - MasterDetailSheet'dan "ALL COMMENTS" bosilganda
/// to'liq ro'yxatni ko'rsatadi. Reviews ro'yxati allaqachon bloc'da
/// yuklangan bo'lgani sabab konstruktor argumenti orqali uzatamiz -
/// bloc'ga qayta murojaat shart emas.
class AllReviewsScreen extends StatelessWidget {
  const AllReviewsScreen({super.key, required this.reviews});

  final List<ReviewModel> reviews;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.lightBlue,
      appBar: AppBar(
        title: const Text(
          'Reviews',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: reviews.isEmpty
          ? Center(
              child: Text(
                'No reviews yet',
                style: TextStyle(color: AppColor.grey, fontSize: 13),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: reviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final review = reviews[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColor.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ReviewItem(
                    rating: review.stars,
                    review: review.comment,
                    tag: review.tag,
                    date: review.createdAt,
                    avatar: review.driverAvatar,
                    name: review.driverName,
                  ),
                );
              },
            ),
    );
  }
}
