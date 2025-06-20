import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/features/auth/presentation/pages/sign_in_page.dart';
import 'package:taxi_app/src/routes/pages.dart';

class Routes {
  static final GoRouter router = GoRouter(
    initialLocation: Pages.signIn,
    routes: [
      GoRoute(
        path: Pages.signIn,
        builder: (context, state) {
          return SignInPage();
        },
      ),
    ],
  );
}
