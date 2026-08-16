import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/secure_storage.dart';

import '../../features/splash/splash_screen.dart';

import '../../features/auth/login/login_screen.dart';
import '../../features/auth/register/register_screen.dart';
import '../../features/auth/otp/otp_screen.dart';

import '../../features/home/home_screen.dart';

import '../../features/profile/profile_screen.dart';

import '../../features/contacts/new_contact/new_contact_screen.dart';

import '../../features/chat/chat_screen.dart';

final SecureStorage storage = SecureStorage();

final GoRouter appRouter = GoRouter(
  initialLocation: '/',

  // ===========================================================================
  // AUTH REDIRECT
  // ===========================================================================

  redirect: (context, state) async {
    final location = state.matchedLocation;

    final token = await storage.getAccessToken();

    final loggedIn = token != null && token.isNotEmpty;

    // -------------------------------------------------------------------------
    // LOGGED IN
    // -------------------------------------------------------------------------

    if (loggedIn) {
      // Prevent logged-in users from going back to authentication screens.
      if (location == '/' ||
          location == '/login' ||
          location == '/register') {
        return '/home';
      }

      return null;
    }

    // -------------------------------------------------------------------------
    // LOGGED OUT
    // -------------------------------------------------------------------------

    if (!loggedIn) {
      // Splash is always allowed.
      if (location == '/') {
        return null;
      }

      // Authentication screens are public.
      if (location == '/login' ||
          location == '/register' ||
          location == '/otp') {
        return null;
      }

      // Everything else requires authentication.
      return '/';
    }

    return null;
  },

  // ===========================================================================
  // ROUTES
  // ===========================================================================

  routes: [
    // -------------------------------------------------------------------------
    // SPLASH
    // -------------------------------------------------------------------------

    GoRoute(
      path: '/',
      builder: (context, state) {
        return const SplashScreen();
      },
    ),

    // -------------------------------------------------------------------------
    // LOGIN
    // -------------------------------------------------------------------------

    GoRoute(
      path: '/login',
      builder: (context, state) {
        return const LoginScreen();
      },
    ),

    // -------------------------------------------------------------------------
    // REGISTER
    // -------------------------------------------------------------------------

    GoRoute(
      path: '/register',
      builder: (context, state) {
        return const RegisterScreen();
      },
    ),

    // -------------------------------------------------------------------------
    // OTP
    // -------------------------------------------------------------------------

    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final extra = state.extra;

        if (extra is! Map<String, dynamic>) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Invalid OTP arguments',
              ),
            ),
          );
        }

        final emailValue = extra['email'];
        final passwordValue = extra['password'];

        final email = emailValue is String ? emailValue : '';
        final password = passwordValue is String ? passwordValue : '';

        if (email.isEmpty || password.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Invalid OTP data',
              ),
            ),
          );
        }

        return OtpScreen(
          email: email,
          password: password,
        );
      },
    ),

    // -------------------------------------------------------------------------
    // HOME
    // -------------------------------------------------------------------------

    GoRoute(
      path: '/home',
      builder: (context, state) {
        return const HomeScreen();
      },
    ),

    // -------------------------------------------------------------------------
    // PROFILE
    // -------------------------------------------------------------------------

    GoRoute(
      path: '/profile',
      builder: (context, state) {
        return const ProfileScreen();
      },
    ),

    // -------------------------------------------------------------------------
    // NEW CONTACT
    // -------------------------------------------------------------------------

    GoRoute(
      path: '/new-contact',
      builder: (context, state) {
        return const NewContactScreen();
      },
    ),

    // -------------------------------------------------------------------------
    // CHAT
    // -------------------------------------------------------------------------

    GoRoute(
      path: '/chat',
      builder: (context, state) {
        final extra = state.extra;

        // HomeScreen/contact list must provide chat information.
        if (extra is! Map<String, dynamic>) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Invalid chat arguments',
              ),
            ),
          );
        }

        // ---------------------------------------------------------------------
        // NAME
        // ---------------------------------------------------------------------

        final nameValue = extra['name'];

        final name = nameValue is String &&
                nameValue.trim().isNotEmpty
            ? nameValue
            : 'Unknown user';

        // ---------------------------------------------------------------------
        // AVATAR
        // ---------------------------------------------------------------------

        final avatarValue = extra['avatar'];

        final avatar = avatarValue is String
            ? avatarValue
            : '';

        // ---------------------------------------------------------------------
        // OPEN CHAT
        // ---------------------------------------------------------------------
        //
        // IMPORTANT:
        // ChatScreen currently accepts ONLY:
        //
        //   name
        //   avatar
        //
        // It does NOT accept conversationId or otherUserId.
        //

        return ChatScreen(
          name: name,
          avatar: avatar,
        );
      },
    ),
  ],
);