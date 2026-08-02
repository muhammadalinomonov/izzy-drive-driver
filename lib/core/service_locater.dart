import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:taxi_app/core/di/injection.dart';

/// Kept as an alias so the ~30 existing `serviceLocator<T>()` call sites keep
/// working. New code should prefer [getIt] from `core/di/injection.dart`.
final serviceLocator = getIt;

/// App bootstrap: loads secrets, then builds the DI graph.
///
/// Registrations themselves are no longer written here — they are generated
/// from `@injectable` / `@lazySingleton` annotations into
/// `core/di/injection.config.dart`. Only genuinely global side effects that
/// aren't dependency registration (dotenv, the Mapbox SDK token) stay.
Future<void> setupLocator() async {
  await dotenv.load(fileName: '.env');
  final mapboxToken = dotenv.env['MAPBOX_ACCESS_TOKEN']!;
  assert(
    mapboxToken.startsWith('pk.'),
    'MAPBOX_ACCESS_TOKEN must be a public (pk.*) token. A secret sk.* token '
    'is extractable from the shipped app bundle.',
  );
  MapboxOptions.setAccessToken(mapboxToken);

  // Must come after dotenv: @preResolve'd singletons may read config at
  // construction time.
  await configureDependencies();
}

Future<void> resetLocator() async {
  await getIt.reset();
  await setupLocator();
}
