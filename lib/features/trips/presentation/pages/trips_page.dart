import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/core/widgets/app_skeleton.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/core/utils/unit_format.dart';
import 'package:taxi_app/features/trips/data/model/navigation_session_model.dart';
import 'package:taxi_app/features/trips/data/model/trip_model.dart';
import 'package:taxi_app/features/trips/presentation/bloc/trips_bloc.dart';
import 'package:taxi_app/features/trips/presentation/pages/driving_mode_page.dart';
import 'package:taxi_app/features/trips/presentation/pages/route_overview_page.dart';
import 'package:taxi_app/features/trips/presentation/widgets/trip_search_bar.dart';
import 'package:taxi_app/features/trips/presentation/widgets/trip_tile.dart';
import 'package:taxi_app/routes/pages.dart';

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
    bloc.add(const TripsActiveSessionChecked());
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
    context.read<TripsBloc>()
      ..add(const TripsRefreshed())
      ..add(const TripsActiveSessionChecked());
    await Future.delayed(const Duration(milliseconds: 350));
  }

  /// Resumes the in-progress trip. The session is already in hand from
  /// `GET current`, so Driving Mode restores route, progress and map state
  /// from it - nothing is recalculated.
  Future<void> _continueRoute(NavigationSessionModel session) async {
    await context.push(
      Pages.drivingMode,
      extra: DrivingModeArgs(
        session: session,
        // The session carries only raw coordinates for the destination, and
        // resuming skips the planning screen that knew the place name. Driving
        // Mode falls back to a generic label when this is empty.
        destinationLabel: '',
      ),
    );
    if (!mounted) return;
    // The trip may have been completed or cancelled in there - re-check so the
    // card clears, and refresh history since a finished trip belongs in it.
    context.read<TripsBloc>()
      ..add(const TripsActiveSessionChecked())
      ..add(const TripsRefreshed());
  }

  /// Opens the planning flow. When it pops with a chosen origin/destination
  /// pair the history is refreshed - calculating a route creates a new
  /// toll-route record server-side.
  Future<void> _openTripPlanner() async {
    final result = await context.push(Pages.tripMap);
    if (!mounted || result == null) return;
    context.read<TripsBloc>().add(const TripsRefreshed());
  }

  /// Opens Route Overview for a history item straight away. The list
  /// endpoint's `toll_markers` may be empty (see docs/mobile-api.md §4.1) and
  /// its endpoints carry no labels, so the overview fetches the full detail
  /// behind its own loading state rather than holding the tap here.
  void _openRouteDetail(TripModel trip) {
    context.push(Pages.routeOverview, extra: RouteOverviewArgs.pending(trip));
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

  /// The Continue Route card, or null when no trip is running.
  ///
  /// Built here rather than in the outer column so it can ride inside the
  /// scroll view: pinned above the list it ate a fixed slice of a short
  /// screen, and on a phone in a cradle that is most of the history.
  Widget? _continueCard(TripsState state) {
    final session = state.activeSession;
    if (!state.hasActiveSession || session == null) return null;
    return _ContinueRouteCard(
      session: session,
      onTap: () => _continueRoute(session),
    );
  }

  Widget _buildList() {
    return BlocBuilder<TripsBloc, TripsState>(
        builder: (context, state) {
          final card = _continueCard(state);

          if (state.listStatus == TripsListStatus.loading && state.items.isEmpty) {
            return _WithHeader(header: card, child: const _TripsSkeleton());
          }
          if (state.listStatus == TripsListStatus.failure && state.items.isEmpty) {
            return _WithHeader(
              header: card,
              child: _ErrorView(
                message: state.errorMessage,
                errorCode: state.errorCode,
                onRetry: () => context.read<TripsBloc>().add(const TripsLoaded()),
              ),
            );
          }
          if (state.items.isEmpty) {
            return _WithHeader(
              header: card,
              child: _EmptyView(onRefresh: _refresh),
            );
          }

          // The card is item 0 of the list itself, so it scrolls away with the
          // history instead of holding the top of the viewport.
          final headerCount = card == null ? 0 : 1;
          return RefreshIndicator.adaptive(
            onRefresh: _refresh,
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount:
                  headerCount + state.items.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (card != null && index == 0) return card;
                final itemIndex = index - headerCount;
                if (itemIndex >= state.items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  );
                }
                final trip = state.items[itemIndex];
                return TripTile(
                  trip: trip,
                  onTap: () => _openRouteDetail(trip),
                );
              },
            ),
          );
        },
    );
  }

}

/// Places the Continue Route card above a non-list state.
///
/// The skeleton, empty and error views own their own scrolling (or have
/// nothing to scroll), so the card sits above them rather than being threaded
/// into their internals.
class _WithHeader extends StatelessWidget {
  const _WithHeader({required this.header, required this.child});

  final Widget? header;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (header == null) return child;
    return Column(
      children: [
        header!,
        Expanded(child: child),
      ],
    );
  }
}

class _TripsSkeleton extends StatelessWidget {
  const _TripsSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
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

/// Resume affordance for an unfinished trip, pinned above the history list.
///
/// Shows how far along the trip is so the driver can tell at a glance whether
/// this is the run they just paused - progress data is already in the session
/// from `GET current`, so nothing extra is fetched to render it.
class _ContinueRouteCard extends StatelessWidget {
  const _ContinueRouteCard({required this.session, required this.onTap});

  final NavigationSessionModel session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = session.progress;
    final percent = (progress.percent / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Material(
        color: AppColor.kPrimaryColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.navigation_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'trips.continueRoute'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'trips.tripInProgress'.tr(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${progress.percent.round()}%',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded,
                        color: Colors.white, size: 22),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 5,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatMiles(progress.remainingDistanceMeters),
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                    Text(
                      formatDuration(progress.remainingDurationSeconds),
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
