import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/location_service.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/common_image.dart';
import 'package:taxi_app/src/features/master/data/repository/master_repository_impl.dart';
import 'package:taxi_app/src/features/master/data/source/master_remote_data_source.dart';
import 'package:taxi_app/src/features/master/presentation/bloc/master_bloc.dart';
import 'package:taxi_app/src/features/master/presentation/screens/master_detail_sheet.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/bloc/orders_bloc.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/order_info_card.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/qr_code_dialog.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/sub_orders_card.dart';
import 'package:taxi_app/src/routes/pages.dart';

class FinishedOrderScreen extends StatefulWidget {
  const FinishedOrderScreen({super.key});

  @override
  State<FinishedOrderScreen> createState() => _FinishedOrderScreenState();
}

class _FinishedOrderScreenState extends State<FinishedOrderScreen>
    with TickerProviderStateMixin {
  final TextEditingController commentController = TextEditingController();
  // 0 = hech qaysi yulduz tanlanmagan. Mobile'da `star + 1` yuborilmaydi —
  // foydalanuvchi tanlagan qiymat to'g'ridan-to'g'ri 1..5.
  int selectedStar = 0;
  // Tag (Good / Excellent / Bad) — comment'dan ALOHIDA, parallel ishlaydi.
  String? selectedTag;
  bool _commentExpanded = false;

  late final AnimationController _checkAnim;
  late final AnimationController _ringAnim;

  static const List<String> _tagOptions = ['Good', 'Excellent', 'Bad'];

  @override
  void initState() {
    super.initState();
    context.read<OrdersBloc>().add(ConnectToWebSocketEvent());
    _checkAnim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    )..forward();
    _ringAnim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    commentController.dispose();
    _checkAnim.dispose();
    _ringAnim.dispose();
    super.dispose();
  }

  void _submit() {
    final mechanic = context.read<OrdersBloc>().state.currentOrder.selectedMechanic.id;
    context.read<OrdersBloc>()
      ..add(RateMasterEvent(
        star: selectedStar > 0 ? selectedStar : 5,
        comment: commentController.text,
        tag: selectedTag,
        mechanicId: mechanic,
      ))
      ..add(DoneCurrentOrderEvent(
        onSuccess: (code) {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (_) => BookingSuccessDialog(
              bookingCode: code.toString(), qrData: code.toString(),
            ),
          );
        },
      ));
  }

  void _openMasterDetail() {
    final mechanic = context.read<OrdersBloc>().state.currentOrder.selectedMechanic;
    final bloc = MasterBloc(
      MasterRepositoryImpl(MasterRemoteDataSource()), LocationService(),
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: bloc, child: MasterDetailSheet(id: mechanic.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismisser(
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _submit,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: context.sizeOf.width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: AppColor.blueMain,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              'Complete'.tr(),
              style: context.textTheme.bodyLarge!.copyWith(
                fontSize: 16, fontWeight: FontWeight.w600, color: AppColor.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        backgroundColor: AppColor.lightBlue,
        body: BlocListener<OrdersBloc, OrdersState>(
          listenWhen: (p, c) =>
              p.lifecycleEvent != c.lifecycleEvent &&
              c.lifecycleEvent == OrderLifecycleEvent.completed,
          listener: (context, state) {
            context.read<OrdersBloc>().add(ClearLifecycleEventEvent());
            Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
            context.go(Pages.main);
          },
          child: BlocBuilder<OrdersBloc, OrdersState>(
            builder: (context, state) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SuccessHeader(checkAnim: _checkAnim, ringAnim: _ringAnim),
                    _RateCard(
                      selectedStar: selectedStar,
                      onStarTap: (i) => setState(() => selectedStar = i),
                      tagOptions: _tagOptions,
                      selectedTag: selectedTag,
                      onTagTap: (t) => setState(() {
                        selectedTag = (selectedTag == t) ? null : t;
                      }),
                      commentExpanded: _commentExpanded,
                      onExpandComment: () => setState(() => _commentExpanded = !_commentExpanded),
                      commentController: commentController,
                      mechanicPhoto: state.currentOrder.selectedMechanic.photo,
                      mechanicName: state.currentOrder.selectedMechanic.fullName,
                      onMoreTap: _openMasterDetail,
                    ),
                    OrderInfoCard(currentOrder: state.currentOrder),
                    const SizedBox(height: 8),
                    SubOrdersCard(currentOrder: state.currentOrder),
                    SizedBox(height: context.padding.bottom + 80),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------- Top success header with animated check + pulse rings ----------

class _SuccessHeader extends StatelessWidget {
  const _SuccessHeader({required this.checkAnim, required this.ringAnim});

  final AnimationController checkAnim;
  final AnimationController ringAnim;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.sizeOf.width,
      padding: EdgeInsets.only(
        top: context.padding.top + 18, left: 27, right: 27, bottom: 22,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 160, height: 160,
            // Lottie animatsiya — JSON fayl `assets/lottie/success.json`
            // joyiga qo'yiladi. Yo'q bo'lsa eski check + pulse fallback'i
            // ko'rsatiladi.
            child: Lottie.asset(
              'assets/lottie/success.json',
              width: 160, height: 160,
              fit: BoxFit.contain,
              repeat: false,
              errorBuilder: (context, error, stackTrace) {
                return _CheckFallback(checkAnim: checkAnim, ringAnim: ringAnim);
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Successfully completed!'.tr(),
            style: context.textTheme.bodyMedium!.copyWith(
              fontSize: 20, fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please rate the master, this helps us improve!'.tr(),
            style: context.textTheme.bodySmall!.copyWith(
              fontSize: 14, fontWeight: FontWeight.w400, color: AppColor.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

}

/// Lottie JSON topilmaganda ko'rsatiladigan fallback — eski check icon +
/// pulse halqalar. Foydalanuvchi `assets/lottie/success.json` qo'shsa
/// avtomatik Lottie ishlatiladi.
class _CheckFallback extends StatelessWidget {
  const _CheckFallback({required this.checkAnim, required this.ringAnim});

  final AnimationController checkAnim;
  final AnimationController ringAnim;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([checkAnim, ringAnim]),
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            for (int i = 0; i < 3; i++)
              _ring((ringAnim.value + i / 3) % 1.0),
            ScaleTransition(
              scale: CurvedAnimation(
                parent: checkAnim, curve: Curves.elasticOut,
              ),
              child: Container(
                width: 76, height: 76,
                decoration: BoxDecoration(
                  color: AppColor.blueMain, shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  AppIcons.check,
                  width: 38, height: 38,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _ring(double t) {
    final size = 76 + (160 - 76) * t;
    final opacity = (1 - t) * 0.5;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColor.blueMain.withValues(alpha: opacity), width: 2,
        ),
      ),
    );
  }
}

// ---------- Rate card ----------

class _RateCard extends StatelessWidget {
  const _RateCard({
    required this.selectedStar,
    required this.onStarTap,
    required this.tagOptions,
    required this.selectedTag,
    required this.onTagTap,
    required this.commentExpanded,
    required this.onExpandComment,
    required this.commentController,
    required this.mechanicPhoto,
    required this.mechanicName,
    required this.onMoreTap,
  });

  final int selectedStar;
  final ValueChanged<int> onStarTap;
  final List<String> tagOptions;
  final String? selectedTag;
  final ValueChanged<String> onTagTap;
  final bool commentExpanded;
  final VoidCallback onExpandComment;
  final TextEditingController commentController;
  final String mechanicPhoto;
  final String mechanicName;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: context.sizeOf.width,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12), color: AppColor.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Rate'.tr(),
            style: context.textTheme.bodyMedium!.copyWith(
              fontSize: 16, fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          // Stars — default 0 selected.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final filled = index < selectedStar;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onStarTap(index + 1),
                child: Padding(
                  padding: EdgeInsets.only(right: index == 4 ? 0 : 10),
                  child: SvgPicture.asset(
                    AppIcons.star, width: 32, height: 32,
                    colorFilter: ColorFilter.mode(
                      filled ? AppColor.yellow : AppColor.lightGreyBlue,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          // Quick tags — Good / Excellent / Bad chips (independent toggle).
          Wrap(
            spacing: 8, runSpacing: 8,
            alignment: WrapAlignment.center,
            children: tagOptions.map((t) {
              final active = selectedTag == t;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTagTap(t),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? AppColor.blueMain : AppColor.lightBlue,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    t.tr(),
                    style: context.textTheme.bodyLarge!.copyWith(
                      fontSize: 14, fontWeight: FontWeight.w500,
                      color: active ? AppColor.white : Colors.black,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          // Leave-a-comment button — centered, separate from tags.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onExpandComment,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: commentExpanded ? AppColor.blueMain : AppColor.lightBlue,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_outlined, size: 16,
                    color: commentExpanded ? AppColor.white : Colors.black,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Leave a comment'.tr(),
                    style: context.textTheme.bodyLarge!.copyWith(
                      fontSize: 14, fontWeight: FontWeight.w500,
                      color: commentExpanded ? AppColor.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: commentExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextField(
                      maxLines: 3,
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: 'Write your thoughts...'.tr(),
                        hintStyle: context.textTheme.bodyLarge!.copyWith(
                          fontSize: 14, fontWeight: FontWeight.w400,
                          color: AppColor.grey,
                        ),
                        border: OutlineInputBorder(
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              AvatarImage(imageUrl: mechanicPhoto, name: mechanicName, size: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mechanicName,
                  style: context.textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.w600, fontSize: 14,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onMoreTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: AppColor.lightBlue,
                  ),
                  child: Text(
                    'More'.tr(),
                    style: context.textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w500, fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
