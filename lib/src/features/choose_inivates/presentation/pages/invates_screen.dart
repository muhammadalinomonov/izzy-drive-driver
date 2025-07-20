// File: lib/src/features/invites/presentation/pages/invates_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import 'package:taxi_app/src/features/home/presentation/widgets/profile_order_model_sheet.dart';
import 'package:taxi_app/src/routes/pages.dart';
import '../../data/model/active_order.dart';
import '../bloc/inivites_bloc.dart';

class InvatesScreen extends StatefulWidget {
  const InvatesScreen({super.key});

  @override
  State<InvatesScreen> createState() => _InvatesScreenState();
}

class _InvatesScreenState extends State<InvatesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<InivitesBloc>().add(FetchActiveOrderEvent());
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
            Navigator.pop(context);
          },
        ),
      ),
      body: BlocBuilder<InivitesBloc, InivitesState>(
        builder: (context, state) {
          if (state is InivitesLoading) {
            return const Center(child: CircularProgressIndicator());
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
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatTimeAgo(order.createdAt),
                          style: TextStyle(
                            color: const Color(0xFF43484B),
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.30,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          order.orderTitle,
                          style: TextStyle(
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
                            SvgPicture.asset(
                              width: 20,
                              height: 20,
                              AppIcons.location,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 25.0),
                                child: Text(
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  order.currentAddress.address,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF6B7073),
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
                              side: BorderSide(
                                width: 1,
                                color: const Color(0xFFE2E7EB),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 12),
                              Text(
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
                              Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 5,
                                  horizontal: 13,
                                ),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFEFF2F5),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1,
                                      color: const Color(0xFFE2E7EB),
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '\$${order.totalPrice.toStringAsFixed(0)}',
                                    style: TextStyle(
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
                                SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  width: 35,
                                  height: 35,
                                  decoration: ShapeDecoration(
                                    color: const Color(0x19FB0000),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: SvgPicture.asset(AppIcons.down),
                                ),
                                SizedBox(width: 10),
                                Container(
                                  width: 38,
                                  padding: const EdgeInsets.all(3),
                                  height: 38,
                                  decoration: ShapeDecoration(
                                    color: const Color(0x1904A516),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: SvgPicture.asset(AppIcons.up),
                                ),
                              ],
                              SizedBox(width: 12),
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
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 18),
                        Text(
                          'Takliflar: ${offers.length}',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.30,
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: offers.length,
                          itemBuilder: (context, index) {
                            final offer = offers[index];
                            final percentageChange = offer.changePercent;
                            final balanceColor = _getBalanceColors(
                              offer.balance,
                            );
                            final changeColor = balanceColor['text']!;
                            final changeBackgroundColor =
                                balanceColor['background']!;
                            final balanceText =
                                offer.balance.toLowerCase() == 'equal'
                                ? 'TENG'
                                : offer.balance.toUpperCase();
                            return _buildOfferItem(
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
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  MaterialButton(
                    onPressed: () => context.read<InivitesBloc>().add(
                      FetchActiveOrderEvent(),
                    ),
                    color: const Color(0xFF0866FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Text(
                      'Retry',
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
            return const Center(child: Text('No data available'));
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
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColor.white),
      child: Column(
        children: [
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 25,
                child: ClipOval(
                  child: offer.avatar != null
                      ? Image.network(
                          offer.avatar!,
                          fit: BoxFit.cover,
                          width: 50,
                          height: 50,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Image.network(
                              'https://avatars.githubusercontent.com/u/108933534?v=4',
                              fit: BoxFit.cover,
                              width: 50,
                              height: 50,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                            );
                          },
                        )
                      : Image.network(
                          'https://avatars.githubusercontent.com/u/108933534?v=4',
                          fit: BoxFit.cover,
                          width: 50,
                          height: 50,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },

                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.mechanicName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        height: 1.40,
                        letterSpacing: -0.30,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      offer.shopAddress,
                      style: TextStyle(
                        color: const Color(0xFF6B7073),
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
          SizedBox(height: 13),
          Row(
            children: [
              const SizedBox(width: 6),
              Text(
                '\$${offer.proposedPrice}',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: changeBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  changeText,
                  style: TextStyle(color: changeColor, fontSize: 11.5),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: balanceColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  balanceText,
                  style: TextStyle(color: balanceTextColor, fontSize: 11.5),
                ),
              ),
            ],
          ),
          SizedBox(height: 13),
          MaterialButton(
            minWidth: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: () {
              showOrderDetailBottomSheet(context, () {
                context.push(Pages.workerInfo);
              });
            },
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 1, color: const Color(0xFFE2E7EB)),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              'Tanlash',
              style: TextStyle(
                color: const Color(0xFF0866FF),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                height: 1.40,
                letterSpacing: -0.30,
              ),
            ),
          ),
          SizedBox(height: 15),
          Container(
            width: double.infinity,
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  strokeAlign: BorderSide.strokeAlignCenter,
                  color: const Color(0xFFECF0F3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(String createdAt) {
    final dateTime = DateTime.parse(createdAt).toLocal();
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
