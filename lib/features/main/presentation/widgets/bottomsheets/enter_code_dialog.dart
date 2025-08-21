import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:formz/formz.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/assets/constants/icons.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/features/common/presentation/widgets/common_button.dart';
import 'package:mechanic/features/main/presentation/blocs/orders/orders_bloc.dart';
import 'package:mechanic/features/profile/presentation/pages/order_history_single_screen.dart';

class EnterOrderDialog extends StatefulWidget {
  const EnterOrderDialog({super.key, required this.orderId});

  final int orderId;

  @override
  _EnterOrderDialogState createState() => _EnterOrderDialogState();
}

class _EnterOrderDialogState extends State<EnterOrderDialog> {
  String code = '';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: BlocConsumer<OrdersBloc, OrdersState>(
        listenWhen: (previous, current) => previous.changeOrderStatus != current.changeOrderStatus,
        listener: (context, state) {
          if (state.changeOrderStatus.isSuccess) {
            Navigator.of(context).push(CupertinoPageRoute(builder: (context) => OrderHistorySingleScreen(orderId: widget.orderId, fromHistory: false)));
          } else if (state.changeOrderStatus.isFailure) {
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
                Container(
                  padding: const EdgeInsets.only(left: 18, top: 12, right: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(context).pop(),
                        child: SvgPicture.asset(
                          AppIcons.arrowBack,
                          width: 24,
                          height: 24,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Kod orqali',
                        style: context.textTheme.bodyMedium!.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
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
                        'Yakunlash uchun kodni kiriting',
                        style: context.textTheme.bodyMedium!.copyWith(
                          fontSize: 14,
                          color: gray4,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Kodni kiriting',
                        style: context.textTheme.bodyMedium!.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width,
                        child: OtpTextField(
                          fieldWidth: 42,
                          fieldHeight: 42,
                          numberOfFields: 5,
                          borderColor: mainColor,
                          focusedBorderColor: mainColor,
                          filled: true,
                          fillColor: solitude,
                          cursorColor: mainColor,
                          decoration: InputDecoration(
                            hintText: '0',
                            // hint: Text('-'),
                            hintStyle: context.textTheme.bodySmall!
                                .copyWith(color: gray6, fontWeight: FontWeight.w400, fontSize: 16),
                          ),
                          borderRadius: BorderRadius.circular(12),
                          showFieldAsBox: true,
                          onCodeChanged: (String code) {
                            this.code = code;
                          },
                          onSubmit: (String verificationCode) {}, // end onSubmit
                        ),
                      ),
                      SizedBox(height: 24),
                      CommonButton(
                        text: 'Qo’shish',
                        onTap: () {
                          context
                              .read<OrdersBloc>()
                              .add(ChangeOrderStatusEvent(orderId: widget.orderId, status: 'completed', code: code));
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
    super.dispose();
  }
}
