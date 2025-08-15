import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/features/profile/presentation/blocs/profile_bloc.dart';
import 'package:shimmer/shimmer.dart';

class OrderActionButtons extends StatelessWidget {
  const OrderActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state.status == 'onwork') {
          return Container(
            padding: EdgeInsets.only(right: 12, left: 12, top: 16, bottom: MediaQuery.paddingOf(context).bottom + 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              color: white,
              boxShadow: [
                BoxShadow(
                  color: black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: Offset(0, -4), // changes position of shadow
                ),
              ],
            ),
            child: SwipeButton(
              activeThumbColor: mainColor,
              inactiveThumbColor: Colors.amber,
              inactiveTrackColor: Colors.red,
              activeTrackColor: aliceBlue,
              thumbPadding: EdgeInsets.all(3),
              thumb: Icon(
                Icons.chevron_right,
                color: white,
              ),
              elevationThumb: 0,
              elevationTrack: 0,
              child: Shimmer.fromColors(
                baseColor: prussianBlue,
                highlightColor: perano,
                child: Text(
                  'Ishni yakunlash',
                  style: context.textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
              onSwipe: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Swipped"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          );
        } else {
          return SizedBox();
        }
      },
    );
  }
}
