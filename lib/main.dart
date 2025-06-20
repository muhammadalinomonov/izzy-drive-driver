import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/theme/app_theme.dart';
import 'package:taxi_app/src/routes/app_router.dart';

void main(List<String> args) {
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
