import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/core/di/injection.dart';
import 'package:taxi_app/features/trips/domain/repo/trips_repo.dart';
import 'package:taxi_app/features/notifications/domain/repo/notifications_repo.dart';
import 'package:taxi_app/core/location_service.dart';
import 'package:taxi_app/core/network/auth_session.dart';
import 'package:taxi_app/features/auth/presentation/bloc/bloc/auth_bloc.dart';
import 'package:taxi_app/features/auth/presentation/bloc/forgot_password_bloc/forgot_password_bloc.dart';
import 'package:taxi_app/features/auth/presentation/pages/forgot_password_email_page.dart';
import 'package:taxi_app/features/auth/presentation/pages/reset_password_page.dart';
import 'package:taxi_app/features/auth/presentation/pages/sign_in_page.dart';
import 'package:taxi_app/features/auth/presentation/pages/sign_up_page.dart';
import 'package:taxi_app/features/common/presentation/pages/splash_screen.dart';
import 'package:taxi_app/features/choose_inivates/presentation/bloc/inivites_bloc.dart';
import 'package:taxi_app/features/choose_inivates/presentation/bloc/proposal_bloc.dart';
import 'package:taxi_app/features/choose_inivates/presentation/pages/invates_screen.dart';
import 'package:taxi_app/features/home/presentation/bloc/bloc/home_bloc.dart';
import 'package:taxi_app/features/home/presentation/screens/home_screen.dart';
import 'package:taxi_app/features/home/presentation/screens/main_screen.dart';
import 'package:taxi_app/features/map/presenation/pages/location_picker_screen.dart';
import 'package:taxi_app/features/order_create/presentation/bloc/order_create_bloc.dart';
import 'package:taxi_app/features/order_create/presentation/pages/order_create_page.dart';
import 'package:taxi_app/features/phone_verify/presentation/bloc/phone_verify_bloc.dart';
import 'package:taxi_app/features/phone_verify/presentation/pages/phone_otp_page.dart';
import 'package:taxi_app/features/map/presenation/bloc/map_bloc.dart';
import 'package:taxi_app/features/master/presentation/bloc/master_bloc.dart';
import 'package:taxi_app/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:taxi_app/features/trips/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:taxi_app/features/trips/presentation/bloc/route_overview/route_overview_bloc.dart';
import 'package:taxi_app/features/trips/presentation/bloc/trip_map/trip_map_bloc.dart';
import 'package:taxi_app/features/trips/presentation/bloc/trips_bloc.dart';
import 'package:taxi_app/features/trips/presentation/pages/driving_mode_page.dart';
import 'package:taxi_app/features/trips/presentation/pages/support_message_page.dart';
import 'package:taxi_app/features/trips/presentation/pages/route_overview_page.dart';
import 'package:taxi_app/features/trips/presentation/pages/trip_map_page.dart';
import 'package:taxi_app/features/notifications/presentation/pages/notification_detail_page.dart';
import 'package:taxi_app/features/notifications/presentation/pages/notifications_page.dart';
import 'package:taxi_app/features/order_proccess/presentation/pages/finished_order_screen.dart';
import 'package:taxi_app/features/order_proccess/presentation/pages/order_info_screen.dart';
import 'package:taxi_app/features/order_proccess/presentation/pages/order_single_screen.dart';
import 'package:taxi_app/features/profile/presentation/pages/order_history_single_screen.dart';
import 'package:taxi_app/features/profile/presentation/pages/orders_history_screen.dart';
import 'package:taxi_app/features/profile/presentation/pages/profile_edit_screen.dart';
import 'package:taxi_app/features/profile/presentation/pages/profile_page.dart';
import 'package:taxi_app/features/truck_info/presentation/bloc/bloc/track_info_bloc.dart';
import 'package:taxi_app/features/truck_info/presentation/screens/track_info.dart';
import 'package:taxi_app/features/worker_info/presentation/pages/worker_info_page.dart';
import 'package:taxi_app/routes/pages.dart';


class Routes {
  static const Set<String> _authRoutes = {
    Pages.signIn,
    Pages.signUp,
    Pages.forgotPasswordEmail,
    Pages.resetPassword,
  };

  // PhoneVerifyBloc - entry sheet va OTP page o'rtasida bo'lishish uchun
  // singleton. Sheet showPhoneVerifySheet() ichida BlocProvider.value bilan
  // ulanadi; OTP page route'da xuddi shu instance'ga ulanadi.
  static PhoneVerifyBloc? _phoneVerifyBloc;

  static PhoneVerifyBloc resolvePhoneVerifyBloc() {
    return _phoneVerifyBloc ??= getIt<PhoneVerifyBloc>();
  }

  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: Pages.splash,
    observers: [ChuckerFlutter.navigatorObserver],
    refreshListenable: AuthSession.tick,
    redirect: (context, state) {
      if (state.matchedLocation == Pages.splash) return null;
      final loggedIn = AuthSession.isLoggedIn;
      final atAuth = _authRoutes.contains(state.matchedLocation);
      if (!loggedIn && !atAuth) return Pages.signIn;
      return null;
    },
    routes: [
      GoRoute(
        path: Pages.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Pages.signIn,
        builder: (context, state) {
          return BlocProvider(
            create: (context) => getIt<AuthBloc>(),
            child: SignInPage(),
          );
        },
      ),
      GoRoute(
        path: Pages.signUp,
        builder: (context, state) {
          return BlocProvider(
            create: (context) => getIt<AuthBloc>(),
            child: SignUpPage(),
          );
        },
      ),
      GoRoute(
        path: Pages.orderCreate,
        builder: (context, state) {
          final extra = (state.extra as Map<String, dynamic>?) ?? const {};
          return BlocProvider(
            create: (_) =>
                getIt<OrderCreateBloc>()..add(
                  OrderCreateInitialized(
                    address: (extra['address'] as String?) ?? '',
                    latitude: (extra['latitude'] as num?)?.toDouble() ?? 0.0,
                    longitude: (extra['longitude'] as num?)?.toDouble() ?? 0.0,
                  ),
                ),
            child: const OrderCreatePage(),
          );
        },
      ),
      GoRoute(
        path: Pages.workerInfo,
        builder: (context, state) {
          return WorkerInfoPage();
        },
      ),
      GoRoute(
        path: Pages.map,
        builder: (context, state) {
          return BlocProvider(
            create: (context) =>
                getIt<MapBloc>(),
            child: const LocationPickerScreen(),
          );
        },
      ),
      GoRoute(
        path: Pages.home,
        builder: (context, state) {
          return BlocProvider(
            create: (context) =>
                getIt<HomeBloc>(),
            child: HomeScreen(),
          );
        },
      ),
      GoRoute(
        path: Pages.main,
        builder: (context, state) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) =>
                    getIt<HomeBloc>(),
              ),
              BlocProvider(
                create: (context) => getIt<MasterBloc>(),
              ),
              BlocProvider(
                create: (_) => getIt<AuthBloc>(),
              ),
              BlocProvider(
                create: (_) => getIt<NotificationsBloc>()..add(const UnreadCountRequested()),
              ),
              // Provided at the route (not inside HomeTabsScreen) so the trip
              // list keeps its pages and scroll state across bottom-nav
              // switches, which rebuild the tab host's subtree.
              BlocProvider(
                create: (_) => getIt<TripsBloc>(),
              ),
            ],
            child: MainScreen(),
          );
        },
      ),
      GoRoute(
        path: Pages.tripMap,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<TripMapBloc>(),
          child: const TripMapPage(),
        ),
      ),
      GoRoute(
        path: Pages.routeOverview,
        builder: (context, state) {
          final args = state.extra as RouteOverviewArgs;
          return BlocProvider(
            create: (_) => RouteOverviewBloc(
              trip: args.trip,
              origin: args.origin,
              destination: args.destination,
              repo: getIt<TripsRepo>(),
              locationService: getIt<LocationService>(),
            ),
            child: RouteOverviewPage(args: args),
          );
        },
      ),
      GoRoute(
        // UI only for now - no bloc, because nothing is fetched or sent yet.
        path: Pages.supportMessage,
        builder: (context, state) => const SupportMessagePage(),
      ),
      GoRoute(
        path: Pages.drivingMode,
        builder: (context, state) {
          final args = state.extra as DrivingModeArgs;
          return BlocProvider(
            create: (_) => getIt<NavigationBloc>(param1: args.session),
            child: DrivingModePage(args: args),
          );
        },
      ),
      GoRoute(
        path: Pages.tackScreen,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<TrackInfoBloc>(),
          child: TrackInfoScreen(),
        ),
      ),
      GoRoute(
        path: Pages.invitesPage,
        builder: (context, state) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => getIt<InivitesBloc>()..add(FetchActiveOrderEvent()),
              ),
              BlocProvider(
                create: (context) => getIt<ProposalBloc>(),
              ),
            ],
            child: InvatesScreen(),
          );
        },
      ),
      GoRoute(
        path: Pages.profile,
        builder: (context, state) {
          return ProfilePage();
        },
      ),
      GoRoute(
        path: Pages.editProfile,
        builder: (context, state) {
          return ProfileEditScreen();
        },
      ),

      GoRoute(
        path: Pages.processOrder,
        builder: (context, state) => const OrderSingleScreen(),
      ),
      GoRoute(
        path: Pages.orderInfo,
        builder: (context, state) => const OrderInfoScreen(),
      ),
      GoRoute(
        path: Pages.ordersHistory,
        builder: (context, state) => const OrdersHistoryScreen(),
      ),
      GoRoute(
        path: Pages.orderHistoryDetail,
        builder: (context, state) =>
            OrderHistorySingleScreen(orderId: (state.extra as Map)['id']),
      ),
      GoRoute(
        path: Pages.searchLocation,
        builder: (context, state) => BlocProvider(
          create: (context) =>
              getIt<MapBloc>(),
          child: const LocationPickerScreen(),
        ),
      ),

      GoRoute(
        path: Pages.finishedOrder,
        builder: (context, state) => const FinishedOrderScreen(),
      ),
      GoRoute(
        path: Pages.forgotPasswordEmail,
        builder: (context, state) {
          return BlocProvider(
            create: (_) => getIt<ForgotPasswordBloc>(),
            child: const ForgotPasswordEmailPage(),
          );
        },
      ),
      GoRoute(
        path: Pages.resetPassword,
        builder: (context, state) {
          final extra = (state.extra as Map?) ?? const {};
          final resetToken = (extra['resetToken'] as String?) ?? '';
          return BlocProvider(
            create: (_) => getIt<ForgotPasswordBloc>(param1: resetToken),
            child: const ResetPasswordPage(),
          );
        },
      ),
      GoRoute(
        path: Pages.phoneOtp,
        builder: (context, state) => BlocProvider.value(
          value: resolvePhoneVerifyBloc(),
          child: const PhoneOtpPage(),
        ),
      ),
      GoRoute(
        path: Pages.notifications,
        builder: (context, state) {
          return BlocProvider(
            create: (_) => getIt<NotificationsBloc>()..add(const NotificationsLoaded()),
            child: const NotificationsPage(),
          );
        },
      ),
      GoRoute(
        path: Pages.notificationDetail,
        builder: (context, state) {
          final extra = (state.extra as Map?) ?? const {};
          final id = (extra['id'] as int?) ?? 0;
          return NotificationDetailPage(
            id: id,
            repo: getIt<NotificationsRepo>(),
          );
        },
      ),
    ],
  );
}
