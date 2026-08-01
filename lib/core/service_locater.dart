import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:taxi_app/core/network/dio_model.dart';
import 'package:taxi_app/core/network/toll_dio.dart';
import 'package:taxi_app/core/network/token_service.dart';
import 'package:taxi_app/core/location_service.dart';
import 'package:taxi_app/core/services/connectivity_service.dart';
import 'package:taxi_app/core/services/websocket_service.dart';


final serviceLocator = GetIt.I;

Future<void> setupLocator() async {
  await StorageRepository.getInstance();
  final connectivityService = ConnectivityService();
  await connectivityService.init();
  serviceLocator.registerLazySingleton<ConnectivityService>(() => connectivityService);
  serviceLocator.registerLazySingleton(DioSettings.new);
  // Quadrix Tolling backend - separate host + auth scheme, see TollDioSettings.
  serviceLocator.registerLazySingleton(TollDioSettings.new);
  serviceLocator.registerLazySingleton(LocationService.new);
  serviceLocator.registerLazySingleton(WebSocketService.new);

  await dotenv.load(fileName: '.env');
  final mapboxToken = dotenv.env['MAPBOX_ACCESS_TOKEN']!;
  assert(
    mapboxToken.startsWith('pk.'),
    'MAPBOX_ACCESS_TOKEN must be a public (pk.*) token. A secret sk.* token '
    'is extractable from the shipped app bundle.',
  );
  MapboxOptions.setAccessToken(mapboxToken);
}

Future resetLocator() async {
  await serviceLocator.reset();
  setupLocator();
}
