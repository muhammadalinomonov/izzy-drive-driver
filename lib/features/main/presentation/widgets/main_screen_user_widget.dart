import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/assets/constants/icons.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/features/profile/presentation/blocs/profile_bloc.dart';
import 'package:mechanic/features/profile/presentation/widgets/circular_avatar_widget.dart';

class MainScreenUserWidget extends StatelessWidget {
  const MainScreenUserWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: white,
          ),
          child: Row(
            children: [
              CircularAvatarWidget(),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello',
                      style: context.textTheme.bodySmall!.copyWith(color: gray4),
                    ),
                    SizedBox(height: 4),
                    Text(
                      state.user.fullName,
                      style: context.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              SvgPicture.asset(AppIcons.chevronRight),
            ],
          ),
        );
      },
    );
  }
}
