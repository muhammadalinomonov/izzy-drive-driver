
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:mechanic/core/network/dio_optionts.dart';
import 'package:mechanic/core/storage/storage_repository.dart';
import 'package:mechanic/features/auth/data/data_sources/auth_data_source.dart';
import 'package:mechanic/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mechanic/features/auth/domain/repositories/auth_repository.dart';
import 'package:mechanic/features/main/data/datasources/orders_datasource.dart';
import 'package:mechanic/features/main/data/repositories/orders_repository_impl.dart';
import 'package:mechanic/features/main/domain/repositories/orders_repository.dart';
import 'package:mechanic/features/profile/data/datasources/profile_datasource.dart';
import 'package:mechanic/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:mechanic/features/profile/domain/repositories/profile_repository.dart';

final serviceLocator = GetIt.instance;

Future<void> setUpLocator() async {
  await StorageRepository.getInstance();

  serviceLocator.registerLazySingleton<Dio>(() => DioOptions().dio);

  ///data sources
  serviceLocator.registerLazySingleton<AuthDataSource>(() => AuthDataSourceImpl(dio: serviceLocator.call<Dio>()));
  serviceLocator.registerLazySingleton<ProfileDataSource>(() => ProfileDataSourceImpl(dio: serviceLocator.call<Dio>()));
  serviceLocator.registerLazySingleton<OrdersDataSource>(() => OrdersDataSourceImpl(dio: serviceLocator.call<Dio>()));
  // serviceLocator.registerLazySingleton<CardDataSource>(() => CardDataSourceImpl(dio: serviceLocator.call<Dio>()));
  //
  ///repositories
  serviceLocator.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(dataSource: serviceLocator.call<AuthDataSource>()));
  serviceLocator.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(dataSource: serviceLocator.call<ProfileDataSource>()));
  serviceLocator.registerLazySingleton<OrdersRepository>(
      () => OrdersRepositoryImpl(dataSource: serviceLocator.call<OrdersDataSource>()));
  // serviceLocator.registerLazySingleton<CardRepository>(
  //     () => CardRepositoryImpl(dataSource: serviceLocator.call<CardDataSource>()));



}
