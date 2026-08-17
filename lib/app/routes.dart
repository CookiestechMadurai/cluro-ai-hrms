import 'package:flutter/material.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../models/app_user.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashScreen(),
        login: (_) => const LoginScreen(),
        dashboard: (context) {
          final user =
              ModalRoute.of(context)!.settings.arguments as AppUser;

          return DashboardScreen(user: user);
        },
      };
}