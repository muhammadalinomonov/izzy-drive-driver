import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:taxi_app/src/core/network/injection.config.dart';

final sl = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async => sl.init();
