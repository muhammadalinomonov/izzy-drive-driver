import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import 'package:taxi_app/src/core/theme/app_theme.dart';
import 'package:taxi_app/src/routes/app_router.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();

  runApp(TaxiApp());
}

class TaxiApp extends StatelessWidget {
  const TaxiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Taxi app',
      theme: AppTheme.light,
      routerConfig: Routes.router,
    );
  }
}
