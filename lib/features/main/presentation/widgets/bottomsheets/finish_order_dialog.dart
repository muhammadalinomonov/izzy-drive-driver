import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:formz/formz.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/assets/constants/icons.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/features/main/presentation/blocs/orders/orders_bloc.dart';
import 'package:mechanic/features/main/presentation/screens/qr_code_screen.dart';
import 'package:mechanic/features/main/presentation/widgets/bottomsheets/enter_code_dialog.dart';

class FinishOrderDialog extends StatefulWidget {
  const FinishOrderDialog({super.key, required this.orderId});

  final int orderId;

  @override
  _FinishOrderDialogState createState() => _FinishOrderDialogState();
}

class _FinishOrderDialogState extends State<FinishOrderDialog> {
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
                Container(
                  padding: const EdgeInsets.only(left: 18, top: 12, right: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Yakunlash',
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
                        'Yakunlash uchun kodni kiriting yoki QRni skaner qilish!',
                        style: context.textTheme.bodyMedium!.copyWith(
                          fontSize: 14,
                          color: gray4,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(CupertinoPageRoute(builder: (context) => QrCodeScreen()));
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18), border: BoxBorder.all(color: grayLine)),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SvgPicture.asset(AppIcons.qrCode),
                                    SizedBox(height: 8),
                                    Text(
                                      'Skaner qilish',
                                      style: context.textTheme.bodyMedium!.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 18),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (BuildContext context) {
                                    return EnterOrderDialog(orderId: widget.orderId);
                                  },
                                );
                              },
                              child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18), border: BoxBorder.all(color: grayLine)),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SvgPicture.asset(AppIcons.edit),
                                      SizedBox(height: 8),
                                      Text(
                                        'Kodni kiritish',
                                        style: context.textTheme.bodyMedium!.copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  )),
                            ),
                          ),
                        ],
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
