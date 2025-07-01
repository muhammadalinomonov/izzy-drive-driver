import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/features/auth/presentation/pages/sign_in_page.dart';
import 'package:taxi_app/src/features/auth/presentation/pages/sign_up_page.dart';
import 'package:taxi_app/src/features/chat/presentation/pages/chat_page.dart';
import 'package:taxi_app/src/features/map/presenation/pages/map_screen.dart';
import 'package:taxi_app/src/routes/pages.dart';

class Routes {
  static final GoRouter router = GoRouter(
    initialLocation: Pages.chat,
    routes: [
      GoRoute(
        path: Pages.signIn,
        builder: (context, state) {
          return SignInPage();
        },
      ),
      GoRoute(
        path: Pages.signUp,
        builder: (context, state) {
          return SignUpPage();
        },
      ),
      GoRoute(
        path: Pages.chat,
        builder: (context, state) {
          return ChatPage();
        },
      ), GoRoute(
        path: Pages.map,
        builder: (context, state) {
          return MapScreen();
        },
      ),
    ],
  );
}
