import 'package:injectable/injectable.dart';
import 'package:taxi_app/core/location_service.dart';
import 'package:taxi_app/core/network/dio_model.dart';
import 'package:taxi_app/core/network/toll_dio.dart';
import 'package:taxi_app/core/network/token_service.dart';
import 'package:taxi_app/core/services/connectivity_service.dart';
import 'package:taxi_app/core/services/websocket_service.dart';

/// Bindings for types this app doesn't own the constructors of, or that need
/// async setup before anything can use them.
///
/// Classes we DO own are annotated in place (`@lazySingleton` / `@injectable`)
/// rather than listed here.
@module
abstract class RegisterModule {
  /// SharedPreferences-backed. Every `StorageRepository.getX` is static and
  /// silently returns empty values until `_preferences` is populated, so this
  /// has to resolve before the first route is built — hence `@preResolve`.
  @preResolve
  @lazySingleton
  Future<StorageRepository> get storage => StorageRepository.getInstance();

  /// Owns a platform stream subscription that `init()` opens. Pre-resolved so
  /// `ConnectivityCubit` never reads a service that hasn't started listening.
  @preResolve
  @lazySingleton
  Future<ConnectivityService> get connectivity async {
    final service = ConnectivityService();
    await service.init();
    return service;
  }

  /// Main IzzyDrive API client.
  @lazySingleton
  DioSettings get dioSettings => DioSettings();

  /// Quadrix Tolling backend — separate host + auth scheme, see TollDioSettings.
  @lazySingleton
  TollDioSettings get tollDioSettings => TollDioSettings();

  @lazySingleton
  LocationService get locationService => LocationService();

  @lazySingleton
  WebSocketService get webSocketService => WebSocketService();
}
