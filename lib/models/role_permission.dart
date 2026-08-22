import 'user_role.dart';

enum AccessLevel {
  allowed,   // ✓
  denied,    // ✗
  manage,    // ✓ manage
  viewOnly,  // ✓ view
  hrUse,     // HR use
  ownOnly,   // own
}

extension AccessLevelExtension on AccessLevel {
  String get label => switch (this) {
        AccessLevel.allowed => 'Allowed',
        AccessLevel.denied => 'Denied',
        AccessLevel.manage => 'Manage',
        AccessLevel.viewOnly => 'View Only',
        AccessLevel.hrUse => 'HR Use',
        AccessLevel.ownOnly => 'Own Only',
      };

  String get shortSymbol => switch (this) {
        AccessLevel.allowed => '✓',
        AccessLevel.denied => '✗',
        AccessLevel.manage => '✓ manage',
        AccessLevel.viewOnly => '✓ view',
        AccessLevel.hrUse => 'HR use',
        AccessLevel.ownOnly => 'own',
      };
}

class PermissionFeature {
  final String category;
  final String featureName;
  final Map<UserRole, AccessLevel> accessMap;

  const PermissionFeature({
    required this.category,
    required this.featureName,
    required this.accessMap,
  });
}

class RolePermissionMatrix {
  RolePermissionMatrix._();

  static const List<PermissionFeature> initialMatrix = [
    // Category: System & Access
    PermissionFeature(
      category: 'System & Access',
      featureName: 'System Dashboard',
      accessMap: {
        UserRole.admin: AccessLevel.allowed,
        UserRole.hr: AccessLevel.denied,
        UserRole.employee: AccessLevel.denied,
      },
    ),
    PermissionFeature(
      category: 'System & Access',
      featureName: 'User Management',
      accessMap: {
        UserRole.admin: AccessLevel.allowed,
        UserRole.hr: AccessLevel.denied,
        UserRole.employee: AccessLevel.denied,
      },
    ),
    PermissionFeature(
      category: 'System & Access',
      featureName: 'Roles & Permissions',
      accessMap: {
        UserRole.admin: AccessLevel.allowed,
        UserRole.hr: AccessLevel.denied,
        UserRole.employee: AccessLevel.denied,
      },
    ),
    PermissionFeature(
      category: 'System & Access',
      featureName: 'Organization Settings',
      accessMap: {
        UserRole.admin: AccessLevel.allowed,
        UserRole.hr: AccessLevel.denied,
        UserRole.employee: AccessLevel.denied,
      },
    ),
    PermissionFeature(
      category: 'System & Access',
      featureName: 'Departments',
      accessMap: {
        UserRole.admin: AccessLevel.allowed,
        UserRole.hr: AccessLevel.hrUse,
        UserRole.employee: AccessLevel.denied,
      },
    ),
    PermissionFeature(
      category: 'System & Access',
      featureName: 'Designations',
      accessMap: {
        UserRole.admin: AccessLevel.allowed,
        UserRole.hr: AccessLevel.hrUse,
        UserRole.employee: AccessLevel.denied,
      },
    ),

    // Category: Human Resources
    PermissionFeature(
      category: 'Human Resources',
      featureName: 'Employees',
      accessMap: {
        UserRole.admin: AccessLevel.viewOnly,
        UserRole.hr: AccessLevel.manage,
        UserRole.employee: AccessLevel.denied,
      },
    ),
    PermissionFeature(
      category: 'Human Resources',
      featureName: 'Attendance',
      accessMap: {
        UserRole.admin: AccessLevel.viewOnly,
        UserRole.hr: AccessLevel.manage,
        UserRole.employee: AccessLevel.ownOnly,
      },
    ),
    PermissionFeature(
      category: 'Human Resources',
      featureName: 'Leave',
      accessMap: {
        UserRole.admin: AccessLevel.viewOnly,
        UserRole.hr: AccessLevel.manage,
        UserRole.employee: AccessLevel.ownOnly,
      },
    ),
    PermissionFeature(
      category: 'Human Resources',
      featureName: 'Payroll',
      accessMap: {
        UserRole.admin: AccessLevel.viewOnly,
        UserRole.hr: AccessLevel.manage,
        UserRole.employee: AccessLevel.ownOnly,
      },
    ),
    PermissionFeature(
      category: 'Human Resources',
      featureName: 'Recruitment',
      accessMap: {
        UserRole.admin: AccessLevel.denied,
        UserRole.hr: AccessLevel.manage,
        UserRole.employee: AccessLevel.denied,
      },
    ),
    PermissionFeature(
      category: 'Human Resources',
      featureName: 'Performance',
      accessMap: {
        UserRole.admin: AccessLevel.denied,
        UserRole.hr: AccessLevel.manage,
        UserRole.employee: AccessLevel.ownOnly,
      },
    ),
    PermissionFeature(
      category: 'Human Resources',
      featureName: 'Training',
      accessMap: {
        UserRole.admin: AccessLevel.denied,
        UserRole.hr: AccessLevel.manage,
        UserRole.employee: AccessLevel.ownOnly,
      },
    ),

    // Category: Personal Workspace
    PermissionFeature(
      category: 'Personal Workspace',
      featureName: 'My Profile',
      accessMap: {
        UserRole.admin: AccessLevel.allowed,
        UserRole.hr: AccessLevel.allowed,
        UserRole.employee: AccessLevel.allowed,
      },
    ),
    PermissionFeature(
      category: 'Personal Workspace',
      featureName: 'Logout',
      accessMap: {
        UserRole.admin: AccessLevel.allowed,
        UserRole.hr: AccessLevel.allowed,
        UserRole.employee: AccessLevel.allowed,
      },
    ),
  ];
}
