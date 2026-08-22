import 'package:flutter/material.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/auth/not_implemented_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/hr/hr_dashboard_screen.dart';
import '../features/employee/employee_dashboard_screen.dart';
import '../models/app_user.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String hrDashboard = '/hr-dashboard';
  static const String employeeDashboard = '/employee-dashboard';
  static const String notImplemented = '/not-implemented';

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashScreen(),
        login: (_) => const LoginScreen(),
        dashboard: (context) {
          final user =
              ModalRoute.of(context)?.settings.arguments as AppUser?;
          if (user == null) {
            return const LoginScreen();
          }
          return DashboardScreen(user: user);
        },
        hrDashboard: (context) {
          final user =
              ModalRoute.of(context)?.settings.arguments as AppUser?;
          if (user == null) {
            return const LoginScreen();
          }
          return HrDashboardScreen(user: user);
        },
        employeeDashboard: (context) {
          final user =
              ModalRoute.of(context)?.settings.arguments as AppUser?;
          if (user == null) {
            return const LoginScreen();
          }
          return EmployeeDashboardScreen(user: user);
        },
        notImplemented: (context) {
          final user =
              ModalRoute.of(context)?.settings.arguments as AppUser?;
          if (user == null) {
            return const LoginScreen();
          }
          return NotImplementedScreen(user: user);
        },
      };
}