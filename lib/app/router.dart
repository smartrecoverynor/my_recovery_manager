import 'package:go_router/go_router.dart';
import '../features/welcome/welcome_page.dart';
import '../features/authentication/login_page.dart';
import '../features/authentication/register_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const WelcomePage(),
    ),
    GoRoute(
      path: '/login',
          builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
        path: '/register',
          builder: (context, state) => const RegisterPage(),
    ),
  ],
);