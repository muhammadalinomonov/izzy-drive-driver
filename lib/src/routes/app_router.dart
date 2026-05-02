import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/location_service.dart';
import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import 'package:taxi_app/src/features/auth/data/repo/auth_repo_impl.dart';
import 'package:taxi_app/src/features/auth/data/source/auth_data_source.dart';
import 'package:taxi_app/src/features/auth/presentation/bloc/bloc/auth_bloc.dart';
import 'package:taxi_app/src/features/auth/presentation/bloc/forgot_password_bloc/forgot_password_bloc.dart';
import 'package:taxi_app/src/features/auth/presentation/pages/forgot_password_email_page.dart';
import 'package:taxi_app/src/features/auth/presentation/pages/reset_password_page.dart';
import 'package:taxi_app/src/features/auth/presentation/pages/sign_in_page.dart';
import 'package:taxi_app/src/features/auth/presentation/pages/sign_up_page.dart';
import 'package:taxi_app/src/features/chat/presentation/pages/chat_page.dart';
import 'package:taxi_app/src/features/choose_inivates/data/repo/active_order_repository_imp.dart';
import 'package:taxi_app/src/features/choose_inivates/presentation/bloc/inivites_bloc.dart';
import 'package:taxi_app/src/features/choose_inivates/presentation/bloc/proposal_bloc.dart';
import 'package:taxi_app/src/features/choose_inivates/presentation/pages/invates_screen.dart';
import 'package:taxi_app/src/features/home/data/repository/home_repository_impl.dart';
import 'package:taxi_app/src/features/home/data/source/home_data_source.dart';
import 'package:taxi_app/src/features/home/presentation/bloc/bloc/home_bloc.dart';
import 'package:taxi_app/src/features/home/presentation/screens/home_screen.dart';
import 'package:taxi_app/src/features/home/presentation/screens/main_screen.dart';
import 'package:taxi_app/src/features/map/presenation/pages/location_picker_screen.dart';
import 'package:taxi_app/src/features/map/presenation/bloc/map_bloc.dart';
import 'package:taxi_app/src/features/master/data/repository/master_repository_impl.dart';
import 'package:taxi_app/src/features/master/data/source/master_remote_data_source.dart';
import 'package:taxi_app/src/features/master/presentation/bloc/master_bloc.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/pages/finished_order_screen.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/pages/order_info_screen.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/pages/order_single_screen.dart';
import 'package:taxi_app/src/features/profile/presentation/pages/order_history_single_screen.dart';
import 'package:taxi_app/src/features/profile/presentation/pages/orders_history_screen.dart';
import 'package:taxi_app/src/features/profile/presentation/pages/profile_edit_screen.dart';
import 'package:taxi_app/src/features/profile/presentation/pages/profile_page.dart';
import 'package:taxi_app/src/features/truck_info/data/repo/driver_info_repo_impl.dart';
import 'package:taxi_app/src/features/truck_info/data/source/driver_info_source.dart';
import 'package:taxi_app/src/features/truck_info/presentation/bloc/bloc/track_info_bloc.dart';
import 'package:taxi_app/src/features/truck_info/presentation/screens/track_info.dart';
import 'package:taxi_app/src/features/worker_info/presentation/pages/worker_info_page.dart';
import 'package:taxi_app/src/routes/pages.dart';

import '../features/chat/data/repo/chat_repo_imp.dart';
import '../features/chat/data/source/chat_data_source.dart';
import '../features/chat/presentation/bloc/chat_bloc.dart';
import '../features/choose_inivates/data/source/active_order_source.dart';
import '../features/map/data/repo/map_repo_imp.dart';
import '../features/map/data/source/map_data_source.dart';

class Routes {
  static final GoRouter router = GoRouter(
    initialLocation: StorageRepository.getString('token').isNotEmpty ? Pages.main : Pages.signIn,
    observers: [ChuckerFlutter.navigatorObserver],
    routes: [
      GoRoute(
        path: Pages.signIn,
        builder: (context, state) {
          return BlocProvider(
            create: (context) => AuthBloc(authRepo: AuthRepoImpl(authDataSource: AuthDataSource())),
            child: SignInPage(),
          );
        },
      ),
      GoRoute(
        path: Pages.signUp,
        builder: (context, state) {
          return BlocProvider(
            create: (context) => AuthBloc(authRepo: AuthRepoImpl(authDataSource: AuthDataSource())),
            child: SignUpPage(),
          );
        },
      ),
      GoRoute(
        path: Pages.chat,
        builder: (context, state) {
          final extra = (state.extra as Map<String, dynamic>?) ?? const {};
          return BlocProvider(
            create: (context) => ChatBloc(chatRepo: ChatRepoImpl(chatDataSource: ChatDataSource())),
            child: ChatPage(
              address: (extra['address'] as String?) ?? '',
              latitude: (extra['latitude'] as num?)?.toDouble() ?? 0.0,
              longitude: (extra['longitude'] as num?)?.toDouble() ?? 0.0,
            ),
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
            create: (context) => MapBloc(mapRepo: MapRepoImpl(dataSource: MapDataSource())),
            child: const LocationPickerScreen(),
          );
        },
      ),
      GoRoute(
        path: Pages.home,
        builder: (context, state) {
          return BlocProvider(
            create: (context) => HomeBloc(HomeRepositoryImpl(dataSource: HomeDataSource())),
            child: HomeScreen(),
          );
        },
      ),
      GoRoute(
        path: Pages.main,
        builder: (context, state) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => HomeBloc(HomeRepositoryImpl(dataSource: HomeDataSource()))),
              BlocProvider(
                create: (context) =>
                    MasterBloc(MasterRepositoryImpl(MasterRemoteDataSource()), serviceLocator<LocationService>()),
              ),
              BlocProvider(
                create: (_) => AuthBloc(
                  authRepo: AuthRepoImpl(authDataSource: AuthDataSource()),
                ),
              ),
            ],
            child: MainScreen(),
          );
        },
      ),
      GoRoute(
        path: Pages.tackScreen,
        builder: (context, state) => BlocProvider(
          create: (_) => TrackInfoBloc(driverInfoRepo: DriverInfoRepoImpl(driverInfoSource: DriverInfoSource())),
          child: TrackInfoScreen(),
        ),
      ),
      GoRoute(
        path: Pages.invatesPage,
        builder: (context, state) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => InivitesBloc(
                  activeOrderRepository: ActiveOrderRepositoryImpl(activeOrderSource: ActiveOrderSource()),
                )..add(FetchActiveOrderEvent()),
              ),
              BlocProvider(create: (context) => ProposalBloc(HomeRepositoryImpl(dataSource: HomeDataSource()))),
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
        path: Pages.proccessOrder,
        builder: (context, state) => const OrderSingleScreen(),
      ),
      GoRoute(path: Pages.orderInfo, builder: (context, state) => const OrderInfoScreen()),
      GoRoute(path: Pages.ordersHistory, builder: (context, state) => const OrdersHistoryScreen()),
      GoRoute(
        path: Pages.orderHistoryDetail,
        builder: (context, state) => OrderHistorySingleScreen(orderId: (state.extra as Map)['id']),
      ),
      GoRoute(
        path: Pages.searchLocation,
        builder: (context, state) => BlocProvider(
          create: (context) => MapBloc(mapRepo: MapRepoImpl(dataSource: MapDataSource())),
          child: const LocationPickerScreen(),
        ),
      ),

      GoRoute(path: Pages.finishedOrder, builder: (context, state) => const FinishedOrderScreen()),
      GoRoute(
        path: Pages.forgotPasswordEmail,
        builder: (context, state) {
          return BlocProvider(
            create: (_) => ForgotPasswordBloc(
              authRepo: AuthRepoImpl(authDataSource: AuthDataSource()),
            ),
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
            create: (_) => ForgotPasswordBloc(
              authRepo: AuthRepoImpl(authDataSource: AuthDataSource()),
              seedResetToken: resetToken,
            ),
            child: const ResetPasswordPage(),
          );
        },
      ),
    ],
  );
}
