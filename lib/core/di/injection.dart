import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:taxi_app/core/di/injection.config.dart';

/// The app's single [GetIt] instance.
///
/// Also exported as `serviceLocator` from `core/service_locater.dart` for the
/// call sites that predate this file — both names resolve to `GetIt.I`.
final getIt = GetIt.instance;

/// Wires every `@injectable`-annotated class plus the third-party bindings in
/// [RegisterModule]. Generated into `injection.config.dart` by
/// `dart run build_runner build --delete-conflicting-outputs`.
///
/// Awaits: some singletons (`StorageRepository`, `ConnectivityService`) need
/// async setup and are `@preResolve`d, so this must complete before `runApp`.
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: false,
  asExtension: true,
)
Future<void> configureDependencies() => getIt.init();
