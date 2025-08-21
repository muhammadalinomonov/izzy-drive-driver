import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/features/profile/presentation/blocs/profile_bloc.dart';

class WorkingStatus extends StatefulWidget {
  const WorkingStatus({super.key});

  @override
  State<WorkingStatus> createState() => _WorkingStatusState();
}

class _WorkingStatusState extends State<WorkingStatus> {
  bool isOnline = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (previous, current) => previous.user != current.user,
      listener: (context, state) {
        setState(() {
          isOnline = state.user.status != 'offline';
        });
      },
      builder: (context, state) => Container(
        padding: EdgeInsets.fromLTRB(10, 8, 0, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(3.8),
              height: 18,
              width: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isOnline ? green : red).withValues(alpha: .1),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? green : red,
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                isOnline ? 'Online' : 'Offline',
                style: context.textTheme.titleSmall,
              ),
            ),
            SizedBox(
              // width: 33,
              height: 20,
              child: Transform.scale(
                scale: 0.735,
                child: CupertinoSwitch(
                  value: isOnline,
                  onChanged: (value) {
                    // if (state.status == 'onwork') {
                    //   context.showPopUp(status: PopUpStatus.warning, message: 'Sizda hozirda aktiv buyurtma bor');
                    //   return;
                    // }
                    context.read<ProfileBloc>().add(UpdateStatusEvent(isOnline: !isOnline));
                    setState(() {
                      isOnline = value;
                    });
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
