import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:taxi_app/src/features/auth/data/repo/auth_repo_impl.dart';
import 'package:taxi_app/src/features/auth/data/source/auth_data_source.dart';
import 'package:taxi_app/src/features/auth/presentation/bloc/bloc/auth_bloc.dart';
import 'package:taxi_app/src/features/auth/presentation/pages/sign_in_page.dart';
import 'package:taxi_app/src/features/auth/presentation/pages/sign_up_page.dart';
import 'package:taxi_app/src/features/chat/presentation/pages/chat_page.dart';
import 'package:taxi_app/src/features/choose_inivates/presentation/pages/invates_screen.dart';
import 'package:taxi_app/src/features/home/data/repository/home_repository_impl.dart';
import 'package:taxi_app/src/features/home/data/source/home_data_source.dart';
import 'package:taxi_app/src/features/home/presentation/bloc/bloc/home_bloc.dart';
import 'package:taxi_app/src/features/home/presentation/screens/home_screen.dart';
import 'package:taxi_app/src/features/home/presentation/screens/main_screen.dart';
import 'package:taxi_app/src/features/map/presenation/bloc/map_bloc.dart';
import 'package:taxi_app/src/features/map/presenation/pages/map_screen.dart';
import 'package:taxi_app/src/features/truck_info/data/repo/driver_info_repo_impl.dart';
import 'package:taxi_app/src/features/truck_info/data/source/driver_info_source.dart';
import 'package:taxi_app/src/features/truck_info/presentation/bloc/bloc/track_info_bloc.dart';
import 'package:taxi_app/src/features/truck_info/presentation/screens/track_info.dart';
import 'package:taxi_app/src/features/worker_info/presentation/pages/worker_info_page.dart';
import 'package:taxi_app/src/routes/pages.dart';

import '../features/chat/data/repo/chat_repo_imp.dart';
import '../features/chat/data/source/chat_data_source.dart';
import '../features/chat/presentation/bloc/chat_bloc.dart';
import '../features/map/data/repo/map_repo_imp.dart';
import '../features/map/data/source/map_data_source.dart';

class Routes {
  static final GoRouter router = GoRouter(
    initialLocation: StorageRepository.getString('token').isNotEmpty
        ? Pages.main
        : Pages.signIn,
    routes: [
      GoRoute(
        path: Pages.signIn,
        builder: (context, state) {
          return BlocProvider(
            create: (context) => AuthBloc(
              authRepo: AuthRepoImpl(authDataSource: AuthDataSource()),
            ),
            child: SignInPage(),
          );
        },
      ),
      GoRoute(
        path: Pages.signUp,
        builder: (context, state) {
          return BlocProvider(
            create: (context) => AuthBloc(
              authRepo: AuthRepoImpl(authDataSource: AuthDataSource()),
            ),
            child: SignUpPage(),
          );
        },
      ),
      GoRoute(
        path: Pages.chat,
        builder: (context, state) {
          return BlocProvider(
            create: (context) => ChatBloc(
              chatRepo: ChatRepoImpl(chatDataSource: ChatDataSource()),
            ),
            child: ChatPage(),
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
                MapBloc(mapRepo: MapRepoImpl(dataSource: MapDataSource())),
            child: MapScreen(),
          );
        },
      ),
      GoRoute(
        path: Pages.home,
        builder: (context, state) {
          return BlocProvider(
            create: (context) =>
                HomeBloc(HomeRepositoryImpl(dataSource: HomeDataSource())),
            child: HomeScreen(),
          );
        },
      ),
      GoRoute(
        path: Pages.main,
        builder: (context, state) {
          return BlocProvider(
            create: (context) =>
                HomeBloc(HomeRepositoryImpl(dataSource: HomeDataSource())),
            child: MainScreen(),
          );
        },
      ),
      GoRoute(
        path: Pages.tackScreen,
        builder: (context, state) => BlocProvider(
          create: (_) => TrackInfoBloc(
            driverInfoRepo: DriverInfoRepoImpl(
              driverInfoSource: DriverInfoSource(),
            ),
          ),
          child: TrackInfoScreen(),
        ),
      ),
      GoRoute(
        path: Pages.invatesPage,
        builder: (context, state) {
          return InvatesScreen();
        },

      ),
    ],
  );
}
