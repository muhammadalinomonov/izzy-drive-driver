import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/features/choose_inivates/presentation/widgets/profile_order_model_sheet.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/common_scalel_animation.dart';
import 'package:taxi_app/src/routes/pages.dart';

import '../../data/model/active_order.dart';
import '../bloc/inivites_bloc.dart';

class InvatesScreen extends StatefulWidget {
  const InvatesScreen({super.key});

  @override
  State<InvatesScreen> createState() => _InvatesScreenState();
}

class _InvatesScreenState extends State<InvatesScreen> {
  late InivitesBloc inivitesBloc;

  @override
  void initState() {
    super.initState();
    // Dastlab ma'lumotlarni yuklash
    inivitesBloc = context.read<InivitesBloc>()..add(FetchActiveOrderEvent());
  }

  @override
  void dispose() {
    // WebSocket'dan uzilish
    inivitesBloc.add(DisconnectFromWebSocketEvent());
    print('WebSocket disconnected');
    super.dispose();
  }

  // Function to handle the refresh action
  Future<void> _onRefresh() async {
    context.read<InivitesBloc>().add(FetchActiveOrderEvent());
    // Optional delay to ensure the refresh indicator is visible
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.greyBg,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // WebSocket'dan uzilish
            context.read<InivitesBloc>().add(DisconnectFromWebSocketEvent());
            Navigator.pop(context);
          },
        ),
      ),
      body: BlocBuilder<InivitesBloc, InivitesState>(
        builder: (context, state) {
          if (state is InivitesLoading) {
            return const Center(child: CircularProgressIndicator.adaptive());
          } else if (state is InivitesLoaded) {
            final orderResponse = state.orderResponse;
            final order = orderResponse.order;
            final offers = orderResponse.data;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColor.white,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          _formatTimeAgo(order.createdAt),
                          style: const TextStyle(
                            color: Color(0xFF43484B),
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.30,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          order.orderTitle,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 23,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.30,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            SvgPicture.asset(width: 20, height: 20, AppIcons.location),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 25.0),
                                child: Text(
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  order.currentAddress.address,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF6B7073),
                                    fontSize: 15,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.30,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.5),
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(width: 1, color: Color(0xFFE2E7EB)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              const Text(
                                'Taklif summasi',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  height: 1.20,
                                  letterSpacing: -0.30,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 13),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFEFF2F5),
                                  shape: RoundedRectangleBorder(
                                    side: const BorderSide(width: 1, color: Color(0xFFE2E7EB)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '\$${order.totalPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500,
                                      height: 1.40,
                                      letterSpacing: -0.30,
                                    ),
                                  ),
                                ),
                              ),
                              if (offers.isEmpty) ...[
                                const SizedBox(width: 10),
                                CommonScaleAnimation(
                                  onTap: () {
                                    if (order.price > 1) {
                                      context.read<InivitesBloc>().add(UpdateOrderPriceEvent(price: order.price - 1));
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    width: 35,
                                    height: 35,
                                    decoration: ShapeDecoration(
                                      color: const Color(0x19FB0000),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: SvgPicture.asset(AppIcons.down),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                CommonScaleAnimation(
                                  onTap: () {
                                    context.read<InivitesBloc>().add(UpdateOrderPriceEvent(price: order.price + 1));
                                  },
                                  child: Container(
                                    width: 38,
                                    padding: const EdgeInsets.all(3),
                                    height: 38,
                                    decoration: ShapeDecoration(
                                      color: const Color(0x1904A516),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: SvgPicture.asset(AppIcons.up),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 12),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: AppColor.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Takliflar: ${offers.length}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.30,
                              ),
                            ),
                            // Real-time indicator
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Real-time',
                                    style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        offers.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 50),
                                  child: Column(
                                    children: [
                                      Icon(Icons.hourglass_empty, size: 50, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Takliflar kutilmoqda...',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Ustalar sizning buyurtmangizni ko\'rib chiqishmoqda',
                                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: offers.length,
                                itemBuilder: (context, index) {
                                  final offer = offers[index];
                                  final percentageChange = offer.changePercent;
                                  final balanceColor = _getBalanceColors(offer.balance);
                                  final changeColor = balanceColor['text']!;
                                  final changeBackgroundColor = balanceColor['background']!;
                                  final balanceText = offer.balance.toLowerCase() == 'equal'
                                      ? 'TENG'
                                      : offer.balance.toUpperCase();
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    child: _buildOfferItem(
                                      context: context,
                                      offer: offer,
                                      percentageChange: percentageChange,
                                      changeColor: changeColor,
                                      changeBackgroundColor: changeBackgroundColor,
                                      changeText: percentageChange >= 0
                                          ? '↑${percentageChange.toStringAsFixed(1)}%'
                                          : '↓${percentageChange.abs().toStringAsFixed(1)}%',
                                      balanceColor: balanceColor['background']!,
                                      balanceTextColor: balanceColor['text']!,
                                      balanceText: balanceText,
                                      isNew: index == 0 && offers.length > 1, // Eng birinchi taklif yangi
                                    ),
                                  );
                                },
                              ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else if (state is InivitesError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Xatolik yuz berdi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${state.message}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  MaterialButton(
                    onPressed: () => context.read<InivitesBloc>().add(FetchActiveOrderEvent()),
                    color: const Color(0xFF0866FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    child: const Text(
                      'Qayta urinish',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Ma\'lumotlar yuklanmoqda...')],
              ),
            );
          }
        },
      ),
    );
  }

  Map<String, Color> _getBalanceColors(String balance) {
    switch (balance.toLowerCase()) {
      case 'equal':
        return {'background': Colors.yellow[100]!, 'text': Colors.yellow[800]!};
      case 'cheap':
        return {
          'background': Colors.red[100]!, // Red for "cheap"
          'text': Colors.red[800]!,
        };
      case 'expensive':
        return {
          'background': Colors.green[100]!, // Green for "expensive"
          'text': Colors.green[800]!,
        };
      default:
        return {'background': Colors.grey[100]!, 'text': Colors.grey[800]!};
    }
  }

  Widget _buildOfferItem({
    required BuildContext context,
    required OrderData offer,
    required double percentageChange,
    required Color changeColor,
    required Color changeBackgroundColor,
    required String changeText,
    required Color balanceColor,
    required Color balanceTextColor,
    required String balanceText,
    bool isNew = false,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: isNew ? 8 : 0),
      decoration: BoxDecoration(color: AppColor.white),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.transparent,
                      child: ClipOval(
                        child: offer.avatar != null
                            ? Image.network(
                                offer.avatar!,
                                fit: BoxFit.cover,
                                width: 50,
                                height: 50,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return SvgPicture.asset(AppIcons.profile, fit: BoxFit.cover, width: 50, height: 50);
                                },
                              )
                            : SvgPicture.asset(AppIcons.profile, fit: BoxFit.cover, width: 50, height: 50),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  offer.mechanicName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    height: 1.40,
                                    letterSpacing: -0.30,
                                  ),
                                ),
                              ),
                              if (offer.distance > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${offer.distance.toStringAsFixed(1)} km',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            offer.shopAddress,
                            style: const TextStyle(
                              color: Color(0xFF6B7073),
                              fontSize: 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              height: 1.40,
                              letterSpacing: -0.30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    const SizedBox(width: 6),
                    Text(
                      '\$${offer.proposedPrice.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: changeBackgroundColor, borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        changeText,
                        style: TextStyle(color: changeColor, fontSize: 11.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTimeAgo(offer.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF6B7073),
                        fontSize: 11,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                MaterialButton(
                  minWidth: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: () {
                    showOrderDetailBottomSheet(context, offer.id.toString(), () {
                      context.push(Pages.proccessOrder);
                    });
                  },
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(width: 1, color: Color(0xFFE2E7EB)),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Text(
                    'Tanlash',
                    style: TextStyle(
                      color: Color(0xFF0866FF),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      height: 1.40,
                      letterSpacing: -0.30,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            decoration: const ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 1, strokeAlign: BorderSide.strokeAlignCenter, color: Color(0xFFECF0F3)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(String createdAt) {
    try {
      final dateTime = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'Hozir';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} daqiqa oldin';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} soat oldin';
      } else {
        return '${difference.inDays} kun oldin';
      }
    } catch (e) {
      return 'Noma\'lum vaqt';
    }
  }
}
