import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/features/trips/presentation/bloc/trips_bloc.dart';
import 'package:taxi_app/src/features/trips/presentation/widgets/trip_search_bar.dart';
import 'package:taxi_app/src/features/trips/presentation/widgets/trip_tile.dart';
import 'package:taxi_app/src/routes/pages.dart';

/// Trip history — `GET mobile/toll-routes` on the Quadrix Tolling backend.
///
/// Rendered as the first tab of the home tab host. The bloc is provided by the
/// `/main` route so the list survives tab switches inside the IndexedStack.
class TripsPage extends StatefulWidget {
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final bloc = context.read<TripsBloc>();
    if (bloc.state.listStatus == TripsListStatus.initial) {
      bloc.add(const TripsLoaded());
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 120;
    if (_scrollController.position.pixels < threshold) return;
    final state = context.read<TripsBloc>().state;
    if (state.hasMore && state.loadMoreStatus != TripsListStatus.loading) {
      context.read<TripsBloc>().add(const TripsLoadMore());
    }
  }

  Future<void> _refresh() async {
    context.read<TripsBloc>().add(const TripsRefreshed());
    await Future.delayed(const Duration(milliseconds: 350));
  }

  /// Opens the planning flow. When it pops with a chosen origin/destination
  /// pair the history is refreshed - calculating a route creates a new
  /// toll-route record server-side.
  Future<void> _openTripPlanner() async {
    final result = await context.push(Pages.tripMap);
    if (!mounted || result == null) return;
    context.read<TripsBloc>().add(const TripsRefreshed());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColor.white,
      child: Column(
        children: [
          TripSearchBar(onTap: _openTripPlanner),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    return BlocBuilder<TripsBloc, TripsState>(
        builder: (context, state) {
          if (state.listStatus == TripsListStatus.loading && state.items.isEmpty) {
            return const _TripsSkeleton();
          }
          if (state.listStatus == TripsListStatus.failure && state.items.isEmpty) {
            return _ErrorView(
              message: state.errorMessage,
              errorCode: state.errorCode,
              onRetry: () => context.read<TripsBloc>().add(const TripsLoaded()),
            );
          }
          if (state.items.isEmpty) {
            return _EmptyView(onRefresh: _refresh);
          }
          return RefreshIndicator.adaptive(
            onRefresh: _refresh,
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: state.items.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  );
                }
                return TripTile(trip: state.items[index]);
              },
            ),
          );
        },
    );
  }
}

class _TripsSkeleton extends StatelessWidget {
  const _TripsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEFF3F6),
      highlightColor: const Color(0xFFF7F9FB),
      period: const Duration(milliseconds: 1400),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          height: 132,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF3F6),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height / 5),
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColor.lightBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.route_outlined,
                    size: 30,
                    color: AppColor.kPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'trips.emptyTitle'.tr(),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'trips.emptySubtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColor.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.errorCode,
    required this.onRetry,
  });

  final String message;
  final String errorCode;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // No Quadrix credentials on the device yet - that's a setup gap, not a
    // transient failure, so "Retry" would just fail again identically.
    final notConnected = errorCode == 'TOLL_SESSION_MISSING';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              notConnected ? Icons.link_off : Icons.error_outline,
              size: 40,
              color: AppColor.darkGrey,
            ),
            const SizedBox(height: 12),
            Text(
              notConnected
                  ? 'trips.notConnected'.tr()
                  : (message.isEmpty ? 'common.somethingWentWrong'.tr() : message),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColor.grey),
            ),
            if (!notConnected) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onRetry,
                child: Text('common.retry'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
