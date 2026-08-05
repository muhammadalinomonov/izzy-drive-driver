# CLAUDE.md

Guidance for Claude Code (claude.ai/code) when working in this repository.

## Project

Flutter app ("Drive Driver" / pubspec name `taxi_app`) — the **driver-side** client for the IzzyDrive roadside-assistance platform. Backend is `https://api.izzydrive.com/api/v1/`. Dart SDK `^3.8.1`.

There is a sister app — the mechanic-side client — at:
```
/Users/javoxir/StudioProjects/mechanic-app
```
Both apps share the same backend and parts of the auth/storage/FCM stack. When porting from there, follow the rules in [Sister-project porting](#sister-project-porting) — never copy mechanic-app's conventions wholesale; adapt to this repo's existing patterns.

## Common commands

```bash
flutter pub get
flutter run
flutter analyze
flutter test
flutter build apk / flutter build ios
dart run build_runner build --delete-conflicting-outputs
```

iOS-only setup: `cd ios && pod install` after touching native plugins.

`.env` file is required at repo root (`MAPBOX_ACCESS_TOKEN=…`) — `setupLocator` calls `dotenv.load` and crashes on missing keys.

## Architecture (THIS repo's conventions — preserve them)

There is **no `lib/src/` layer** — it was removed and `core/`, `features/` and
`routes/` now sit directly under `lib/`. Imports read
`package:taxi_app/features/…`, with no `src` segment.

```
lib/
  main.dart                           # WidgetsFlutterBinding + setupLocator + runApp
  firebase_options.dart
  core/
    service_locater.dart              # NOTE: typo "locater" is intentional, kept for git-blame stability
    network/
      api_constants.dart
      dio_model.dart
      network_response.dart           # final result type — { errorText, data<T> }
      token_service.dart              # contains StorageRepository (SharedPreferences singleton)
    exeptions/                        # NOTE: typo "exeptions" is intentional, kept
    extensions/
    theme/
    utils/
      unit_format.dart                # miles/duration formatting — single source, see below
    components/
    widgets/
      app_skeleton.dart               # AppSkeleton / SkeletonBox — the ONLY shimmer config
    constants/
    enums/
    location_service.dart
  features/<feature>/
    data/
      model/                          # singular — *_model.dart with @JsonSerializable
      source/                         # singular — *_data_source.dart, calls Dio
      repo/                           # singular — *_repo_impl.dart extends abstract repo
    domain/
      repo/                           # singular — abstract repo only; NO entities, NO usecases
    presentation/
      bloc/                           # may be nested as bloc/bloc/ in some features
      pages/                          # singular — *_page.dart or *_screen.dart
      widgets/
  routes/
    app_router.dart                   # GoRouter — single Routes.router static field
    pages.dart                        # static String constants for paths
```

### Conventions to preserve

- **Result type is `NetworkResponse<T>`** (`core/network/network_response.dart`) — `{ String errorText, T? data }`. Repos return `Future<NetworkResponse<T>>`. Empty `errorText` = success. **Do NOT introduce `Either<L, R>` / `dartz` / sealed `Failure` types** — this repo doesn't use them, and mixing in one feature creates inconsistency.

- **DI is GetIt + `injectable` code generation.** Nothing is registered by hand.
  Annotate the class and re-run the generator:
  ```dart
  @lazySingleton class AuthDataSource { … }                  // data sources
  @LazySingleton(as: AuthRepo) class AuthRepoImpl … { … }     // repos, bound to the abstraction
  @injectable class AuthBloc extends Bloc<…> { … }            // blocs/cubits — new instance each resolve
  ```
  ```dart
  GoRoute(
    path: Pages.signIn,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<AuthBloc>(),
      child: SignInPage(),
    ),
  ),
  ```
  - Graph root is `core/di/injection.dart` (`getIt`, `configureDependencies()`);
    generated output is `core/di/injection.config.dart` — **never edit it**.
  - Run `dart run build_runner build --delete-conflicting-outputs` after adding
    or changing any annotation. Forgetting this is the usual cause of a
    "type not registered" crash at runtime.
  - Types we don't own, or that need async setup, go in `core/di/register_module.dart`.
    `StorageRepository` and `ConnectivityService` are `@preResolve`d, so
    `configureDependencies()` must be awaited before `runApp`.
  - `serviceLocator` (in `core/service_locater.dart`) is a back-compat alias for
    `getIt`. Prefer `getIt` in new code.
  - **Blocs are `@injectable` (factory), never singletons** — a closed bloc
    cannot be reused, and a singleton bloc leaks state across routes.
  - **Runtime constructor arguments** use `@factoryParam` (max two), resolved as
    `getIt<NavigationBloc>(param1: session)`. A bloc needing more than two —
    `RouteOverviewBloc` takes trip + origin + destination — stays hand-built in
    its route builder, with only its *dependencies* pulled from `getIt`.

- **Domain is thin.** Each feature has only `domain/repo/<feature>_repo.dart` (abstract class). **No entities, no use cases.** Models in `data/model/` double as DTOs and as the type carried through the bloc/UI layer. Don't introduce a `domain/entities/` folder unless the user asks.

- **BLoCs use callback events, not stream-based auth status.** Pattern from `auth_bloc.dart`:
  ```dart
  on<LoginEvent>((event, emit) async {
    emit(AuthState(status: AuthStatus.loading));
    final response = await authRepo.logIn(event.authModel);
    if (response.errorText.isEmpty) {
      event.onSuccess();    // navigation handled by caller
      emit(AuthState(status: AuthStatus.success));
    } else {
      event.onError();
      emit(AuthState(status: AuthStatus.failure, errorMessage: response.errorText));
    }
  });
  ```
  Events carry `onSuccess` / `onError` callbacks. The page does `context.go(Pages.main)` from the callback. **Don't replicate mechanic-app's `authStreamController` pattern** here.

- **Routing is `go_router` only.** `MaterialApp.router(routerConfig: Routes.router)` in `main.dart`. All paths are constants in `routes/pages.dart`. Auth gating is done at boot via `initialLocation`:
  ```dart
  initialLocation: StorageRepository.getString('token').isNotEmpty ? Pages.main : Pages.signIn,
  ```
  After login/register/logout, navigate via `context.go(Pages.X)` from the bloc-event callback. **Never push a `MaterialPageRoute` / `CupertinoPageRoute` directly via Navigator** — it would skip GoRouter's stack.

- **Storage** is `StorageRepository` (in `core/network/token_service.dart`, despite the file name). Keys are passed as raw strings (`'token'`, etc.) — there's no `StoreKeys` constants file. If you find yourself referencing a key in 3+ places, propose adding constants but don't unilaterally introduce them.

- **Models use `json_serializable` + `freezed`-free style.** Run `dart run build_runner build --delete-conflicting-outputs` after editing any annotated model.

- **Secrets via `flutter_dotenv`.** Never hardcode tokens in source. Add to `.env` and load via `dotenv.env['KEY']`. The Mapbox token already follows this pattern.

- **Typos preserved.** `service_locater` (should be `locator`) and `exeptions` (should be `exceptions`) are intentional and kept stable to avoid noisy renames across the codebase. Don't fix them in passing — only if the user explicitly requests a rename.

- **`bloc/bloc/` double-nesting.** Some features (e.g. `auth`, `home`, `truck_info`) accidentally have a doubled bloc folder. Match what's already there — don't "tidy" it without permission.

## Sister-project porting

When porting features, FCM, auth providers, or anything from `/Users/javoxir/StudioProjects/mechanic-app`:

1. Use the `/port-from-mechanic` slash command (defined in `.claude/commands/`). It encapsulates the full workflow.
2. **Never copy paths or imports verbatim.** Apply the mapping table below.
3. **Adapt the architecture, don't import it.** This repo uses `NetworkResponse`, not `Either`. It uses `go_router`, not `Navigator.pushAndRemoveUntil`. It uses thin domain. Match THIS repo.
4. **Driver-side endpoints differ.** Mechanic-app calls `/mechanics/...`; driver-app calls `/drivers/...`. The flow logic is mirrored but the URL and request bodies differ. Confirm with the user when unsure.

### Path & naming mapping table

| mechanic-app | IzzyDrive |
|---|---|
| `package:mechanic/...` | `package:taxi_app/...` |
| `lib/features/<f>/...` | `lib/features/<f>/...` |
| `data/data_sources/<f>_data_source.dart` | `data/source/<f>_data_source.dart` |
| `data/models/<f>_model.dart` | `data/model/<f>_model.dart` |
| `data/repositories/<f>_repository_impl.dart` | `data/repo/<f>_repo_impl.dart` |
| `domain/repositories/<f>_repository.dart` | `domain/repo/<f>_repo.dart` |
| `domain/entities/<f>_entity.dart` | (none — fold into `data/model/`) |
| `domain/usecases/<f>_usecase.dart` | (none — call repo directly from bloc) |
| `presentation/screens/<f>_screen.dart` | `presentation/pages/<f>_page.dart` (or `_screen.dart` if existing screens use that) |
| `presentation/blocs/<f>/<f>_bloc.dart` | `presentation/bloc/bloc/<f>_bloc.dart` (match feature's existing nesting) |
| `core/exceptions/` | `core/exeptions/` |
| `core/utils/service_locator.dart` | `core/service_locater.dart` |

### Architectural mapping

| mechanic-app pattern | IzzyDrive equivalent |
|---|---|
| `Either<Failure, T>` return + `result.isRight` branching | `NetworkResponse<T>` return + `response.errorText.isEmpty` branching |
| `try/catch ServerException → ServerFailure → Either.left` | `try/catch → return NetworkResponse(errorText: e.message)` |
| `serviceLocator.registerLazySingleton<XRepository>(() => XRepositoryImpl(...))` | Annotate `@LazySingleton(as: XRepository)` and re-run build_runner |
| `BlocProvider(create:(_) => XBloc())` at root MultiBlocProvider | `BlocProvider(create:(_) => getIt<XBloc>())` per route |
| `authStreamController.add(authenticated)` + `AuthenticationBloc` listens | Save token via `StorageRepository.putString('token', ...)` then call `event.onSuccess()` callback (page does `context.go(Pages.main)`) |
| `MyApp.navigatorKey.currentState!.pushAndRemoveUntil(...)` | `context.go(Pages.X)` (or `context.goNamed` if named routes are added later) |
| `MyApp.navigatorKey.currentContext.read<XBloc>()` | `context.read<XBloc>()` from page; or expose bloc via `BlocProvider` ancestor |
| `formz`'s `FormzSubmissionStatus` (`inProgress|success|failure`) | Existing per-feature enums (e.g., `AuthStatus { initial, loading, success, failure }`). `formz` is in pubspec — use it where it's already used; otherwise match the local enum style. |
| Hardcoded Mapbox token in `main.dart` | `dotenv.env['MAPBOX_ACCESS_TOKEN']` |
| `StoreKeys.token` constants | Raw strings (`'token'`, `'refresh'`) — match this repo's style |

### Things to check before each port

- Does the feature exist already in IzzyDrive? Don't blow it away — diff and **only add what's missing**.
- Does the backend endpoint exist for drivers? `/api/v1/drivers/...` may not have feature parity with `/mechanics/...`. Ask if unsure.
- Does the UI copy reference "mexanik" / "usta"? Replace with driver-appropriate terms ("haydovchi" / "mijoz").
- Is there a Pages constant for the route? If not, add one to `routes/pages.dart` AND register the route in `app_router.dart`.

## Notes

- `injectable_generator` IS in use — see the DI section above. The `injectable` runtime package was missing for a long time, which is why nothing was annotated.
- `retrofit_generator` and `flutter_gen_runner` were removed from dev_deps: retrofit was never a runtime dependency and its generator failed to compile, breaking `build_runner` for every builder.
- `formz` is in deps but only sparsely used — match local form-state pattern, don't introduce formz everywhere.
- `flutter_local_notifications` is **not** a dep here. If porting FCM from mechanic-app, the foreground-notification suppression doesn't need that package — just don't show anything on `onMessage` (socket already covers it).
- Two apps share one backend — see `/Users/javoxir/StudioProjects/mechanic-app/CLAUDE.md` for the backend contract details.