import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';
import 'package:taxi_app/src/core/utils/my_functions.dart';
import 'package:taxi_app/src/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:taxi_app/src/features/profile/presentation/widgets/create_output_sheet.dart';
import 'package:taxi_app/src/features/profile/presentation/widgets/output_item.dart';

class OutputsScreen extends StatefulWidget {
  const OutputsScreen({super.key});

  @override
  State<OutputsScreen> createState() => _OutputsScreenState();
}

class _OutputsScreenState extends State<OutputsScreen> {
  @override
  void initState() {
    super.initState();

    context.read<ProfileBloc>().add(GetOutputsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber,
      body: SizedBox(
        width: context.sizeOf.width,
        height: context.sizeOf.height,
        child: Stack(
          children: [
            Image.asset('assets/images/truck_image.png', width: context.sizeOf.width, height: 296, fit: BoxFit.cover),

            Container(
              margin: EdgeInsets.only(left: 12, top: context.padding.top),
              // padding: EdgeInsets.all(value),
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColor.black.withValues(alpha: .2)),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: AppColor.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              top: 250,
              bottom: 0,
              child: Container(
                width: context.sizeOf.width,
                padding: EdgeInsets.only(top: 24, left: 16, right: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  color: Colors.white,
                ),
                child: BlocBuilder<ProfileBloc, ProfileState>(
                  builder: (context, state) {
                    if (state.outputsStatus.isInProgress) {
                      return Center(child: CircularProgressIndicator.adaptive());
                    }
                    if (state.outputsStatus.isSuccess) {
                      return Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Expenses',
                                style: context.textTheme.headlineLarge!.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4),
                                child: GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
                                      isScrollControlled: true,
                                      context: context,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => CreateOutputSheet(),
                                    );
                                  },
                                  child: Text(
                                    'Add expense',
                                    style: context.textTheme.headlineLarge!.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColor.blueMain,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),

                          Expanded(
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              itemBuilder: (context, index) {
                                final output = state.outputs[index];
                                return OutputItem(
                                  title: output.title,
                                  date: MyFunctions.formatDateTime(output.createdAt),
                                  price: '\$${output.amount}',
                                );
                              },
                              separatorBuilder: (context, index) => Divider(color: AppColor.lightBlue),
                              itemCount: state.outputs.length,
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(bottom: context.padding.bottom),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Color(0xffE0F0FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Total expenses',
                                  style: context.textTheme.headlineLarge!.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: AppColor.darkBlue,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  '\$${state.totalAmount}',
                                  style: context.textTheme.headlineLarge!.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColor.blueMain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      return SizedBox();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
