import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuditLogService {
  AuditLogService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Records a security or system operation event in the central Firestore audit_logs collection.
  static Future<void> logEvent({
    required String action,
    required String targetType,
    required String targetId,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await _firestore.collection('audit_logs').add({
      'actorUid': currentUser.uid,
      'actorEmail': currentUser.email ?? '',
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      'metadata': metadata ?? {},
    });
  }

  /// Returns a real-time stream of audit logs ordered chronologically by creation timestamp.
  static Stream<List<AuditLogEntry>> streamAuditLogs() {
    return _firestore
        .collection('audit_logs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AuditLogEntry(
          id: doc.id,
          actorUid: data['actorUid'] as String? ?? '',
          actorEmail: data['actorEmail'] as String? ?? '',
          action: data['action'] as String? ?? '',
          targetType: data['targetType'] as String? ?? '',
          targetId: data['targetId'] as String? ?? '',
          description: data['description'] as String? ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          metadata: data['metadata'] as Map<String, dynamic>? ?? {},
        );
      }).toList();
    });
  }
}

class AuditLogEntry {
  final String id;
  final String actorUid;
  final String actorEmail;
  final String action;
  final String targetType;
  final String targetId;
  final String description;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const AuditLogEntry({
    required this.id,
    required this.actorUid,
    required this.actorEmail,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.description,
    required this.createdAt,
    required this.metadata,
  });
}
