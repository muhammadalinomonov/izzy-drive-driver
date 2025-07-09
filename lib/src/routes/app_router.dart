import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:taxi_app/src/features/auth/data/repo/auth_repo_impl.dart';
import 'package:taxi_app/src/features/auth/data/source/auth_data_source.dart';
import 'package:taxi_app/src/features/auth/presentation/bloc/bloc/auth_bloc.dart';
import 'package:taxi_app/src/features/auth/presentation/pages/sign_in_page.dart';
import 'package:taxi_app/src/features/auth/presentation/pages/sign_up_page.dart';
import 'package:taxi_app/src/features/chat/presentation/pages/chat_page.dart';
import 'package:taxi_app/src/features/map/presenation/pages/map_screen.dart';
import 'package:taxi_app/src/features/truck_info/data/repo/driver_info_repo_impl.dart';
import 'package:taxi_app/src/features/truck_info/data/source/driver_info_source.dart';
import 'package:taxi_app/src/features/truck_info/presentation/bloc/bloc/track_info_bloc.dart';
import 'package:taxi_app/src/features/truck_info/presentation/screens/track_info.dart';
import 'package:taxi_app/src/routes/pages.dart';

class Routes {
  static final GoRouter router = GoRouter(
    initialLocation: StorageRepository.getString('token').isNotEmpty
        ? Pages.chat
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
          return ChatPage();
        },
      ),
      GoRoute(
        path: Pages.map,
        builder: (context, state) {
          return MapScreen();
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
    ],
  );
}
