import 'package:flutter/material.dart';
import 'package:formz/formz.dart';

class Paginator extends StatelessWidget {
  const Paginator({
    super.key,
    required this.status,
    required this.hasMoreReach,
    required this.onLoadMore,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
    required this.itemCount,
    required this.separator,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
    this.onRefresh,
  });

  final FormzSubmissionStatus status;
  final bool hasMoreReach;
  final VoidCallback onLoadMore;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;
  final int itemCount;
  final Widget Function(BuildContext context, int index) separator;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsets padding;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      if (itemCount == 0 && status.isSuccess) {
        if (emptyWidget != null) {
          // Empty state Stack ichida — eng tagga qo'yiladi va qimirlamaydi.
          // Ustida transparent ListView pull-to-refresh gesturlarini qabul
          // qiladi, lekin uning ichi bo'sh shaffof bo'lgani sabab user
          // hech qanday vizual o'zgarishni ko'rmaydi — faqat spinner.
          return Stack(
            children: [
              Positioned.fill(
                child: Center(child: emptyWidget!),
              ),
              RefreshIndicator.adaptive(
                onRefresh: onRefresh ?? () async {},
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [SizedBox(height: 1)],
                ),
              ),
            ],
          );
        }
      } else if (status.isInProgress) {
        return loadingWidget ?? Center(child: CircularProgressIndicator.adaptive());
      } else if (status.isFailure) {
        if (errorWidget != null) {
          return RefreshIndicator.adaptive(
            onRefresh: onRefresh ?? () async {},
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding:EdgeInsets.only(top: MediaQuery.sizeOf(context).height/3 ),
                child: errorWidget!,
              ),
            ),
          );
        }
      }

      if (status.isSuccess) {
        return RefreshIndicator.adaptive(
          onRefresh: onRefresh ?? () async {},
          child: ListView.separated(
            padding: padding,
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              if (index == itemCount && hasMoreReach) {
                onLoadMore.call();
                return Center(child: CircularProgressIndicator.adaptive());
              }
              return itemBuilder.call(context, index);
            },
            separatorBuilder: (context, index) {
              return separator.call(context, index);
            },
            itemCount: itemCount + (hasMoreReach ? 1 : 0),
          ),
        );
      } else {
        return SizedBox();
      }
    });
  }
}
