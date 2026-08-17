import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/user_role.dart';

class UserService {
  UserService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static Future<AppUser> getCurrentUserProfile() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      throw Exception('No authenticated user found.');
    }

    final document = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    if (!document.exists) {
      throw Exception('HRMS user profile not found.');
    }

    final data = document.data();

    if (data == null) {
      throw Exception('Invalid HRMS user profile.');
    }

    final status = data['status'] as String? ?? 'inactive';

    if (status != 'active') {
      throw Exception('Your HRMS account is inactive.');
    }

    final roleString = data['role'] as String? ?? '';

    final role = switch (roleString) {
      'admin' => UserRole.admin,
      'hr' => UserRole.hr,
      'employee' => UserRole.employee,
      _ => throw Exception('Invalid user role.'),
    };

    return AppUser(
      uid: firebaseUser.uid,
      name: data['name'] as String? ?? 'User',
      email: data['email'] as String? ?? firebaseUser.email ?? '',
      role: role,
    );
  }
}