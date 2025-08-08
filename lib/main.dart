import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanic/assets/theme/theme.dart';
import 'package:mechanic/core/utils/service_locator.dart';
import 'package:mechanic/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mechanic/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:mechanic/features/auth/presentation/blocs/authentication/authentication_bloc.dart';
import 'package:mechanic/features/auth/presentation/screens/auth_screen.dart';
import 'package:mechanic/features/main/presentation/blocs/orders/orders_bloc.dart';
import 'package:mechanic/features/main/presentation/screens/main_screen.dart';
import 'package:mechanic/features/profile/presentation/blocs/profile_bloc.dart';
import 'package:mechanic/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // await Firebase.initializeApp();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await setUpLocator();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  NavigatorState get navigator => MyApp.navigatorKey.currentState!;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create:(_) =>  AuthenticationBloc()..add(AuthInitialEvent())),
        BlocProvider(create:(_) =>  AuthBloc()),
        BlocProvider(create:(_) =>  ProfileBloc()),
        BlocProvider(create:(_) =>  OrdersBloc()),
      ],
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1)),
        child: MaterialApp(
          title: 'Drive Mechanic',
          theme: AppTheme.themeData,
          navigatorKey: MyApp.navigatorKey,
          onGenerateRoute: (settings) => CupertinoPageRoute(
            builder: (context) => Scaffold(),
          ),
          builder: (context, child) {
            return BlocListener<AuthenticationBloc, AuthenticationState>(
              listener: (context, state) {
                switch (state.status) {
                  case AuthenticationStatus.authenticated:
                    navigator.pushAndRemoveUntil(
                        CupertinoPageRoute(
                          builder: (context) => const MainScreen(),
                        ),
                        (route) => false);
                    break;
                  case AuthenticationStatus.unauthenticated:
                    navigator.pushAndRemoveUntil(
                        CupertinoPageRoute(
                          builder: (context) => const AuthScreen(),
                        ),
                        (route) => false);
                    break;
                }
              },
              child: child!,
            );
          },
        ),
      ),
    );
  }
}
