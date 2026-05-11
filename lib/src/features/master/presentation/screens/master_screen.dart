import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/common_image.dart';
import 'package:taxi_app/src/features/master/data/model/master_model.dart';
import 'package:taxi_app/src/features/master/presentation/bloc/master_bloc.dart';
import 'package:taxi_app/src/features/master/presentation/screens/master_detail_sheet.dart';

class MasterScreen extends StatefulWidget {
  const MasterScreen({super.key});

  @override
  State<MasterScreen> createState() => _MasterScreenState();
}

class _MasterScreenState extends State<MasterScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // `didChangeDependencies` can fire multiple times (locale/theme changes,
    // bottom-tab re-activation); we want a silent refresh on those re-fires.
    // The first invocation has no master data yet, so the bloc still emits
    // `loading` to render the initial shimmer.
    BlocProvider.of<MasterBloc>(context).add(MasterFetch(silent: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Masters'.tr(),
          style: context.textS.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w500),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {},
            icon: SvgPicture.asset(AppIcons.bell, width: 24, height: 24),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BlocBuilder<MasterBloc, MasterState>(
              buildWhen: (p, c) => p.currentAddress != c.currentAddress,
              builder: (context, state) => _AddressPill(
                address: state.currentAddress ?? 'No location found'.tr(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<MasterBloc, MasterState>(
                builder: (context, state) {
                  if (state.status == MasterStatus.loading) {
                    return const _MastersGridSkeleton();
                  } else if (state.status == MasterStatus.success) {
                    if (state.masters.isEmpty) {
                      return RefreshIndicator.adaptive(
                        onRefresh: () async {
                          context.read<MasterBloc>().add(MasterFetch());
                        },
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            _MastersEmptyState(),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator.adaptive(
                      onRefresh: () async {
                        // Pull-to-refresh: keep the existing grid visible while
                        // the user sees the platform refresh spinner.
                        context.read<MasterBloc>().add(MasterFetch(silent: true));
                      },
                      child: GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 190,
                        ),
                        itemCount: state.masters.length,
                        itemBuilder: (context, index) {
                          return _MasterCard(master: state.masters[index]);
                        },
                      ),
                    );
                  } else if (state.status == MasterStatus.failure) {
                    return RefreshIndicator.adaptive(
                      onRefresh: () async {
                        // Pull-to-refresh: keep the existing grid visible while
                        // the user sees the platform refresh spinner.
                        context.read<MasterBloc>().add(MasterFetch(silent: true));
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          _MastersErrorState(message: state.error),
                        ],
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressPill extends StatelessWidget {
  const _AddressPill({required this.address});
  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColor.lightBlue,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          SvgPicture.asset(AppIcons.location, width: 16, height: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              address,
              style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MasterCard extends StatelessWidget {
  final MasterModel master;
  const _MasterCard({required this.master});

  @override
  Widget build(BuildContext context) {
    final ratingValue = master.rating;
    return Container(
      decoration: BoxDecoration(
        color: AppColor.lightBlue,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        children: [
          SizedBox(
            width: 60,
            height: 47,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                AvatarImage(
                  imageUrl: master.photo ?? '',
                  size: 44,
                ),
                if (ratingValue != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(AppIcons.star, width: 9, height: 9),
                          const SizedBox(width: 2),
                          Text(
                            ratingValue.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Mechanic'.tr(),
            style: TextStyle(fontSize: 12, color: AppColor.grey),
          ),
          const SizedBox(height: 6),
          Text(
            master.fullName ?? '',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            master.experience != null
                ? '${master.experience} ${"years experience".tr()}'
                : '',
            style: TextStyle(fontSize: 12, color: AppColor.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              final bloc = context.read<MasterBloc>();
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (ctx) {
                  return BlocProvider.value(
                    value: bloc,
                    child: MasterDetailSheet(id: master.id ?? 0),
                  );
                },
              );
            },
            child: Container(
              width: double.infinity,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                'More'.tr(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MastersGridSkeleton extends StatelessWidget {
  const _MastersGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEFF3F6),
      highlightColor: const Color(0xFFF7F9FB),
      period: const Duration(milliseconds: 1400),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 190,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEFF3F6),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}

class _MastersEmptyState extends StatelessWidget {
  const _MastersEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.engineering_outlined, size: 60, color: AppColor.grey),
          const SizedBox(height: 16),
          Text(
            'No masters found'.tr(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'There are no masters available near you right now. Pull down to refresh.'.tr(),
              style: TextStyle(color: AppColor.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _MastersErrorState extends StatelessWidget {
  const _MastersErrorState({this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'An error occurred'.tr(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message?.isNotEmpty == true ? message! : 'Something went wrong. Pull down to try again.'.tr(),
              style: TextStyle(color: AppColor.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          MaterialButton(
            onPressed: () => context.read<MasterBloc>().add(MasterFetch()),
            color: AppColor.blueMain,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: Text(
              'Try again'.tr(),
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
