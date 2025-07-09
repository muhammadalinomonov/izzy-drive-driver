import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';
import 'package:taxi_app/src/features/home/presentation/widgets/search_input.dart';
import 'package:card_swiper/card_swiper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final List<String> imgList = [
      'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8Z3ltfGVufDB8fDB8fHww',
      'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=900&auto=format&fit=crop&q=60',
      'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?w=900&auto=format&fit=crop&q=60',
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Asosiy',
          style: context.textS.titleLarge?.copyWith(fontSize: 20),
        ),
        centerTitle: false,
        actions: [
          IconButton(onPressed: () {}, icon: SvgPicture.asset(AppIcons.bell)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),

            child: Column(
              children: [
                SearchInputWidget(hint: 'Usta qayerga borsin ?'),
                SizedBox(height: 12),
                LastLocationWidget(),
                SizedBox(height: 12),
                LastLocationWidget(),
              ],
            ),
          ),
          SizedBox(height: 20),

          SizedBox(
            height: 140,
            child: Swiper(
              autoplayDelay: 1,

              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imgList[index],
                      fit: BoxFit.cover,
                      width: 340,
                    ),
                  ),
                );
              },
              itemCount: imgList.length,
              autoplay: true,
              viewportFraction: 1.0,
              scale: 0.95,
            ),
          ),
        ],
      ),
    );
  }
}

class LastLocationWidget extends StatelessWidget {
  const LastLocationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 55,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 19, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.grey, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(AppIcons.pending),
          SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Evos chilonzor'),
              Text(
                '2972 Westheimer Rd. Santa Ana, Illinois 85486',
                style: context.textS.labelMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
