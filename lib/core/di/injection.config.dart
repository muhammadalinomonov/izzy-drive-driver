// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:taxi_app/core/di/register_module.dart' as _i750;
import 'package:taxi_app/core/location_service.dart' as _i120;
import 'package:taxi_app/core/network/dio_model.dart' as _i848;
import 'package:taxi_app/core/network/token_service.dart' as _i805;
import 'package:taxi_app/core/network/toll_dio.dart' as _i1047;
import 'package:taxi_app/core/services/connectivity_service.dart' as _i648;
import 'package:taxi_app/core/services/websocket_service.dart' as _i803;
import 'package:taxi_app/features/auth/data/repo/auth_repo_impl.dart' as _i200;
import 'package:taxi_app/features/auth/data/repo/auth_repo_impl_2.dart'
    as _i259;
import 'package:taxi_app/features/auth/data/source/auth2_data_source.dart'
    as _i608;
import 'package:taxi_app/features/auth/data/source/auth_data_source.dart'
    as _i922;
import 'package:taxi_app/features/auth/domain/repo/auth_repo.dart' as _i102;
import 'package:taxi_app/features/auth/presentation/bloc/bloc/auth_bloc.dart'
    as _i1069;
import 'package:taxi_app/features/auth/presentation/bloc/forgot_password_bloc/forgot_password_bloc.dart'
    as _i882;
import 'package:taxi_app/features/cancel_reasons/data/repo/cancel_reason_repo_impl.dart'
    as _i160;
import 'package:taxi_app/features/cancel_reasons/data/source/cancel_reason_data_source.dart'
    as _i1034;
import 'package:taxi_app/features/cancel_reasons/domain/repo/cancel_reason_repo.dart'
    as _i648;
import 'package:taxi_app/features/choose_inivates/data/repo/active_order_repository_imp.dart'
    as _i668;
import 'package:taxi_app/features/choose_inivates/data/source/active_order_source.dart'
    as _i612;
import 'package:taxi_app/features/choose_inivates/domain/active_order_repository.dart'
    as _i946;
import 'package:taxi_app/features/choose_inivates/presentation/bloc/inivites_bloc.dart'
    as _i204;
import 'package:taxi_app/features/choose_inivates/presentation/bloc/proposal_bloc.dart'
    as _i671;
import 'package:taxi_app/features/common/presentation/cubits/connectivity/connectivity_cubit.dart'
    as _i979;
import 'package:taxi_app/features/home/data/repository/home_repository_impl.dart'
    as _i409;
import 'package:taxi_app/features/home/data/source/home_data_source.dart'
    as _i888;
import 'package:taxi_app/features/home/domain/repository/home_repository.dart'
    as _i982;
import 'package:taxi_app/features/home/presentation/bloc/bloc/home_bloc.dart'
    as _i171;
import 'package:taxi_app/features/map/data/repo/map_repo_imp.dart' as _i407;
import 'package:taxi_app/features/map/data/source/map_data_source.dart'
    as _i409;
import 'package:taxi_app/features/map/domain/map_repo.dart' as _i425;
import 'package:taxi_app/features/map/presenation/bloc/map_bloc.dart' as _i729;
import 'package:taxi_app/features/master/data/repository/master_repository_impl.dart'
    as _i126;
import 'package:taxi_app/features/master/data/source/master_remote_data_source.dart'
    as _i417;
import 'package:taxi_app/features/master/domain/repository/master_repository.dart'
    as _i502;
import 'package:taxi_app/features/master/presentation/bloc/master_bloc.dart'
    as _i809;
import 'package:taxi_app/features/notifications/data/repo/notifications_repo_impl.dart'
    as _i208;
import 'package:taxi_app/features/notifications/data/source/notifications_data_source.dart'
    as _i433;
import 'package:taxi_app/features/notifications/domain/repo/notifications_repo.dart'
    as _i158;
import 'package:taxi_app/features/notifications/presentation/bloc/notifications_bloc.dart'
    as _i350;
import 'package:taxi_app/features/order_create/data/repo/order_create_repo_impl.dart'
    as _i336;
import 'package:taxi_app/features/order_create/data/source/order_create_data_source.dart'
    as _i127;
import 'package:taxi_app/features/order_create/domain/repo/order_create_repo.dart'
    as _i733;
import 'package:taxi_app/features/order_create/presentation/bloc/order_create_bloc.dart'
    as _i865;
import 'package:taxi_app/features/order_proccess/data/order_proccess_source.dart'
    as _i716;
import 'package:taxi_app/features/order_proccess/domain/order_repo.dart'
    as _i27;
import 'package:taxi_app/features/order_proccess/presentation/bloc/orders_bloc.dart'
    as _i79;
import 'package:taxi_app/features/phone_verify/data/repo/phone_verify_repo_impl.dart'
    as _i635;
import 'package:taxi_app/features/phone_verify/data/source/phone_verify_data_source.dart'
    as _i147;
import 'package:taxi_app/features/phone_verify/domain/repo/phone_verify_repo.dart'
    as _i995;
import 'package:taxi_app/features/phone_verify/presentation/bloc/phone_verify_bloc.dart'
    as _i131;
import 'package:taxi_app/features/profile/data/repository/profile_repository_impl.dart'
    as _i996;
import 'package:taxi_app/features/profile/data/source/profile_data_source.dart'
    as _i138;
import 'package:taxi_app/features/profile/domain/repository/profile_repository.dart'
    as _i810;
import 'package:taxi_app/features/profile/presentation/bloc/history/orders_history_bloc.dart'
    as _i550;
import 'package:taxi_app/features/profile/presentation/bloc/profile_bloc.dart'
    as _i886;
import 'package:taxi_app/features/trips/data/model/navigation_session_model.dart'
    as _i554;
import 'package:taxi_app/features/trips/data/repo/fuel_stations_repo_impl.dart'
    as _i1070;
import 'package:taxi_app/features/trips/data/repo/route_support_repo_impl.dart'
    as _i679;
import 'package:taxi_app/features/trips/data/repo/support_chat_repo_impl.dart'
    as _i488;
import 'package:taxi_app/features/trips/data/repo/trips_repo_impl.dart'
    as _i121;
import 'package:taxi_app/features/trips/data/source/fuel_stations_data_source.dart'
    as _i515;
import 'package:taxi_app/features/trips/data/source/route_support_data_source.dart'
    as _i599;
import 'package:taxi_app/features/trips/data/source/support_chat_data_source.dart'
    as _i927;
import 'package:taxi_app/features/trips/data/source/trips_data_source.dart'
    as _i627;
import 'package:taxi_app/features/trips/domain/repo/fuel_stations_repo.dart'
    as _i736;
import 'package:taxi_app/features/trips/domain/repo/route_support_repo.dart'
    as _i129;
import 'package:taxi_app/features/trips/domain/repo/support_chat_repo.dart'
    as _i589;
import 'package:taxi_app/features/trips/domain/repo/trips_repo.dart' as _i106;
import 'package:taxi_app/features/trips/presentation/bloc/navigation/navigation_bloc.dart'
    as _i317;
import 'package:taxi_app/features/trips/presentation/bloc/support_chat/support_chat_bloc.dart'
    as _i285;
import 'package:taxi_app/features/trips/presentation/bloc/trip_map/trip_map_bloc.dart'
    as _i50;
import 'package:taxi_app/features/trips/presentation/bloc/trips_bloc.dart'
    as _i869;
import 'package:taxi_app/features/truck_info/data/repo/driver_info_repo_impl.dart'
    as _i374;
import 'package:taxi_app/features/truck_info/data/source/driver_info_source.dart'
    as _i141;
import 'package:taxi_app/features/truck_info/domain/repo/driver_info_repo.dart'
    as _i677;
import 'package:taxi_app/features/truck_info/presentation/bloc/bloc/track_info_bloc.dart'
    as _i822;
import 'package:taxi_app/features/worker_info/data/repo/worker_info_repo_impl.dart'
    as _i432;
import 'package:taxi_app/features/worker_info/domain/repo/worker_info_repo.dart'
    as _i889;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    await gh.lazySingletonAsync<_i805.StorageRepository>(
      () => registerModule.storage,
      preResolve: true,
    );
    await gh.lazySingletonAsync<_i648.ConnectivityService>(
      () => registerModule.connectivity,
      preResolve: true,
    );
    gh.lazySingleton<_i848.DioSettings>(() => registerModule.dioSettings);
    gh.lazySingleton<_i1047.TollDioSettings>(
      () => registerModule.tollDioSettings,
    );
    gh.lazySingleton<_i120.LocationService>(
      () => registerModule.locationService,
    );
    gh.lazySingleton<_i803.WebSocketService>(
      () => registerModule.webSocketService,
    );
    gh.lazySingleton<_i888.HomeDataSource>(() => _i888.HomeDataSource());
    gh.lazySingleton<_i127.OrderCreateDataSource>(
      () => _i127.OrderCreateDataSource(),
    );
    gh.lazySingleton<_i716.OrderProccessSource>(
      () => _i716.OrderProccessSource(),
    );
    gh.lazySingleton<_i147.PhoneVerifyDataSource>(
      () => _i147.PhoneVerifyDataSource(),
    );
    gh.lazySingleton<_i922.AuthDataSource>(() => _i922.AuthDataSource());
    gh.lazySingleton<_i1034.CancelReasonDataSource>(
      () => _i1034.CancelReasonDataSource(),
    );
    gh.lazySingleton<_i409.MapDataSource>(() => _i409.MapDataSource());
    gh.lazySingleton<_i612.ActiveOrderSource>(() => _i612.ActiveOrderSource());
    gh.lazySingleton<_i138.ProfileDataSource>(() => _i138.ProfileDataSource());
    gh.lazySingleton<_i417.MasterRemoteDataSource>(
      () => _i417.MasterRemoteDataSource(),
    );
    gh.lazySingleton<_i141.DriverInfoSource>(() => _i141.DriverInfoSource());
    gh.lazySingleton<_i627.TripsDataSource>(() => _i627.TripsDataSource());
    gh.lazySingleton<_i433.NotificationsDataSource>(
      () => _i433.NotificationsDataSource(),
    );
    gh.lazySingleton<_i515.FuelStationsDataSource>(
      () => _i515.FuelStationsDataSource(),
    );
    gh.lazySingleton<_i599.RouteSupportDataSource>(
      () => _i599.RouteSupportDataSource(),
    );
    gh.lazySingleton<_i927.SupportChatDataSource>(
      () => _i927.SupportChatDataSource(),
    );
    gh.lazySingleton<_i608.Auth2DataSource>(() => _i608.Auth2DataSource());
    gh.lazySingleton<_i27.OrderRepository>(
      () => _i27.OrderRepositoryImpl(
        orderProccessSource: gh<_i716.OrderProccessSource>(),
      ),
    );
    gh.lazySingleton<_i158.NotificationsRepo>(
      () => _i208.NotificationsRepoImpl(
        dataSource: gh<_i433.NotificationsDataSource>(),
      ),
    );
    gh.lazySingleton<_i810.ProfileRepository>(
      () => _i996.ProfileRepositoryImpl(gh<_i138.ProfileDataSource>()),
    );
    gh.lazySingleton<_i982.HomeRepository>(
      () => _i409.HomeRepositoryImpl(dataSource: gh<_i888.HomeDataSource>()),
    );
    gh.lazySingleton<_i995.PhoneVerifyRepo>(
      () => _i635.PhoneVerifyRepoImpl(
        dataSource: gh<_i147.PhoneVerifyDataSource>(),
      ),
    );
    gh.lazySingleton<_i648.CancelReasonRepo>(
      () => _i160.CancelReasonRepoImpl(
        dataSource: gh<_i1034.CancelReasonDataSource>(),
      ),
    );
    gh.lazySingleton<_i502.MasterRepository>(
      () => _i126.MasterRepositoryImpl(gh<_i417.MasterRemoteDataSource>()),
    );
    gh.lazySingleton<_i425.MapRepo>(
      () => _i407.MapRepoImpl(dataSource: gh<_i409.MapDataSource>()),
    );
    gh.factory<_i550.OrdersHistoryBloc>(
      () => _i550.OrdersHistoryBloc(gh<_i810.ProfileRepository>()),
    );
    gh.lazySingleton<_i733.OrderCreateRepo>(
      () => _i336.OrderCreateRepoImpl(
        dataSource: gh<_i127.OrderCreateDataSource>(),
      ),
    );
    gh.lazySingleton<_i736.FuelStationsRepo>(
      () => _i1070.FuelStationsRepoImpl(
        dataSource: gh<_i515.FuelStationsDataSource>(),
      ),
    );
    gh.lazySingleton<_i102.AuthRepo>(
      () => _i259.AuthRepoImpl2(auth2DataSource: gh<_i608.Auth2DataSource>()),
      instanceName: 'auth2',
    );
    gh.factory<_i671.ProposalBloc>(
      () => _i671.ProposalBloc(gh<_i982.HomeRepository>()),
    );
    gh.factory<_i865.OrderCreateBloc>(
      () => _i865.OrderCreateBloc(repo: gh<_i733.OrderCreateRepo>()),
    );
    gh.lazySingleton<_i889.WorkerInfoRepo>(() => _i432.WorkerInfoRepoImpl());
    gh.factory<_i350.NotificationsBloc>(
      () => _i350.NotificationsBloc(repo: gh<_i158.NotificationsRepo>()),
    );
    gh.lazySingleton<_i106.TripsRepo>(
      () => _i121.TripsRepoImpl(dataSource: gh<_i627.TripsDataSource>()),
    );
    gh.lazySingleton<_i946.ActiveOrderRepository>(
      () => _i668.ActiveOrderRepositoryImpl(
        activeOrderSource: gh<_i612.ActiveOrderSource>(),
      ),
    );
    gh.lazySingleton<_i102.AuthRepo>(
      () => _i200.AuthRepoImpl(authDataSource: gh<_i922.AuthDataSource>()),
      instanceName: 'auth1',
    );
    gh.factory<_i729.MapBloc>(
      () => _i729.MapBloc(mapRepo: gh<_i425.MapRepo>()),
    );
    gh.lazySingleton<_i677.DriverInfoRepo>(
      () => _i374.DriverInfoRepoImpl(
        driverInfoSource: gh<_i141.DriverInfoSource>(),
      ),
    );
    gh.lazySingleton<_i589.SupportChatRepo>(
      () => _i488.SupportChatRepoImpl(
        dataSource: gh<_i927.SupportChatDataSource>(),
      ),
    );
    gh.factory<_i131.PhoneVerifyBloc>(
      () => _i131.PhoneVerifyBloc(repo: gh<_i995.PhoneVerifyRepo>()),
    );
    gh.factory<_i171.HomeBloc>(
      () => _i171.HomeBloc(gh<_i982.HomeRepository>()),
    );
    gh.lazySingleton<_i129.RouteSupportRepo>(
      () => _i679.RouteSupportRepoImpl(
        dataSource: gh<_i599.RouteSupportDataSource>(),
      ),
    );
    gh.factory<_i869.TripsBloc>(
      () => _i869.TripsBloc(repo: gh<_i106.TripsRepo>()),
    );
    gh.factory<_i285.SupportChatBloc>(
      () => _i285.SupportChatBloc(repo: gh<_i589.SupportChatRepo>()),
    );
    gh.factory<_i979.ConnectivityCubit>(
      () => _i979.ConnectivityCubit(gh<_i648.ConnectivityService>()),
    );
    gh.factory<_i79.OrdersBloc>(
      () => _i79.OrdersBloc(orderRepository: gh<_i27.OrderRepository>()),
    );
    gh.factory<_i886.ProfileBloc>(
      () => _i886.ProfileBloc(gh<_i810.ProfileRepository>()),
    );
    gh.factoryParam<
      _i317.NavigationBloc,
      _i554.NavigationSessionModel?,
      dynamic
    >(
      (initialSession, _) => _i317.NavigationBloc(
        initialSession: initialSession,
        repo: gh<_i106.TripsRepo>(),
        locationService: gh<_i120.LocationService>(),
      ),
    );
    gh.factoryParam<_i882.ForgotPasswordBloc, String?, dynamic>(
      (seedResetToken, _) => _i882.ForgotPasswordBloc(
        authRepo: gh<_i102.AuthRepo>(instanceName: 'auth1'),
        seedResetToken: seedResetToken,
      ),
    );
    gh.factory<_i809.MasterBloc>(
      () => _i809.MasterBloc(
        gh<_i502.MasterRepository>(),
        gh<_i120.LocationService>(),
      ),
    );
    gh.factory<_i50.TripMapBloc>(
      () => _i50.TripMapBloc(
        repo: gh<_i106.TripsRepo>(),
        locationService: gh<_i120.LocationService>(),
        fuelStationsRepo: gh<_i736.FuelStationsRepo>(),
      ),
    );
    gh.factory<_i1069.AuthBloc>(
      () =>
          _i1069.AuthBloc(authRepo: gh<_i102.AuthRepo>(instanceName: 'auth2')),
    );
    gh.factory<_i204.InivitesBloc>(
      () => _i204.InivitesBloc(
        activeOrderRepository: gh<_i946.ActiveOrderRepository>(),
      ),
    );
    gh.factory<_i822.TrackInfoBloc>(
      () => _i822.TrackInfoBloc(driverInfoRepo: gh<_i677.DriverInfoRepo>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i750.RegisterModule {}
