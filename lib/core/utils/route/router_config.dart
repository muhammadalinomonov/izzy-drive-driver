import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:mechanic/features/auth/presentation/screens/auth_screen.dart';

class GoRouterConfig {
  GoRouterConfig._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String fillAccountInfo = '/fill-account-info';
  static const String home = '/home-screen';
  static const String orderSingle = '/order-single';

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: splash,
    routes: [
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => AuthScreen(),
      )
    ],
  );
}
