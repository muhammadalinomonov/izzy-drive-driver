import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/firebase_options.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import 'package:taxi_app/src/core/theme/app_theme.dart';
import 'package:taxi_app/src/core/utils/notifications.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/bloc/orders_bloc.dart';
import 'package:taxi_app/src/features/profile/data/repository/profile_repository_impl.dart';
import 'package:taxi_app/src/features/profile/data/source/profile_data_source.dart';
import 'package:taxi_app/src/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:taxi_app/src/routes/app_router.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await setupLocator();
  await PushNotifications.initFCM();
  ChuckerFlutter.showOnRelease = true;
  ChuckerFlutter.showNotification = false;
  runApp(TaxiApp());
}

class TaxiApp extends StatelessWidget {
  const TaxiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: OrdersBloc()),
        BlocProvider.value(value: ProfileBloc(ProfileRepositoryImpl(ProfileDataSource()))),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Izzy Drive Client',
        theme: AppTheme.light,
        routerConfig: Routes.router,
        builder: (context, child) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPress: () => ChuckerFlutter.showChuckerScreen(),
            child: child,
          );
        },
      ),
    );
  }
}
