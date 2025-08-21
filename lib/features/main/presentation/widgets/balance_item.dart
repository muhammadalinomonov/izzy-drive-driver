import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/assets/constants/icons.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/features/profile/presentation/blocs/profile_bloc.dart';

class BalanceItem extends StatelessWidget {
  const BalanceItem({super.key,  this.fromMain = true});
  final bool fromMain;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.fromLTRB(10, 8, 12, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: Colors.white,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                fromMain?AppIcons.diogram:AppIcons.wallet,
                height: 20,
                width: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  fromMain?'Today':'Wallet',
                  style: context.textTheme.titleSmall!.copyWith(color: gray4),
                ),
              ),
              Text(
                '\$${state.user.balance.isNotEmpty? state.user.balance : '0'}',
                style: context.textTheme.bodyMedium,
              )
            ],
          ),
        );
      },
    );
  }
}
