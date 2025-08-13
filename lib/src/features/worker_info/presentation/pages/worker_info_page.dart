import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';
import 'package:taxi_app/src/core/widgets/app_button.dart';
import 'package:taxi_app/src/features/home/presentation/widgets/comment_section_modal_sheet.dart';
import 'package:taxi_app/src/features/choose_inivates/presentation/widgets/profile_order_model_sheet.dart';
import 'package:taxi_app/src/routes/pages.dart';
import '../../data/model/worker_info_model.dart';
import '../../data/repo/worker_info_repo_impl.dart';

class WorkerInfoPage extends StatefulWidget {
  const WorkerInfoPage({super.key});

  @override
  State<WorkerInfoPage> createState() => _WorkerInfoPageState();
}

class _WorkerInfoPageState extends State<WorkerInfoPage> {
  final repo = WorkerInfoRepoImpl();
  int _selectedRating = 1;
  int? _pickRate;

  final List<String> _ratingTitles = ["Yaxshi", "A'lo", "Yomon", "Izoh yozish"];

  @override
  Widget build(BuildContext context) {
    final worker = repo.getWorker();
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: AppColor.lightBlue,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (worker.status == WorkerStatus.accepted) ...[
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF3366FF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Muvaffaqiyatli yakunlandi!',
                                      style: context.textS.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Iltimos, ustani baholang, bu bizni yanada yaxshiroq bo’lishimizga yordam beradi!',
                                      style: context.textS.bodyMedium?.copyWith(
                                        color: AppColor.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Baholang',
                                      style: context.textS.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(5, (index) {
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedRating = index + 1;
                                            });
                                          },
                                          child: Icon(
                                            index < _selectedRating
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: Color(0xFFFFC107),
                                            size: 32,
                                          ),
                                        );
                                      }),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(
                                        _ratingTitles.length,
                                        (i) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: GestureDetector(
                                            onTap: () => setState(() {
                                              _pickRate = i;
                                            }),
                                            child: Chip(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                              ),
                                              side: BorderSide.none,
                                              label: Text(
                                                _ratingTitles[i],
                                                style: context.textS.titleSmall
                                                    ?.copyWith(
                                                      fontSize: 13,
                                                      color:
                                                          _pickRate != null &&
                                                              _pickRate == i
                                                          ? AppColor.white
                                                          : AppColor.black,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                              ),
                                              backgroundColor:
                                                  _pickRate != null &&
                                                      _pickRate == i
                                                  ? AppColor.kPrimaryColor
                                                  : AppColor.lightBlue,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_pickRate == 3) ...[
                                      const SizedBox(height: 16),
                                      TextField(
                                        maxLines: 5,
                                        decoration: InputDecoration(
                                          hintText: 'Izohingizni kiriting...',
                                          filled: true,
                                          fillColor: AppColor.lightBlue,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 16,
                                              ),
                                        ),
                                        style: context.textS.bodyMedium,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ] else ...[
                              // Original info block
                              Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 18,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColor.white,
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text:
                                            'Usta ishni boshladi, tahminiy ish vaqti',
                                        style: context.textS.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' 40 daqiqa',
                                        style: context.textS.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColor.kPrimaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColor.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Master',
                                        style: context.textS.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 12.5),
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundImage: NetworkImage(
                                              worker.avatarUrl,
                                            ),
                                            radius: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                worker.name,
                                                style: context.textS.titleSmall!
                                                    .copyWith(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                              ),
                                              Text(
                                                worker.experience,
                                                style: context.textS.bodySmall
                                                    ?.copyWith(
                                                      color: AppColor.darkGrey,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          Spacer(),
                                          ElevatedButton(
                                            onPressed: () => showCommentSectionModalSheet(context),
                                            style: ElevatedButton.styleFrom(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 3,
                                              ),
                                              backgroundColor: Colors.grey[200],
                                              foregroundColor: Colors.black,
                                              elevation: 0,
                                            ),
                                            child: Text('More'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColor.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Buyurtma ma’lumotlari',
                                        style: context.textS.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Buyurtma berildi',
                                        style: context.textS.bodySmall?.copyWith(
                                          color: AppColor.grey,
                                        ),
                                      ),
                                      Text(
                                        '17.06.2025, 18:21',
                                        style: context.textS.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        'Qayerga',
                                        style: context.textS.bodySmall?.copyWith(
                                          color: AppColor.grey,
                                        ),
                                      ),
                                      Text(
                                        '3517 W. Gray St. Utica, Pennsylvania',
                                        style: context.textS.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColor.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Xizmatlar',
                                        style: context.textS.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Text(
                                            'Balonni yamash',
                                            style: context.textS.bodyMedium
                                                ?.copyWith(color: AppColor.grey),
                                          ),
                                          Spacer(),
                                          Text(
                                            ' 24 1000',
                                            style: context.textS.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
        
                                      Row(
                                        children: [
                                          Text(
                                            'Kolodkani almashtirish',
                                            style: context.textS.bodyMedium
                                                ?.copyWith(color: AppColor.grey),
                                          ),
                                          Spacer(),
                                          Text(
                                            ' 24 1000',
                                            style: context.textS.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ],
                                      ),
                                      if (worker.status ==
                                          WorkerStatus.pending) ...[
                                        const SizedBox(height: 8),
        
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColor.white,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColor.lightGrey,
                                                spreadRadius: 5,
                                                blurRadius: 7,
                                                offset: Offset(
                                                  0,
                                                  3,
                                                ), // changes position of shadow
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    'Benzonasosni almashtirish',
                                                    style:
                                                        context.textS.bodyMedium,
                                                  ),
                                                  Spacer(),
                                                  Text(
                                                    ' 24 1000',
                                                    style: context
                                                        .textS
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: AppButton(
                                                      size: Size(
                                                        double.infinity,
                                                        36,
                                                      ),
                                                      onTap: () {
                                                        setState(() {
                                                          repo.updateStatus(
                                                            WorkerStatus.accepted,
                                                          );
                                                        });
                                                      },
        
                                                      title: 'Accept',
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: AppButton(
                                                      backGroundColor:
                                                          AppColor.lightBlue,
                                                      textColor: AppColor.black,
                                                      onTap: () {},
                                                      title: 'Cancel',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Color(0xFFE8F1FF),
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              'Umumiy summa',
                                              style: context.textS.titleSmall
                                                  ?.copyWith(
                                                    color: AppColor.darkBlue,
                                                  ),
                                            ),
                                            Spacer(),
                                            if (worker.status ==
                                                WorkerStatus.accepted)
                                              Icon(
                                                Icons.check_circle,
                                                color: AppColor.kPrimaryColor,
                                              ),
                                            const SizedBox(width: 4),
                                            Text(
                                              ' 24 2000',
                                              style: TextStyle(
                                                color: AppColor.kPrimaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GestureDetector(
                                onTap: () => context.go(Pages.main),
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: AppColor.lightBlue,
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: SvgPicture.asset(AppIcons.phone),
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text('Call', style: context.textS.bodySmall),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: AppColor.lightBlue,
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: SvgPicture.asset(AppIcons.x),
                                    ),
                                  ),
                                  SizedBox(height: 12),
        
                                  Text('Cancel', style: context.textS.bodySmall),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
