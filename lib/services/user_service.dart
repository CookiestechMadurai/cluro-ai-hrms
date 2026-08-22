import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;

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
      status: status,
    );
  }

  static Stream<List<AppUser>> streamUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final roleString = data['role'] as String? ?? '';
        final role = switch (roleString) {
          'admin' => UserRole.admin,
          'hr' => UserRole.hr,
          'employee' => UserRole.employee,
          _ => UserRole.employee,
        };
        final status = data['status'] as String? ?? 'inactive';
        return AppUser(
          uid: doc.id,
          name: data['name'] as String? ?? 'User',
          email: data['email'] as String? ?? '',
          role: role,
          status: status,
        );
      }).toList();
    }).handleError((error) {
      if (error is FirebaseException) {
        debugPrint('DIAGNOSTIC: FIRESTORE ERROR CODE: ${error.code}');
        debugPrint('DIAGNOSTIC: FIRESTORE ERROR MESSAGE: ${error.message}');
      } else {
        debugPrint('DIAGNOSTIC: FIRESTORE ERROR: $error');
      }
      throw error;
    });
  }

  static Future<AppUser> getUserByUid(String uid) async {
    final document = await _firestore.collection('users').doc(uid).get();

    if (!document.exists) {
      throw Exception('User profile not found.');
    }

    final data = document.data();
    if (data == null) {
      throw Exception('Invalid user profile.');
    }

    final roleString = data['role'] as String? ?? '';
    final role = switch (roleString) {
      'admin' => UserRole.admin,
      'hr' => UserRole.hr,
      'employee' => UserRole.employee,
      _ => UserRole.employee,
    };
    final status = data['status'] as String? ?? 'inactive';

    return AppUser(
      uid: uid,
      name: data['name'] as String? ?? 'User',
      email: data['email'] as String? ?? '',
      role: role,
      status: status,
    );
  }

  static Future<void> updateUserProfile({
    required String uid,
    required String name,
    required UserRole role,
    required String status,
  }) async {
    final HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('updateUser');
    final HttpsCallableResult result = await callable.call({
      'uid': uid,
      'name': name.trim(),
      'role': role.name,
      'status': status,
    });

    final data = result.data as Map<dynamic, dynamic>?;
    if (data == null || data['success'] != true) {
      throw Exception('Server returned an invalid success status.');
    }
  }
}