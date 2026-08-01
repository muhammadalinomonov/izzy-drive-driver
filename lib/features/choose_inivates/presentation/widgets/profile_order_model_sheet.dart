// Master detail bottom sheet - Figma frame 15 (node 1859:4927).
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/features/choose_inivates/presentation/bloc/inivites_bloc.dart';
import 'package:taxi_app/features/common/presentation/widgets/common_image.dart';
import 'package:taxi_app/features/choose_inivates/presentation/bloc/proposal_bloc.dart';
import 'package:taxi_app/features/choose_inivates/presentation/bloc/proposal_state.dart';

import '../bloc/proposal_event.dart';

const Color _kBg = Color(0xFFEFF3F6);
const Color _kBorder = Color(0xFFE3E8EB);
const Color _kSubtitle = Color(0xFF6B7073);
const Color _kCaption = Color(0xFF43484B);
const Color _kMuted = Color(0xFF93989B);
const Color _kPrimary = Color(0xFF0866FF);

void showOrderDetailBottomSheet(
  BuildContext c,
  String id,
  VoidCallback onDoneTap,
) {
  showModalBottomSheet(
    context: c,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x4D000000),
    builder: (context) {
      final proposalBloc = BlocProvider.of<ProposalBloc>(c);
      final invitesBloc = BlocProvider.of<InivitesBloc>(c);
      proposalBloc.add(GetProposalEvent(id: int.parse(id)));
      return BlocProvider.value(
        value: proposalBloc,
        child: DraggableScrollableSheet(
          // Figma: bottom sheet 15px-dan boshlanadi (statusbar ostida) - deyarli
          // butun ekranni egallaydi.
          initialChildSize: 0.96,
          minChildSize: 0.6,
          maxChildSize: 0.96,
          expand: false,
          builder: (context, scrollController) {
            return _SheetContent(
              proposalId: id,
              scrollController: scrollController,
              onCall: () async {
                proposalBloc.add(SelectProposalEvent(proposalId: int.parse(id)));
                final completed = await proposalBloc.stream.firstWhere(
                  (s) =>
                      (s.status == ProposalStatus.loaded && s.route != null) ||
                      s.status == ProposalStatus.error,
                );
                if (completed.status == ProposalStatus.error) {
                  if (c.mounted) {
                    ScaffoldMessenger.of(c).showSnackBar(
                      SnackBar(
                        content: Text(
                          completed.errorMessage ?? 'Failed to select master',
                        ),
                      ),
                    );
                  }
                  return;
                }
                invitesBloc.add(DisconnectFromWebSocketEvent());
                if (c.mounted && Navigator.of(c).canPop()) {
                  Navigator.of(c).pop();
                }
                onDoneTap();
              },
            );
          },
        ),
      );
    },
  );
}

class _SheetContent extends StatelessWidget {
  const _SheetContent({
    required this.proposalId,
    required this.scrollController,
    required this.onCall,
  });

  final String proposalId;
  final ScrollController scrollController;
  final Future<void> Function() onCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Scrollable content (profile + about + payment). Drag handle endi
          // birinchi oq cardning ICHIDA - Figma'dagidek.
          Expanded(
            child: BlocBuilder<ProposalBloc, ProposalState>(
              builder: (context, state) {
                if (state.status == ProposalStatus.loading ||
                    state.status == ProposalStatus.initial) {
                  return ListView(
                    controller: scrollController,
                    padding: EdgeInsets.zero,
                    children: const [_ProfileCardSkeleton()],
                  );
                }
                if (state.status == ProposalStatus.error) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        state.errorMessage ?? 'Error loading proposal',
                        style: const TextStyle(color: _kSubtitle),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final proposal = state.proposal;
                if (proposal == null) {
                  return ListView(
                    controller: scrollController,
                    padding: EdgeInsets.zero,
                    children: const [_ProfileCardSkeleton()],
                  );
                }
                return ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    _ProfileCard(proposal: proposal),
                    const SizedBox(height: 8),
                    _AboutOrderCard(order: proposal.orderInfo),
                    const SizedBox(height: 8),
                    const _PaymentCard(),
                  ],
                );
              },
            ),
          ),
          // Fixed bottom action card - system nav bar maydonigacha cho'ziladi.
          BlocBuilder<ProposalBloc, ProposalState>(
            builder: (context, state) {
              final loading = state.status == ProposalStatus.loading ||
                  state.status == ProposalStatus.initial;
              final proposal = state.proposal;
              return _BottomActionCard(
                yourOffer: proposal?.orderInfo.orderPrice ?? 0,
                masterOffer: proposal?.orderInfo.proposalPrice ?? 0,
                isLoading: loading,
                onCall: onCall,
              );
            },
          ),
        ],
      ),
    );
  }
}

// Public ProfileSection - comment_section_modal_sheet.dart shu nom bilan
// import qiladi. Master avatar + ism + ro'yxatdan o'tgan sanani ko'rsatadi.
class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return BlocBuilder<ProposalBloc, ProposalState>(
      builder: (context, state) {
        if (state.status == ProposalStatus.loading ||
            state.status == ProposalStatus.initial) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }
        if (state.status == ProposalStatus.error) {
          return Center(
            child: Text('Error: ${state.errorMessage ?? "Unknown error"}'),
          );
        }
        if (state.proposal == null) {
          return const Center(child: Text('No data available'));
        }
        final mechanic = state.proposal!.mechanicInfo;
        return Column(
          children: [
            AvatarImage(
              imageUrl: mechanic.avatar,
              name: mechanic.mechanicName,
              size: mq.size.width * 0.26,
            ),
            const SizedBox(height: 12),
            Text(
              mechanic.mechanicName,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                letterSpacing: -0.30,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${'Registered data'.tr()}  '
              '${_formatRegisteredDate(state.proposal!.orderInfo.createdAt)}',
              style: const TextStyle(
                color: _kSubtitle,
                fontSize: 11,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                letterSpacing: -0.30,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------- Profile card (top white card with avatar + stats) ----------

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.proposal});

  final dynamic proposal; // Proposal - kept dynamic to avoid extra imports

  @override
  Widget build(BuildContext context) {
    final mechanic = proposal.mechanicInfo;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        // Sheet top bilan birga 24px rounded - drag handle ham shu cardning
        // ichida.
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          // Drag handle - endi oq cardning ICHIDA, Figma'dagi pozitsiyada.
          Container(
            width: 43,
            height: 4,
            decoration: BoxDecoration(
              color: _kBorder,
              borderRadius: BorderRadius.circular(540),
            ),
          ),
          const SizedBox(height: 18),
          // Avatar 87x87.
          AvatarImage(
            imageUrl: mechanic.avatar,
            name: mechanic.mechanicName,
            size: 87,
          ),
          const SizedBox(height: 14),
          Text(
            mechanic.mechanicName,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              height: 1.4,
              letterSpacing: -0.30,
            ),
          ),
          const SizedBox(height: 6),
          // "Registered data DATE (X days ago)"
          DefaultTextStyle(
            style: const TextStyle(
              color: _kSubtitle,
              fontSize: 11,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.4,
              letterSpacing: -0.30,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Registered data'.tr()),
                const SizedBox(width: 8),
                Text(_formatRegisteredDate(proposal.orderInfo.createdAt)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          // Stats row: All orders / Success / Performance.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatColumn(
                label: 'All orders'.tr(),
                value: '${mechanic.allOrdersCount}',
              ),
              _StatColumn(
                label: 'Success'.tr(),
                value: '${mechanic.successOrdersCount}',
              ),
              _StatColumn(
                label: 'Performance'.tr(),
                // Backend is the source of truth — the percentage formula
                // can change server-side without an app release. Fall back
                // to the local success/all ratio only while the backend
                // rollout is in progress and `performancePercent` is null.
                value: _formatPerformance(
                  mechanic.performancePercent,
                  mechanic.allOrdersCount,
                  mechanic.successOrdersCount,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _kMuted,
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            letterSpacing: -0.30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            letterSpacing: -0.30,
          ),
        ),
      ],
    );
  }
}

class _ProfileCardSkeleton extends StatelessWidget {
  const _ProfileCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: const Column(
        children: [
          _SkBox(width: 87, height: 87, radius: 50),
          SizedBox(height: 14),
          _SkBox(width: 160, height: 16),
          SizedBox(height: 8),
          _SkBox(width: 220, height: 11),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SkStat(),
              _SkStat(),
              _SkStat(),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkStat extends StatelessWidget {
  const _SkStat();
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SkBox(width: 70, height: 11),
        SizedBox(height: 8),
        _SkBox(width: 50, height: 20),
      ],
    );
  }
}

class _SkBox extends StatelessWidget {
  const _SkBox({required this.width, required this.height, this.radius = 4});
  final double width;
  final double height;
  final double radius;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ---------- About order card ----------

class _AboutOrderCard extends StatelessWidget {
  const _AboutOrderCard({required this.order});

  final dynamic order; // OrderInfo

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ABOUT ORDER'.tr(),
            style: const TextStyle(
              color: _kMuted,
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              letterSpacing: -0.30,
            ),
          ),
          const SizedBox(height: 18),
          _Field(
            label: 'Problem'.tr(),
            value: order.orderTitle,
          ),
          const SizedBox(height: 14),
          _Field(
            label: 'Where to'.tr(),
            value: order.orderAddress,
            italicSuffix: _formatDistance(order.distance),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value, this.italicSuffix});

  final String label;
  final String value;
  final String? italicSuffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _kMuted,
            fontSize: 11,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            letterSpacing: -0.30,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            height: 1.4,
            letterSpacing: -0.30,
          ),
        ),
        if (italicSuffix != null) ...[
          const SizedBox(height: 4),
          Text(
            italicSuffix!,
            style: const TextStyle(
              color: _kCaption,
              fontSize: 11,
              fontFamily: 'Inter',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.30,
            ),
          ),
        ],
      ],
    );
  }
}

// ---------- Payment card ----------

class _PaymentCard extends StatelessWidget {
  const _PaymentCard();

  @override
  Widget build(BuildContext context) {
    // Hozircha faqat Cash mavjud - Apple Pay va Google Pay keyinroq qo'shiladi.
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PAYMENT INFORMATION'.tr(),
            style: const TextStyle(
              color: _kMuted,
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              letterSpacing: -0.30,
            ),
          ),
          const SizedBox(height: 18),
          _PayRow(
            icon: Icons.payments_outlined,
            label: 'Cash'.tr(),
            selected: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _PayRow extends StatelessWidget {
  const _PayRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.4,
                letterSpacing: -0.30,
              ),
            ),
          ),
          // Selection indicator: filled blue check if selected, else empty
          // gray circle.
          if (selected)
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: _kPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            )
          else
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(width: 1.5, color: _kBorder),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------- Bottom action card (fixed) ----------

class _BottomActionCard extends StatelessWidget {
  const _BottomActionCard({
    required this.yourOffer,
    required this.masterOffer,
    required this.isLoading,
    required this.onCall,
  });

  final double yourOffer;
  final double masterOffer;
  final bool isLoading;
  final Future<void> Function() onCall;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    // Oq card system nav-gacha cho'ziladi (margin top 8 - sheet-da scroll
    // content bilan orasidagi kichik bo'shliq). Ichidagi paddingga safe-area
    // bottom qo'shiladi - tugma home indicator ostiga tushib qolmaydi.
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 16, 12, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sizning taklifingiz / Ustani taklifi - 2-col with divider.
            Row(
              children: [
                Expanded(
                  child: _OfferColumn(
                    label: 'Your offer'.tr(),
                    value: '\$${yourOffer.toStringAsFixed(0)}',
                    valueColor: _kCaption,
                  ),
                ),
                Container(width: 1, height: 36, color: _kBorder),
                Expanded(
                  child: _OfferColumn(
                    label: "Master's offer".tr(),
                    value: '\$${masterOffer.toStringAsFixed(0)}',
                    valueColor: _kPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Material(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(50),
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: isLoading ? null : () => onCall(),
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            'Call'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              letterSpacing: -0.30,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferColumn extends StatelessWidget {
  const _OfferColumn({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _kSubtitle,
            fontSize: 11,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            height: 1.4,
            letterSpacing: -0.30,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            height: 1.4,
            letterSpacing: -0.30,
          ),
        ),
      ],
    );
  }
}

// ---------- Helpers ----------

String _formatRegisteredDate(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    final now = DateTime.now();
    final diffDays = now.difference(dt).inDays;
    final dateStr =
        '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    if (diffDays <= 0) return dateStr;
    return '$dateStr ($diffDays ${'days ago'.tr()})';
  } catch (_) {
    return iso;
  }
}

String _formatDistance(double distance) {
  if (distance <= 0) return '';
  final km = distance < 10 ? distance.toStringAsFixed(1) : distance.toStringAsFixed(0);
  return '$km km ${'away'.tr()}';
}

String _formatPerformance(int? backendPercent, int allOrders, int successOrders) {
  if (backendPercent != null) {
    return '${backendPercent.clamp(0, 100)}%';
  }
  if (allOrders <= 0) return '0%';
  final pct = (successOrders / allOrders * 100).round().clamp(0, 100);
  return '$pct%';
}
