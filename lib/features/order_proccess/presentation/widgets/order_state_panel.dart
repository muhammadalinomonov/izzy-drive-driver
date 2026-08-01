import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/core/location_service.dart';
import 'package:taxi_app/features/common/presentation/widgets/common_image.dart';
import 'package:taxi_app/features/master/data/repository/master_repository_impl.dart';
import 'package:taxi_app/features/master/data/source/master_remote_data_source.dart';
import 'package:taxi_app/features/master/presentation/bloc/master_bloc.dart';
import 'package:taxi_app/features/master/presentation/screens/master_detail_sheet.dart';
import 'package:taxi_app/features/order_proccess/presentation/bloc/orders_bloc.dart';
import 'package:taxi_app/features/order_proccess/presentation/widgets/order_actions_widget.dart';
import 'package:taxi_app/features/order_proccess/presentation/widgets/order_status_row.dart';

const Color _kBg = Color(0xFFEFF3F6);
const Color _kSubtitle = Color(0xFF6B7073);

/// Tracking / Arrived bottom sheet uchun umumiy panel - Figma frame 1884:4489
/// va 1897:4828 dizaynlarini taqlid qiladi. Tashqi gray fon (24px rounded top)
/// + 3 ta oq card: status, master, actions.
class OrderStatePanel extends StatelessWidget {
  const OrderStatePanel({
    super.key,
    required this.title,
    required this.infoLabel,
    required this.infoValue,
  });

  /// Asosiy sarlavha - "Usta buyurtmani qabul qildi..." kabi.
  final String title;

  /// Yordamchi label - "Kelish vaqti" / "Tahminiy ish vaqti".
  final String infoLabel;

  /// Label qiymati - "17:00-17:10" / "40 daqiqa".
  final String infoValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusCard(title: title, infoLabel: infoLabel, infoValue: infoValue),
          const SizedBox(height: 8),
          const _MasterCard(),
          const SizedBox(height: 8),
          // Actions card telefon tagigacha cho'ziladi - safe-area inset
          // shu cardning ichida, content esa home indicator ostiga tushmaydi.
          const _ActionsCard(),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.infoLabel,
    required this.infoValue,
  });

  final String title;
  final String infoLabel;
  final String infoValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: Column(
          children: [
            // Drag handle.
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                height: 1.4,
                letterSpacing: -0.30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              infoLabel,
              style: const TextStyle(
                color: _kSubtitle,
                fontSize: 11,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                letterSpacing: -0.30,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              infoValue,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                height: 1.4,
                letterSpacing: -0.30,
              ),
            ),
            const SizedBox(height: 8),
            const OrderStatusRow(),
          ],
        ),
      ),
    );
  }
}

class _MasterCard extends StatelessWidget {
  const _MasterCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: BlocSelector<OrdersBloc, OrdersState, dynamic>(
          selector: (state) => state.currentOrder.selectedMechanic,
          builder: (context, mechanic) {
            final fullName = mechanic.fullName as String;
            final photo = mechanic.photo as String;
            final truckInfo = [
              mechanic.truckMark,
              mechanic.truckmodel,
              mechanic.truckYear,
            ].where((s) => (s as String).isNotEmpty).join(' ');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Master'.tr(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.30,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    AvatarImage(imageUrl: photo, name: fullName, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.30,
                            ),
                          ),
                          if (truckInfo.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              truckInfo,
                              style: const TextStyle(
                                color: _kSubtitle,
                                fontSize: 11,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.30,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _MoreButton(mechanicId: mechanic.id as int),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.mechanicId});

  final int mechanicId;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kBg,
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: () {
          final bloc = MasterBloc(
            MasterRepositoryImpl(MasterRemoteDataSource()),
            LocationService(),
          );
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (ctx) => BlocProvider.value(
              value: bloc,
              child: MasterDetailSheet(id: mechanicId),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          alignment: Alignment.center,
          constraints: const BoxConstraints(minWidth: 70, minHeight: 28),
          child: Text(
            'More'.tr(),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              letterSpacing: -0.30,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  const _ActionsCard();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        // Faqat tepa burchaklari rounded - pastki qism telefon chetigacha
        // tekis cho'ziladi.
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 8 + bottomInset),
        child: const OrderActionsWidget(),
      ),
    );
  }
}
