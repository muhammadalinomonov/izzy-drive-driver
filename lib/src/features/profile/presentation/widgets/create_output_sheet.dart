import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';
import 'package:taxi_app/src/core/utils/my_functions.dart';
import 'package:taxi_app/src/features/profile/presentation/bloc/profile_bloc.dart';

import '../../../common/presentation/widgets/common_bottom_sheet.dart';

class CreateOutputSheet extends StatefulWidget {
  const CreateOutputSheet({super.key});

  @override
  State<CreateOutputSheet> createState() => _CreateOutputSheetState();
}

class _CreateOutputSheetState extends State<CreateOutputSheet> {
  late TextEditingController titleController;
  late TextEditingController amountController;

  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController();
    amountController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          return CommonBottomSheet(
            isLoading: state.createOutputStatus.isInProgress,
            onSave: () {
              if (selectedDate == null && titleController.text.isEmpty && amountController.text.isEmpty) {
                return;
              }
              final now = DateTime.now();
              final date = selectedDate?.copyWith(hour: now.hour, minute: now.minute, second: now.second) ?? now;

              context.read<ProfileBloc>().add(
                CreateOutputEvent(
                  title: titleController.text,
                  amount: amountController.text,
                  date: date.toString(),
                  onSuccess: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Expense added successfully'), backgroundColor: Colors.green),
                    );
                    Navigator.of(context).pop();
                  },
                  onError: (String p1) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(p1), backgroundColor: Colors.red));
                  },
                ),
              );
            },
            title: 'Add expense',
            children: [
              SizedBox(height: 12),
              Text(
                'Expense name',
                style: context.textTheme.headlineLarge!.copyWith(fontSize: 13, fontWeight: FontWeight.w400),
              ),
              SizedBox(height: 8),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColor.blueMain),
                  ),
                  fillColor: AppColor.lightBlue,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColor.lightBlue),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  hintText: 'Enter expense name',
                  hintStyle: context.textTheme.headlineLarge!.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text('Date', style: context.textTheme.headlineLarge!.copyWith(fontSize: 13, fontWeight: FontWeight.w400)),
              SizedBox(height: 8),
              Container(
                height: 48,
                decoration: BoxDecoration(color: AppColor.lightBlue, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    SizedBox(width: 12),
                    Text(
                      selectedDate != null
                          ? MyFunctions.formatDateTime(selectedDate.toString(), format: 'dd.MM.yyyy')
                          : 'Select date',
                      style: context.textTheme.headlineLarge!.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: selectedDate == null ? Colors.grey : null,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () async {
                        final now = DateTime.now();
                        final result = await showDatePicker(
                          context: context,
                          firstDate: DateTime(now.year, 1, 1),
                          lastDate: now,
                        );
                        if (result != null) {
                          setState(() {
                            selectedDate = result;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Amount',
                style: context.textTheme.headlineLarge!.copyWith(fontSize: 13, fontWeight: FontWeight.w400),
              ),
              SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColor.blueMain),
                  ),
                  fillColor: AppColor.lightBlue,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColor.lightBlue),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  hintText: 'Enter amount',
                  hintStyle: context.textTheme.headlineLarge!.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
