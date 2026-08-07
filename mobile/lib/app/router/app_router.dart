import 'package:go_router/go_router.dart';

import '../../core/storage/secure_storage.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/auth/login/login_screen.dart';
import '../../features/auth/register/register_screen.dart';
import '../../features/home/home_screen.dart';
import 'package:mobile/features/auth/otp/otp_screen.dart';

final SecureStorage storage = SecureStorage();

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final token = await storage.getAccessToken();
    final loggedin = token != null && token.isNotEmpty;
    final location = state.matchedLocation;

    if (!loggedin &&
        location != '/login' &&
        location != '/register' &&
        location != '/otp' &&
        location != '/' ){
          return '/login';
        }
      
    if (loggedin &&
        (location == '/login' || location == '/register')){
          return '/home';
        }
    
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) => OtpScreen(
        email: state.extra as String,
  ),
),
],
);