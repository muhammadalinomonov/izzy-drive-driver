import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/bloc/orders_bloc.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/order_info_card.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/qr_code_dialog.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/sub_orders_card.dart';

class FinishedOrderScreen extends StatefulWidget {
  const FinishedOrderScreen({super.key});

  @override
  State<FinishedOrderScreen> createState() => _FinishedOrderScreenState();
}

class _FinishedOrderScreenState extends State<FinishedOrderScreen> {
  TextEditingController commentController = TextEditingController();
  int selectedStar = 5;

  final List<String> comments = ['Yaxshi', 'Alo', 'Yomon'];
  String? selectedComment = '';

  @override
  void initState() {
    super.initState();

    context.read<OrdersBloc>().add(ConnectToWebSocketEvent());
    selectedComment = comments[0];
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismisser(
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final mechanic = context.read<OrdersBloc>().state.currentOrder.selectedMechanic.id;
            context.read<OrdersBloc>()
              ..add(
                RateMasterEvent(
                  star: selectedStar + 1,
                  comment: selectedComment ?? commentController.text,
                  mechanicId: mechanic,
                ),
              )
              ..add(
                DoneCurrentOrderEvent(
                  onSuccess: (code) {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) {
                        return BookingSuccessDialog(bookingCode: code.toString(), qrData: code.toString());
                      },
                    );
                  },
                ),
              );
          },
          child: Container(
            margin: EdgeInsets.only(left: 16, right: 16),
            width: context.sizeOf.width,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), color: AppColor.blueMain),
            padding: EdgeInsets.symmetric(vertical: 13),
            child: Text(
              'Yakunlash',
              style: context.textTheme.bodyLarge!.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColor.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        backgroundColor: AppColor.lightBlue,
        body: BlocBuilder<OrdersBloc, OrdersState>(
          builder: (context, state) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: context.sizeOf.width,
                    padding: EdgeInsets.only(top: context.padding.top + 18, right: 27, left: 27, bottom: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                      color: AppColor.white,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(AppIcons.check, width: 50, height: 50),
                        SizedBox(height: 18),
                        Text(
                          'Muvaffaqiyatli yakunlandi!',
                          style: context.textTheme.bodyMedium!.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Iltimos, ustani baholang, bu bizni yanada yaxshiroq bo’lishimizga yordam beradi!',
                          style: context.textTheme.bodySmall!.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColor.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    width: context.sizeOf.width,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColor.white),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Baholang',
                          style: context.textTheme.bodyMedium!.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            5,
                            (index) => GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  selectedStar = index;
                                });
                              },
                              child: Padding(
                                padding: EdgeInsets.only(right: index == 4 ? 0 : 8),
                                child: SvgPicture.asset(
                                  AppIcons.star,
                                  width: 32,
                                  height: 32,
                                  colorFilter: ColorFilter.mode(
                                    index > selectedStar ? AppColor.lightGreyBlue : AppColor.yellow,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 18),
                        Wrap(
                          children: [
                            ...List.generate(
                              comments.length,
                              (index) => GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setState(() {
                                    selectedComment = comments[index];
                                  });
                                },
                                child: Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: comments[index] != selectedComment
                                          ? AppColor.lightBlue
                                          : AppColor.blueMain,
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Text(
                                      comments[index],
                                      style: context.textTheme.bodyLarge!.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: comments[index] == selectedComment ? AppColor.white : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  selectedComment = null;
                                });
                              },
                              child: Padding(
                                padding: EdgeInsets.only(right: 0),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selectedComment == null ? AppColor.blueMain : AppColor.lightBlue,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Text(
                                    'Izoh qoldirish',
                                    style: context.textTheme.bodyLarge!.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: selectedComment == null ? AppColor.white : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        if (selectedComment == null)
                          TextField(
                            maxLines: 3,
                            controller: commentController,
                            onChanged: (value) {},
                            decoration: InputDecoration(
                              hintText: 'Izoh qoldirish',
                              hintStyle: context.textTheme.bodyLarge!.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColor.grey,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColor.lightBlue),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColor.lightBlue),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColor.lightBlue),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColor.kPrimaryColor),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        SizedBox(height: 18),
                        Row(
                          children: [
                            if (state.currentOrder.selectedMechanic.photo.isNotEmpty)
                              Image.network(
                                state.currentOrder.selectedMechanic.photo,
                                width: 44,
                                height: 44,
                                errorBuilder: (context, error, stackTrace) => SizedBox(),
                              ),
                            Text(
                              state.currentOrder.selectedMechanic.fullName,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: AppColor.lightBlue,
                              ),
                              child: Text(
                                'More',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  OrderInfoCard(currentOrder: state.currentOrder),
                  SizedBox(height: 8),
                  SubOrdersCard(currentOrder: state.currentOrder),
                  SizedBox(height: context.padding.bottom + 58),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
