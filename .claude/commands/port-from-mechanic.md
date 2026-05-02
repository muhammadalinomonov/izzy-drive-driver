---
description: Port a feature, file, or commit from the mechanic-app sister repo into IzzyDrive, applying the architecture mapping from CLAUDE.md.
argument-hint: <feature-name | path | commit-hash | "google-auth" | "fcm-router" | etc.>
---

# /port-from-mechanic

Port work from `/Users/javoxir/StudioProjects/mechanic-app` into this repo (IzzyDrive / `taxi_app`), following the cross-project conventions documented in `CLAUDE.md`.

## Argument

`$ARGUMENTS` — what to port. Free-form. Examples:
- `google-auth` / `apple-sign-in` / `forgot-password` / `delete-account` / `fcm-router` / `notification-router`
- `lib/features/auth/data/data_sources/auth_data_source.dart` (a single file)
- `commit:c16aaf3` (a commit hash from mechanic-app)
- `recent` (the last 3-4 commits — list them and ask which)
- empty → ask the user what to port

## Workflow

### 1. Anchor

Read these first, in order:
1. **This repo's CLAUDE.md** at `/Users/javoxir/StudioProjects/IzzyDrive/CLAUDE.md` — the section [Sister-project porting](../../CLAUDE.md#sister-project-porting) has the mapping table that governs everything below.
2. **mechanic-app's CLAUDE.md** at `/Users/javoxir/StudioProjects/mechanic-app/CLAUDE.md` — for backend contract and the *source* convention.

You must internalize both before reading code. The whole point of this command is that **you adapt mechanic-app's code to IzzyDrive's conventions, not import them**.

### 2. Locate the source

Resolve `$ARGUMENTS` to concrete files in mechanic-app:

- **Feature name** → look under `mechanic-app/lib/features/<closest-match>/`. If ambiguous (e.g. "auth" maps to multiple sub-flows), list candidates and ask.
- **Commit hash** → `cd /Users/javoxir/StudioProjects/mechanic-app && git show --stat <hash>` to enumerate files. Then `git show <hash> -- <file>` per file for the diff.
- **`recent`** → `cd /Users/javoxir/StudioProjects/mechanic-app && git log --oneline -10` and ask the user which commits to port.
- **Path** → read directly.

For each source file you intend to port, also locate the **corresponding file in IzzyDrive** (if any) so you can diff. Use the mapping table from CLAUDE.md (`features/auth/data/data_sources/auth_data_source.dart` → `src/features/auth/data/source/auth_data_source.dart` etc).

Report back:
- "Source files" list (mechanic-app paths)
- "Target files" list (IzzyDrive paths — existing or new)
- "Risk notes" (any obvious divergence, e.g. "IzzyDrive's AuthRepo only has logIn/register; porting Google Sign-in needs a new method")

### 3. Diagnose divergence — ask before coding

Before writing anything, surface:

- **Endpoint differences** — if the mechanic-app data source calls `/mechanics/...`, the driver-app's endpoint is `/drivers/...`. Confirm with the user. Some endpoints don't exist on the driver side at all.
- **UI copy** — Uzbek text often says "mexanik" / "ustа" — change to "haydovchi" / appropriate driver-side wording. List the strings you plan to change.
- **Existing IzzyDrive code that overlaps** — if `auth_repo_impl.dart` already has `logIn`/`register`, you're *adding* methods, not rewriting the class. Surface what exists.
- **Missing dependencies** — if the source uses a package not in IzzyDrive's `pubspec.yaml`, list it and ask whether to add it. Don't silently `flutter pub add`.
- **`Pages.X` route entry** — does the route already exist in `src/routes/pages.dart` and `app_router.dart`? If not, plan the addition.

Ask the user about every divergence. Do not assume — **the user explicitly said "farq qiladigan joylarini to'g'irlab ketamiz, unga alohida to'xtalamiz"**.

### 4. Apply the mapping

When writing the IzzyDrive version, apply these transforms mechanically:

**Imports**
```
package:mechanic/<x>            →  package:taxi_app/src/<x>
package:mechanic/features/      →  package:taxi_app/src/features/
package:mechanic/core/          →  package:taxi_app/src/core/
```

**Folder/file renames** — see the mapping table in CLAUDE.md.

**Result type — Either<Failure, T> → NetworkResponse<T>**
```dart
// mechanic-app
Future<Either<Failure, BaseModel<UserModel>>> login(...) async {
  try {
    final res = await dataSource.login(...);
    return Right(res);
  } on ServerException catch (e) {
    return Left(ServerFailure(errorMessage: e.errorMessage));
  }
}

// IzzyDrive
Future<NetworkResponse<UserModel>> logIn(...) async {
  try {
    final res = await dataSource.logIn(...);
    return NetworkResponse(data: res);
  } catch (e) {
    return NetworkResponse(errorText: e.toString());
  }
}
```

**Bloc result branching**
```dart
// mechanic-app
if (result.isRight) { ... } else { errorMsg = result.left.errorMessage; }

// IzzyDrive
if (response.errorText.isEmpty) { ... } else { errorMsg = response.errorText; }
```

**Domain layer**
- Drop `domain/entities/` — fold any extra fields the entity carried back into the model in `data/model/`.
- Drop `domain/usecases/` entirely — the bloc calls the repo directly.
- Keep only `domain/repo/<feature>_repo.dart` (abstract).

**DI**
- Don't add anything to `serviceLocator`. Construct repo+data-source by hand inside the GoRoute builder where the bloc is provided.

**Auth status / navigation**
- mechanic-app's `authStreamController` + `AuthenticationBloc` + `pushAndRemoveUntil` does NOT translate. Replace with:
  - On success in the data source: `StorageRepository.putString('token', accessToken)` (and `'refresh'` if applicable).
  - In the page, after `BlocListener` sees `AuthStatus.success`: `context.go(Pages.main)`.
  - On logout: `StorageRepository.deleteString('token')` (or whatever this codebase uses) → `context.go(Pages.signIn)`.
- For password reset, social sign-in, delete-account: also use callback-based `onSuccess`/`onError` events, matching the existing `LoginEvent` / `RegisterEvent` pattern.

**Navigation calls**
```
MyApp.navigatorKey.currentState!.pushAndRemoveUntil(...)  →  context.go(Pages.X)
Navigator.of(context).push(MaterialPageRoute(...))         →  context.push(Pages.X)
Navigator.of(context).pop()                                →  context.pop()
```
For any new screen, add a constant to `src/routes/pages.dart` AND register the route in `app_router.dart`.

**Secrets**
- Anything hardcoded in mechanic-app's `main.dart` (e.g. Mapbox token) → put in `.env`, load via `dotenv.env['KEY']`. If `.env` already has the key, reuse it.

**Native config (iOS/Android)**
- Apple/Google sign-in often involves `ios/Runner/Info.plist`, `ios/Runner.xcodeproj/project.pbxproj`, `android/app/build.gradle.kts`, Firebase plist files, and bundle-ID-specific OAuth client IDs.
- The driver-app and mechanic-app have **different bundle IDs** — Apple/Google client IDs from mechanic-app will NOT work in IzzyDrive.
- For each native change, surface the file and the specific line, but **ask the user to provide the driver-side OAuth/Firebase credentials** before pasting placeholders. Never copy mechanic-app's client IDs verbatim.

**FCM / NotificationRouter (recent work)**
- mechanic-app's `lib/core/utils/notification_router.dart` references `MyApp.navigatorKey`. In IzzyDrive, replace with `Routes.router` (`GoRouter`) — push targeting via `Routes.router.go(Pages.X)` (a GoRouter instance has `.go()` directly, no context needed).
- Replace `OrdersBloc` lookup pattern. Either:
  - Use `Routes.router.routerDelegate.navigatorKey.currentContext` to read the current bloc, OR
  - Keep an internal `StreamController` inside the router-side helper that the order bloc subscribes to. The user can choose.
- The "stash pending payload until consume" pattern still applies — port the `_pendingPushPayload` + `consumePending` pair faithfully.

### 5. Implement, in small commits

- One feature at a time. Don't bundle Apple-Sign-in + Forgot-Password into one PR.
- After each feature, run `flutter analyze` from the IzzyDrive root and report errors.
- Don't run `flutter pub get` automatically if you added a dep — surface the dep change and let the user run it.
- Don't run `dart run build_runner build` automatically — same reason.

### 6. Verify

- `flutter analyze` from IzzyDrive root — only failures relevant to your changes count; pre-existing warnings are not your problem.
- For UI work, the user will test manually (driver-app + mechanic-app coordination is needed for some flows, e.g. selecting a proposal — mention this when handing off).
- For auth flows: list the manual test steps the user should run.

### 7. Hand off

Final reply must include:
- **Files changed** (paths)
- **Files NOT yet ported** (if you split scope)
- **Native config still needed** (e.g. "Add `GIDClientID` to `Info.plist` for the driver-app's OAuth client")
- **Backend assumptions** ("Assumed driver-side endpoint is `POST /api/v1/drivers/google-auth/` — confirm with backend")
- **Suggested manual test steps**

## Things never to do

- Never edit files in `/Users/javoxir/StudioProjects/mechanic-app` from inside this command. We're porting *from* it; that repo is read-only here.
- Never replace IzzyDrive's `NetworkResponse` with `Either`. Never reintroduce a `usecases/` folder. Never register data sources in GetIt. Never add `MyApp.navigatorKey` — this app uses GoRouter.
- Never silently rename the `service_locater.dart` / `exeptions/` typos. They're load-bearing for git history.
- Never copy OAuth/Firebase client IDs from mechanic-app — bundle IDs differ.
- Never run a destructive git op against IzzyDrive without explicit user request.