import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/firebase_options.dart';
import 'package:taxi_app/core/network/token_service.dart';
import 'package:taxi_app/core/service_locater.dart';
import 'package:taxi_app/core/services/connectivity_service.dart';
import 'package:taxi_app/core/theme/app_theme.dart';
import 'package:taxi_app/core/utils/notifications.dart';
import 'package:taxi_app/features/common/presentation/cubits/connectivity/connectivity_cubit.dart';
import 'package:taxi_app/features/common/presentation/widgets/no_internet_bottom_sheet.dart';
import 'package:taxi_app/features/order_proccess/data/order_proccess_source.dart';
import 'package:taxi_app/features/order_proccess/domain/order_repo.dart';
import 'package:taxi_app/features/order_proccess/presentation/bloc/orders_bloc.dart';
import 'package:taxi_app/features/profile/data/repository/profile_repository_impl.dart';
import 'package:taxi_app/features/profile/data/source/profile_data_source.dart';
import 'package:taxi_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:taxi_app/core/services/remote_config_service.dart';
import 'package:taxi_app/routes/app_router.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await RemoteConfigService.init();
  await setupLocator();
  await PushNotifications.initFCM();
  ChuckerFlutter.showOnRelease = true;
  ChuckerFlutter.showNotification = false;

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      saveLocale: false,
      child: const TaxiApp(),
    ),
  );
}

class TaxiApp extends StatefulWidget {
  const TaxiApp({super.key});

  @override
  State<TaxiApp> createState() => _TaxiAppState();
}

class _TaxiAppState extends State<TaxiApp> {
  bool _isSheetShowing = false;
  bool _initialConnectivityChecked = false;

  @override
  void initState() {
    super.initState();

    // StorageRepository.deleteString('token');
    // StorageRepository.deleteString('refresh');
  }

  void _maybeShowSheet() {
    if (_isSheetShowing) return;
    // MaterialApp.router's builder context lives ABOVE the Navigator
    // created by the routerDelegate, so showModalBottomSheet there
    // crashes with "Navigator operation requested with a context that
    // does not include a Navigator". GoRouter exposes the root
    // navigator key - its currentContext IS the Navigator's context.
    final navCtx = Routes.router.routerDelegate.navigatorKey.currentContext;
    if (navCtx == null) return;
    _isSheetShowing = true;
    NoInternetBottomSheet.show(navCtx).whenComplete(() {
      _isSheetShowing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ConnectivityCubit>(
          create: (_) =>
              ConnectivityCubit(serviceLocator<ConnectivityService>()),
        ),
        BlocProvider(
          create: (_) => OrdersBloc(
            orderRepository: OrderRepositoryImpl(
              orderProccessSource: OrderProccessSource(),
            ),
          ),
        ),
        BlocProvider.value(
          value: ProfileBloc(ProfileRepositoryImpl(ProfileDataSource())),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'IzzyDrive Client',
        theme: AppTheme.light,
        routerConfig: Routes.router,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        builder: (context, child) {
          // BlocListener only fires on subsequent emissions, not on the
          // initial state. If the app boots already offline, the cubit
          // starts in `disconnected` and the listener stays silent - so
          // we run a one-shot post-frame check that opens the sheet
          // when the very first known status is offline.
          if (!_initialConnectivityChecked) {
            _initialConnectivityChecked = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final cubit = context.read<ConnectivityCubit>();
              if (cubit.state.isDisconnected) {
                _maybeShowSheet();
              }
            });
          }
          return BlocListener<ConnectivityCubit, ConnectivityState>(
            listenWhen: (p, c) => p.status != c.status,
            listener: (context, state) {
              if (state.isDisconnected) {
                _maybeShowSheet();
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onLongPress: () {
                final email = StorageRepository.getString('email');
                if (email.contains('quadrixmail')) {
                  ChuckerFlutter.showChuckerScreen();
                }
              },
              child: child,
            ),
          );
        },
      ),
    );
  }
}
