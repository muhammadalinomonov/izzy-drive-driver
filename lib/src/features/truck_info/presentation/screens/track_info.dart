import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/widgets/app_button.dart';
import 'package:taxi_app/src/features/auth/presentation/widgets/auth_input_widget.dart';
import 'package:taxi_app/src/features/truck_info/data/source/driver_info_source.dart';

class TrackInfoScreen extends StatefulWidget {
  const TrackInfoScreen({super.key});

  @override
  State<TrackInfoScreen> createState() => _TrackInfoScreenState();
}

class _TrackInfoScreenState extends State<TrackInfoScreen> {
  @override
  void initState() {
    super.initState();
    DriverInfoSource().getTrackMars();
    DriverInfoSource().getTrackModel('2');
  }

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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: null,
                              hint: const Text("Tanlang"),
                              items: const [
                                DropdownMenuItem(
                                  value: "man",
                                  child: Text("MAN"),
                                ),
                                DropdownMenuItem(
                                  value: "volvo",
                                  child: Text("Volvo"),
                                ),
                                DropdownMenuItem(
                                  value: "daf",
                                  child: Text("DAF"),
                                ),
                              ],
                              onChanged: (value) {},
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down),
                            ),
                          ),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: null,
                              hint: const Text("Tanlang"),
                              items: const [
                                DropdownMenuItem(
                                  value: "model1",
                                  child: Text("Model 1"),
                                ),
                                DropdownMenuItem(
                                  value: "model2",
                                  child: Text("Model 2"),
                                ),
                                DropdownMenuItem(
                                  value: "model3",
                                  child: Text("Model 3"),
                                ),
                              ],
                              onChanged: (value) {},
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down),
                            ),
                          ),
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
                          onTap: () {},
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
