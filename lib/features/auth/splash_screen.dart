import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../services/user_service.dart';
import '../../models/user_role.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription<User?>? _authSubscription;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _listenToAuth();
  }

  void _listenToAuth() {
    try {
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (_isTransitioning) return;
        _handleInitialAuth(user);
      });
    } catch (e) {
      debugPrint('Firebase not initialized: $e');
      if (_isTransitioning) return;
      _isTransitioning = true;
      Future.microtask(() {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      });
    }
  }

  Future<void> _handleInitialAuth(User? firebaseUser) async {
    setState(() {
      _isTransitioning = true;
    });
    await _authSubscription?.cancel();

    if (firebaseUser == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    try {
      final appUser = await UserService.getCurrentUserProfile();
      if (!mounted) return;

      switch (appUser.role) {
        case UserRole.admin:
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.dashboard,
            arguments: appUser,
          );
          break;
        case UserRole.hr:
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.hrDashboard,
            arguments: appUser,
          );
          break;
        case UserRole.employee:
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.employeeDashboard,
            arguments: appUser,
          );
          break;
      }
    } catch (e) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}

      if (!mounted) return;
      final cleanError = e.toString().replaceFirst('Exception: ', '');
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.login,
        arguments: cleanError,
      );
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Cluro HRMS',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}