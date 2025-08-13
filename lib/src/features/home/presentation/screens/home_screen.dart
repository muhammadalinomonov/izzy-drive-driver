import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';
import 'package:taxi_app/src/features/home/presentation/bloc/bloc/home_bloc.dart';
import 'package:taxi_app/src/features/home/presentation/widgets/comment_section_modal_sheet.dart';
import 'package:taxi_app/src/features/choose_inivates/presentation/widgets/profile_order_model_sheet.dart';
import 'package:taxi_app/src/features/home/presentation/widgets/search_input.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:taxi_app/src/routes/pages.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    BlocProvider.of<HomeBloc>(context).add(GetBannersEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  SearchInputWidget(hint: 'Usta qayerga borsin ?', textInputAction: TextInputAction.search,),
                  SizedBox(height: 12),
                  LastLocationWidget(),
                  SizedBox(height: 12),
                  LastLocationWidget(),
                ],
              ),
            ),
            SizedBox(height: 20),
            OtherOpportunitiesWidget(),
            SizedBox(height: 25),
            BannerWidget(),
           
          ],
        ),
      ),
    );
  }
}

class BannerWidget extends StatelessWidget {
  const BannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state.status == HomeStatus.loading) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 340,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        } else if (state.status == HomeStatus.error) {
          return SizedBox(
            height: 140,
            child: Swiper(
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 340,
                      height: 140,
                      color: Colors.grey[300],
                      child: Center(child: Text(state.errorMessage)),
                    ),
                  ),
                );
              },
              itemCount: 2,
              autoplay: true,
              viewportFraction: 1.0,
              scale: 0.95,
            ),
          );
        } else {
          return SizedBox(
            height: 140,
            child: Swiper(
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      state.banners[index]['image'],
                      fit: BoxFit.cover,
                      width: 340,
                      errorBuilder:
                          (
                            BuildContext context,
                            Object exception,
                            StackTrace? stackTrace,
                          ) {
                            return Container(
                              width: 340,
                              height: 140,
                              color: Colors.grey[300],
                              child: Center(child: Icon(Icons.error)),
                            );
                          },
                      loadingBuilder:
                          (
                            BuildContext context,
                            Widget child,
                            ImageChunkEvent? loadingProgress,
                          ) {
                            if (loadingProgress == null) return child;
                            return Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                width: 340,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(child: Icon(Icons.error)),
                              ),
                            );
                          },
                    ),
                  ),
                );
              },
              itemCount: state.banners.length,
              autoplay: true,
              viewportFraction: 1.0,
              scale: 0.95,
            ),
          );
        }
      },
    );
  }
}

class LastLocationWidget extends StatelessWidget {
  const LastLocationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(Pages.map),
      child: Container(
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
      ),
    );
  }
}

// New widget for 'Boshqa imkoniyatlar'
class OtherOpportunitiesWidget extends StatelessWidget {
  const OtherOpportunitiesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Boshqa imkoniyatlar',
            style: context.textS.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _OpportunityCard(
                icon: 'assets/images/food.png',
                label: 'Food',
                soon: true,
              ),
              SizedBox(width: 8),
              _OpportunityCard(
                icon: 'assets/images/deliver.png',
                label: 'Yetkazish',
                soon: true,
              ),
              SizedBox(width: 8),
              _OpportunityCard(
                icon: 'assets/images/grocery.png',
                label: 'Grocery',
                soon: true,
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              _OpportunityCard(
                icon: 'assets/images/activities.png',
                label: 'Activities',
                soon: true,
                isLarge: true,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    _GymCard(
                      image: 'assets/images/gym.png',
                      name: 'Gym 1.8 elite',
                      distance: '1.8 km',
                    ),
                    SizedBox(height: 8),
                    _GymCard(
                      image: 'assets/images/cardio.png',
                      name: 'Cardio Elite',
                      distance: '1.8 km',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  final String icon;
  final String label;
  final bool soon;
  final bool isLarge;

  const _OpportunityCard({
    required this.icon,
    required this.label,
    this.soon = false,
    this.isLarge = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: isLarge ? 100 : 80,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Use Image.asset for local images
                  Image.asset(
                    icon,
                    width: isLarge ? 48 : 36,
                    height: isLarge ? 48 : 36,
                  ),
                  SizedBox(height: 8),
                  Text(label, style: context.textS.labelLarge),
                ],
              ),
            ),
            if (soon)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[200],
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    'SOON',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GymCard extends StatelessWidget {
  final String image;
  final String name;
  final String distance;

  const _GymCard({
    required this.image,
    required this.name,
    required this.distance,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(image, width: 48, height: 48, fit: BoxFit.cover),
          ),
          SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: context.textS.labelLarge),
              Text(distance, style: context.textS.labelMedium),
            ],
          ),
        ],
      ),
    );
  }
}
