import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/widgets/app_button.dart';
import 'package:taxi_app/src/features/choose_inivates/presentation/widgets/profile_order_model_sheet.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/common_image.dart';

void showCommentSectionModalSheet(BuildContext context) {
  bool showAllComments = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColor.lightBlue, // White background
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.only(
                        top: 12,
                        bottom: 18,
                        left: 48,
                        right: 48,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.white,
                        borderRadius: BorderRadius.circular(16),
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
                          ProfileSection(),
                          SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _ProfileStat(title: 'All orders', value: '658'),
                              _ProfileStat(title: 'Success', value: '600'),
                              _ProfileStat(title: 'Performance', value: '99%'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(top: 8),
                        padding: EdgeInsets.only(
                          left: 20,
                          right: 20,
                          bottom: 0,
                          top: 18,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'COMMENTS AND RATINGS',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppColor.darkGrey,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            SizedBox(height: 12),
                            Expanded(
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: BouncingScrollPhysics(),
                                controller: scrollController,
                                itemCount: showAllComments
                                    ? _mockComments.length
                                    : (_mockComments.length > 2
                                          ? 2
                                          : _mockComments.length),
                                separatorBuilder: (_, __) => Divider(
                                  height: 32,
                                  thickness: 1,
                                  color: Colors.grey[200],
                                ),
                                itemBuilder: (context, index) {
                                  final comment = _mockComments[index];
                                  return _CommentCard(comment: comment);
                                },
                              ),
                            ),
                            SizedBox(height: 12),
                            if (!showAllComments && _mockComments.length > 2)
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      showAllComments = true;
                                    });
                                  },
                                  child: Text(
                                    'ALL COMMENTS',
                                    style: TextStyle(
                                      color: AppColor.kPrimaryColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 32, thickness: 1, color: Colors.grey[200]),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 10,
                        bottom: 20,
                        left: 11,
                        right: 11,
                      ),
                      child: AppButton(
                        title: 'Exit',
                        onTap: () => Navigator.pop(context),
                        backGroundColor: AppColor.lightGrey,
                        textColor: AppColor.black,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

class _CommentCard extends StatelessWidget {
  final _Comment comment;
  const _CommentCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AvatarImage(imageUrl: comment.avatarUrl, size: 40),
            SizedBox(width: 10),
            Text(
              comment.name,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(width: 8),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  Icons.star,
                  size: 18,
                  color: i < comment.stars ? Colors.amber : Colors.grey[300],
                ),
              ),
            ),
            SizedBox(width: 4),
            Text(
              comment.stars.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColor.black,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Text(comment.text, style: Theme.of(context).textTheme.bodyMedium),
        SizedBox(height: 4),
        Text(
          comment.date,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColor.grey),
        ),
      ],
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String title;
  final String value;
  const _ProfileStat({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        SizedBox(height: 2),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColor.grey, fontSize: 13),
        ),
      ],
    );
  }
}

class _Comment {
  final String avatarUrl;
  final String name;
  final int stars;
  final String text;
  final String date;
  _Comment({
    required this.avatarUrl,
    required this.name,
    required this.stars,
    required this.text,
    required this.date,
  });
}

final List<_Comment> _mockComments = [
  _Comment(
    avatarUrl:
        'https://randomuser.me/api/portraits/men/2.jpg', // Jerome Bell (man)
    name: 'Jerome Bell',
    stars: 4,
    text:
        'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been',
    date: '4 days ago',
  ),
  _Comment(
    avatarUrl:
        'https://randomuser.me/api/portraits/women/1.jpg', // Annette Black (woman)
    name: 'Annette Black',
    stars: 4,
    text:
        'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been',
    date: '4 days ago',
  ),
  _Comment(
    avatarUrl:
        'https://randomuser.me/api/portraits/women/1.jpg', // Annette Black (woman)
    name: 'Annette Black',
    stars: 4,
    text:
        'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been',
    date: '4 days ago',
  ),
  _Comment(
    avatarUrl:
        'https://randomuser.me/api/portraits/women/1.jpg', // Annette Black (woman)
    name: 'Annette Black',
    stars: 4,
    text:
        'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been',
    date: '4 days ago',
  ),
  _Comment(
    avatarUrl:
        'https://randomuser.me/api/portraits/women/1.jpg', // Annette Black (woman)
    name: 'Annette Black',
    stars: 4,
    text:
        'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been',
    date: '4 days ago',
  ),
];
