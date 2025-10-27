// File: profile_order_model_sheet.dart
// ! Responsive Order Detail Bottom Sheet
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/widgets/app_button.dart';
import 'package:taxi_app/src/features/choose_inivates/presentation/bloc/inivites_bloc.dart';
import 'package:taxi_app/src/features/choose_inivates/presentation/bloc/proposal_bloc.dart';
import 'package:taxi_app/src/features/choose_inivates/presentation/bloc/proposal_state.dart';

import '../../../order_proccess/presentation/bloc/orders_bloc.dart';
import '../bloc/proposal_event.dart';
void showOrderDetailBottomSheet(
    BuildContext c,
    String id,
    VoidCallback onDoneTap,
    ) {
  print(id);
  showModalBottomSheet(
    context: c,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final proposalBloc = BlocProvider.of<ProposalBloc>(c);
      final invitesBloc = BlocProvider.of<InivitesBloc>(c);
      proposalBloc.add(GetProposalEvent(id: int.parse(id)));
      return BlocProvider.value(
        value: proposalBloc,
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return BlocBuilder<ProposalBloc, ProposalState>(
              builder: (c, state) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColor.kPrimary2Color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(
                            top: 12,
                            left: 50,
                            right: 60,
                            bottom: 18,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: AppColor.white,
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 40,
                                height: 5,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const ProfileSection(),
                              const SizedBox(height: 18),
                              const _StatsRow(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: AppColor.white,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionTitle('ABOUT ORDER'),
                              const _OrderInfoSection(),
                              if (state.route != null) ...[
                                const _SectionTitle('SELECTED ORDER DETAILS'),
                                Text(
                                  'Title: ${state.route!['order_title']}',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  'Address: ${state.route!['order_address']}',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  'Price: \$${state.route!['order_price']}',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: AppColor.white,
                          ),
                          child: const Column(
                            children: [
                              _SectionTitle('PAYMENT INFORMATION'),
                              _PaymentOptionsSection(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: AppColor.white,
                          ),
                          child: Column(
                            children: [
                              const _OffersRow(),
                              const SizedBox(height: 18),
                              AppButton(
                                title: 'Chaqirish',
                                onTap: () {
                                  proposalBloc.add(SelectProposalEvent(proposalId: int.parse(id)));
                                  invitesBloc.add(DisconnectFromWebSocketEvent());
                                  onDoneTap(); // Navigate after selection
                                },
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    },
  );
}

class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return BlocBuilder<ProposalBloc, ProposalState>(
      builder: (context, state) {
        if (state.status == ProposalStatus.loading) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        if (state.status == ProposalStatus.error) {
          return Center(child: Text('Error: ${state.errorMessage ?? "Unknown error"}'));
        }
        if (state.status == ProposalStatus.loaded && state.proposal != null) {
          final mechanic = state.proposal!.mechanicInfo;
          return Column(
            children: [
              CircleAvatar(
                backgroundColor: Colors.transparent,
                radius: mq.size.width * 0.13,

                backgroundImage: NetworkImage(mechanic.avatar),
              ),
              const SizedBox(height: 12),
              Text(
                mechanic.mechanicName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Registered data  ${state.proposal!.orderInfo.createdAt.split('T').first}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColor.grey),
              ),
            ],
          );
        }
        return const Center(child: Text('No data available'));
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    TextStyle? labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColor.grey);
    TextStyle? valueStyle = Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500);
    return BlocBuilder<ProposalBloc, ProposalState>(
      builder: (context, state) {
        if (state.status == ProposalStatus.loaded && state.proposal != null) {
          final mechanic = state.proposal!.mechanicInfo;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatColumn('All orders', '${mechanic.allOrdersCount}', labelStyle, valueStyle),
              _StatColumn('Success', '${mechanic.successOrdersCount}', labelStyle, valueStyle),
              _StatColumn('Performance', '${mechanic.performance.averageStars.toStringAsFixed(1)}', labelStyle, valueStyle),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const _StatColumn(this.label, this.value, this.labelStyle, this.valueStyle);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 4),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColor.darkGrey,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OrderInfoSection extends StatelessWidget {
  const _OrderInfoSection();

  @override
  Widget build(BuildContext context) {
    TextStyle? labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColor.grey);
    TextStyle? valueStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500);
    return BlocBuilder<ProposalBloc, ProposalState>(
      builder: (context, state) {
        if (state.status == ProposalStatus.loaded && state.proposal != null) {
          final order = state.proposal!.orderInfo;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Muammo', style: labelStyle),
                Text(order.orderTitle, style: valueStyle),
                const SizedBox(height: 8),
                Text('Qayerga', style: labelStyle),
                Text(order.orderAddress, style: valueStyle),
                Text('${order.distance} km uzoqlikda', style: labelStyle),
              ],
            ),
          );
        }
        return const Center(child: CircularProgressIndicator.adaptive());
      },
    );
  }
}

class _PaymentOptionsSection extends StatefulWidget {
  const _PaymentOptionsSection();

  @override
  State<_PaymentOptionsSection> createState() => _PaymentOptionsSectionState();
}

class _PaymentOptionsSectionState extends State<_PaymentOptionsSection> {
  bool isApple = Platform.isIOS;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PaymentOptionTile(
          icon: AppIcons.apple,
          label: 'Apple Pay',
          selected: isApple,
          onTap: () => setState(() => isApple = true),
        ),
        Divider(
          endIndent: 10,
          indent: 10,
          color: AppColor.lightGrey,
          height: 0.1,
        ),
        _PaymentOptionTile(
          icon: AppIcons.google,
          label: 'Google Pay',
          selected: !isApple,
          onTap: () => setState(() => isApple = false),
        ),
      ],
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOptionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return ListTile(
          leading: SvgPicture.asset(icon),
          title: Text(label),
          trailing: Transform.scale(
            scale: 1.3,
            child: Checkbox(
              side: const BorderSide(width: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              value: selected,
              onChanged: (bool? value) {},
            ),
          ),
          onTap: onTap,
        );
      },
    );
  }
}

class _OffersRow extends StatelessWidget {
  const _OffersRow();

  @override
  Widget build(BuildContext context) {
    TextStyle? labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColor.grey);
    TextStyle? valueStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 18,
    );
    return BlocBuilder<ProposalBloc, ProposalState>(
      builder: (context, state) {
        if (state.status == ProposalStatus.loaded && state.proposal != null) {
          final order = state.proposal!.orderInfo;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Sizning taklifingiz', style: labelStyle),
                      const SizedBox(height: 4),
                      Text('${order.orderPrice} \$', style: valueStyle),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: Colors.grey[300]),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Ustani taklifi', style: labelStyle),
                      const SizedBox(height: 4),
                      Text(
                        '${order.proposalPrice} \$',
                        style: valueStyle?.copyWith(color: AppColor.kPrimaryColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}