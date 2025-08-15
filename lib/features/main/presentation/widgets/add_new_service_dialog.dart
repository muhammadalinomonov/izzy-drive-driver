import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/features/common/presentation/widgets/common_button.dart';
import 'package:mechanic/features/common/presentation/widgets/common_text_field.dart';
import 'package:mechanic/features/main/presentation/blocs/orders/orders_bloc.dart';

class AddNewServiceDialog extends StatefulWidget {
  const AddNewServiceDialog({super.key});

  @override
  _AddNewServiceDialogState createState() => _AddNewServiceDialogState();
}

class _AddNewServiceDialogState extends State<AddNewServiceDialog> {
  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _servicePriceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: BlocConsumer<OrdersBloc, OrdersState>(
        listenWhen: (previous, current) => previous.addNewServiceStatus != current.addNewServiceStatus,
        listener: (context, state) {
          if (state.addNewServiceStatus.isSuccess) {
            context.read<OrdersBloc>().add(GetCurrentOrderEvent());
            context.showPopUp(status: PopUpStatus.success, message: 'Xizmat muvaffaqiyatli jo\'natildi.');
            Navigator.pop(context);
          } else if (state.addNewServiceStatus.isFailure) {
            context.showPopUp(status: PopUpStatus.error, message: 'Xizmatni jo\'natishda xatolik yuz berdi.');
          }
        },
        builder: (context, state) {
          return Container(
            width: MediaQuery.of(context).size.width * 0.89,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.only(left: 18, top: 12, right: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Yangi xizmat',
                        style: context.textTheme.bodyMedium!.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: gray1,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.grey[600],
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yangi xizmat qo’shganingizdan keyin, haydovchi uni tasdiqlashi kerak bo’ladi.',
                        style: context.textTheme.bodyMedium!.copyWith(
                          fontSize: 14,
                          color: gray4,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Xizmat nomi',
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CommonTextField(
                        controller: _serviceNameController,
                        hint: 'Kiriting',
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Xizmat narxi',
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CommonTextField(
                        controller: _servicePriceController,
                        hint: 'Kiriting',
                        suffixIcon: Text(
                          '\$',
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      CommonButton(
                        isLoading: state.addNewServiceStatus.isInProgress,
                        isDisabled: state.addNewServiceStatus.isInProgress,
                        text: 'Qo’shish',
                        onTap: () {
                          context.read<OrdersBloc>().add(AddNewServiceEvent(
                              serviceName: _serviceNameController.text,
                              servicePrice: double.tryParse(_servicePriceController.text) ?? 0.0));
                        },
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _servicePriceController.dispose();
    super.dispose();
  }
}
