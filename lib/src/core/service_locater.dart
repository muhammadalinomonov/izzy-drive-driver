import 'package:get_it/get_it.dart';
import 'package:taxi_app/src/core/network/dio_model.dart';
import 'package:taxi_app/src/core/network/token_service.dart';

final serviceLocator = GetIt.I;

Future<void> setupLocator() async {
  await StorageRepository.getInstance();
  serviceLocator.registerLazySingleton(DioSettings.new);
}

Future resetLocator() async {
  await serviceLocator.reset();
  setupLocator();
}
