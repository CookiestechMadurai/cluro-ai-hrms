import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../../models/app_user.dart';
import '../../models/user_role.dart';
import '../../services/user_service.dart';
import 'user_detail_dialog.dart';
import 'create_user_dialog.dart';

class UserManagementScreen extends StatefulWidget {
  final AppUser adminUser;

  const UserManagementScreen({
    super.key,
    required this.adminUser,
  });

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRoleFilter = 'All';
  String _selectedStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showEditDialog(AppUser user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return UserDetailDialog(
          targetUser: user,
          currentAdmin: widget.adminUser,
          onUpdated: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'User profile updated successfully.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white),
                ),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateUserDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CreateUserDialog(adminUser: widget.adminUser);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width >= 800;

    // DIAGNOSTIC LOGS
    try {
      final app = Firebase.app();
      debugPrint('DIAGNOSTIC: Firebase Project ID (App): ${app.options.projectId}');
    } catch (e) {
      debugPrint('DIAGNOSTIC: Error getting Firebase app: $e');
    }
    final currentUser = FirebaseAuth.instance.currentUser;
    debugPrint('DIAGNOSTIC: Auth User UID: ${currentUser?.uid}');
    debugPrint('DIAGNOSTIC: Auth User Email: ${currentUser?.email}');
    debugPrint('DIAGNOSTIC: Firestore collection path: users');
    if (kIsWeb) {
      debugPrint('DIAGNOSTIC: Running on Web platform');
    } else {
      debugPrint('DIAGNOSTIC: Running on non-Web platform');
    }

    return StreamBuilder<List<AppUser>>(
      stream: UserService.streamUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 40),
                  const SizedBox(height: 16),
                  const Text(
                    'Error Loading Users',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                    style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF64748B), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final users = snapshot.data ?? [];

        // Compute aggregate metrics
        final totalUsers = users.length;
        final activeUsers = users.where((u) => u.status == 'active').length;
        final inactiveUsers = users.where((u) => u.status == 'inactive').length;
        final hrCount = users.where((u) => u.role == UserRole.hr).length;
        final employeeCount = users.where((u) => u.role == UserRole.employee).length;

        // Apply filters
        final filteredUsers = users.where((user) {
          final matchesSearch = user.name.toLowerCase().contains(_searchQuery) ||
              user.email.toLowerCase().contains(_searchQuery);

          final matchesRole = _selectedRoleFilter == 'All' ||
              user.role.name == _selectedRoleFilter.toLowerCase();

          final matchesStatus = _selectedStatusFilter == 'All' ||
              user.status == _selectedStatusFilter.toLowerCase();

          return matchesSearch && matchesRole && matchesStatus;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildMetricsSummary(
                total: totalUsers,
                active: activeUsers,
                inactive: inactiveUsers,
                hr: hrCount,
                employees: employeeCount,
              ),
              const SizedBox(height: 24),
              _buildFilterSection(isWideScreen),
              const SizedBox(height: 20),
              if (filteredUsers.isEmpty)
                _buildEmptyState()
              else if (isWideScreen)
                _buildDesktopTable(filteredUsers)
              else
                _buildMobileCardList(filteredUsers),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Users',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage system accounts and access.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        FilledButton.icon(
          onPressed: () => _showCreateUserDialog(context),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Create User'),
        ),
      ],
    );
  }

  Widget _buildMetricsSummary({
    required int total,
    required int active,
    required int inactive,
    required int hr,
    required int employees,
  }) {
    final double width = MediaQuery.of(context).size.width;
    final int crossAxisCount = width < 600 ? 2 : (width < 1100 ? 3 : 5);
    final double childAspectRatio = width < 600 ? 2.5 : 2.0;

    final metrics = [
      _MetricData('Total', total.toString(), const Color(0xFF2563EB), Icons.people_outline),
      _MetricData('Active', active.toString(), const Color(0xFF10B981), Icons.check_circle_outline),
      _MetricData('Inactive', inactive.toString(), const Color(0xFFEF4444), Icons.block_outlined),
      _MetricData('HR', hr.toString(), const Color(0xFF8B5CF6), Icons.shield_outlined),
      _MetricData('Employees', employees.toString(), const Color(0xFFF59E0B), Icons.badge_outlined),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final item = metrics[index];
        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.color.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(item.icon, color: item.color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.value,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterSection(bool isWideScreen) {
    final searchField = TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        labelText: 'Search by name or email',
        prefixIcon: Icon(Icons.search),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );

    final roleFilter = DropdownButtonFormField<String>(
      initialValue: _selectedRoleFilter,
      decoration: const InputDecoration(
        labelText: 'Role',
        prefixIcon: Icon(Icons.shield_outlined),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: const [
        DropdownMenuItem(value: 'All', child: Text('All Roles')),
        DropdownMenuItem(value: 'Admin', child: Text('Admin')),
        DropdownMenuItem(value: 'HR', child: Text('HR')),
        DropdownMenuItem(value: 'Employee', child: Text('Employee')),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedRoleFilter = val;
          });
        }
      },
    );

    final statusFilter = DropdownButtonFormField<String>(
      initialValue: _selectedStatusFilter,
      decoration: const InputDecoration(
        labelText: 'Status',
        prefixIcon: Icon(Icons.toggle_on_outlined),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: const [
        DropdownMenuItem(value: 'All', child: Text('All Statuses')),
        DropdownMenuItem(value: 'Active', child: Text('Active')),
        DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedStatusFilter = val;
          });
        }
      },
    );

    if (isWideScreen) {
      return Row(
        children: [
          Expanded(flex: 2, child: searchField),
          const SizedBox(width: 12),
          Expanded(child: roleFilter),
          const SizedBox(width: 12),
          Expanded(child: statusFilter),
        ],
      );
    }

    return Column(
      children: [
        searchField,
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: roleFilter),
            const SizedBox(width: 12),
            Expanded(child: statusFilter),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopTable(List<AppUser> filteredUsers) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          headingRowHeight: 46,
          dataRowMinHeight: 52,
          dataRowMaxHeight: 52,
          horizontalMargin: 20,
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('Name', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
            DataColumn(label: Text('Email', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
            DataColumn(label: Text('Role', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
            DataColumn(label: Text('Status', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
            DataColumn(label: Text('Actions', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
          ],
          rows: filteredUsers.map((user) {
            final isSelf = user.uid == widget.adminUser.uid;
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (isSelf) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                DataCell(Text(user.email, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B)))),
                DataCell(_buildRoleBadge(user.role)),
                DataCell(_buildStatusBadge(user.status)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => _showEditDialog(user),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        child: Text(isSelf ? 'View' : 'Edit'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileCardList(List<AppUser> filteredUsers) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        final isSelf = user.uid == widget.adminUser.uid;

        return Card(
          elevation: 0,
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelf) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: const Text(
                                'You',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 8,
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showEditDialog(user),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildRoleBadge(user.role),
                    const SizedBox(width: 8),
                    _buildStatusBadge(user.status),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    Color color;
    Color bgColor;

    switch (role) {
      case UserRole.admin:
        color = const Color(0xFF1E3A8A);
        bgColor = const Color(0xFFDBEAFE);
        break;
      case UserRole.hr:
        color = const Color(0xFF5B21B6);
        bgColor = const Color(0xFFEDE9FE);
        break;
      case UserRole.employee:
        color = const Color(0xFF9A3412);
        bgColor = const Color(0xFFFFEDD5);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.name.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Inter',
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final bool isActive = status == 'active';
    final Color color = isActive ? const Color(0xFF065F46) : const Color(0xFF991B1B);
    final Color bgColor = isActive ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Inter',
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const Icon(Icons.people_outline, size: 40, color: Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            const Text(
              'No matching users found',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try refining your search text or removing the filters.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _selectedRoleFilter = 'All';
                  _selectedStatusFilter = 'All';
                });
              },
              child: const Text('Reset Filters'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricData {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  _MetricData(this.label, this.value, this.color, this.icon);
}
