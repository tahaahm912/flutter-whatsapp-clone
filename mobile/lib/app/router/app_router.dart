import 'package:go_router/go_router.dart';

import '../../core/storage/secure_storage.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/auth/login/login_screen.dart';
import '../../features/auth/register/register_screen.dart';
import '../../features/auth/otp/otp_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/contacts/new_contact/new_contact_screen.dart';

final SecureStorage storage = SecureStorage();

final GoRouter appRouter = GoRouter(
  initialLocation: '/',

  redirect: (context, state) async {
    final location = state.matchedLocation;

    final token = await storage.getAccessToken();
    final loggedIn = token != null && token.isNotEmpty;

    // Logged-in user
    if (loggedIn) {
      if (location == '/' ||
          location == '/login' ||
          location == '/register') {
        return '/home';
      }

      return null;
    }

    // Logged-out user
    if (!loggedIn) {
      // IMPORTANT:
      // Stay on splash when app starts.
      if (location == '/') {
        return null;
      }

      // These are allowed without login.
      if (location == '/login' ||
          location == '/register' ||
          location == '/otp') {
        return null;
      }

      // Protected pages
      return '/';
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
      path: '/otp',
      builder: (context, state) {
        // Week 4, Day 5: the register screen now passes both the
        // email and password (as a Map) so the OTP screen can log
        // the account in right after verification, instead of just
        // the email string it used to receive.
        final args = state.extra as Map<String, dynamic>;

        return OtpScreen(
          email: args['email'] as String,
          password: args['password'] as String,
        );
      },
    ),

    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),

    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),

    GoRoute(
      path: '/new-contact',
      builder: (context, state) => const NewContactScreen(),
    ),
  ],
);