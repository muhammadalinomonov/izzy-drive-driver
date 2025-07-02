import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/components/app_snack_bar.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/widgets/app_button.dart';
import 'package:taxi_app/src/features/auth/presentation/widgets/auth_input_widget.dart';
import 'package:taxi_app/src/features/truck_info/data/source/driver_info_source.dart';
import 'package:taxi_app/src/features/truck_info/domain/model/track_model.dart';
import 'package:taxi_app/src/features/truck_info/presentation/bloc/bloc/track_info_bloc.dart';
import 'package:taxi_app/src/routes/pages.dart';
import 'package:shimmer/shimmer.dart';

class TrackInfoScreen extends StatefulWidget {
  const TrackInfoScreen({super.key});

  @override
  State<TrackInfoScreen> createState() => _TrackInfoScreenState();
}

class _TrackInfoScreenState extends State<TrackInfoScreen> {
  @override
  void initState() {
    super.initState();
    BlocProvider.of<TrackInfoBloc>(context).add(
      GetTrackMarskEvent(
        onError: () {
          AppSnackBar.showError(
            context,
            'Error occured while getting track marks',
          );
        },
      ),
    );
  }

  TruckMark? pickeDtruckMark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Image.asset(
                    'assets/images/gradient2.png',
                    fit: BoxFit.fill,
                    height: 600,
                  ),
                ),
                Expanded(
                  child: Image.asset(
                    'assets/images/gradient1.png',
                    fit: BoxFit.fill,
                    height: 600,
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          "Truck ma'lumotlari",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Truck ma'lumotlarini kirgizib qo'yishingizni tavsiya qilamiz! Bu sizni hisob-kitob olib yurishingizni yordam beradi!",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColor.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 28),
                        const Text(
                          "Truck rasmi",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade300,
                              style: BorderStyle.solid,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 48,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "Rasm qo'shish uchun bosing",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Truck markasi",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        BlocBuilder<TrackInfoBloc, TrackInfoState>(
                          builder: (context, state) {
                            return TruckDropDownWidget(
                              isLoading:
                                  state.status == TrackInfoStatus.loading,
                              value: state.truckMarkResponse?.data.first.name,
                              items:
                                  state.truckMarkResponse?.data.map((mark) {
                                    return DropdownMenuItem(
                                      value: mark.name,
                                      child: Text(mark.name),
                                    );
                                  }).toList() ??
                                  [],
                              onChanged: (value) {
                                pickeDtruckMark = TruckMark(
                                  id: 0,
                                  name: value.toString(),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Truck modeli",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TruckDropDownWidget(
                          value: null,
                          items: const [
                            DropdownMenuItem(value: "man", child: Text("MAN")),
                            DropdownMenuItem(
                              value: "volvo",
                              child: Text("Volvo"),
                            ),
                            DropdownMenuItem(value: "daf", child: Text("DAF")),
                          ],
                          onChanged: (value) {},
                        ),
                        const SizedBox(height: 20),
                        AuthInputWidget(
                          hint: 'Kiriting',
                          label: 'Ishlab chiqarilgan sana',
                        ),
                        const SizedBox(height: 32),
                        AppButton(title: "Ro'yxatdan o'tish", onTap: () {}),
                        const SizedBox(height: 16),
                        AppButton(
                          backGroundColor: AppColor.lightBlue,
                          textColor: AppColor.black,
                          title: "O'tkazib yuborish",
                          onTap: () {
                            context.go(Pages.chat);
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TruckDropDownWidget extends StatelessWidget {
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;
  final Widget? hint;
  final Widget? icon;
  final bool isExpanded;
  final bool isLoading;

  const TruckDropDownWidget({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.icon,
    this.isExpanded = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: hint ?? const Text("Tanlang"),
          items: items,
          onChanged: onChanged,
          isExpanded: isExpanded,
          icon: icon ?? const Icon(Icons.keyboard_arrow_down),
        ),
      ),
    );
  }
}
