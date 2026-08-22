import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/app_user.dart';
import '../../app/routes.dart';
import '../employees/user_management_screen.dart';
import '../roles/roles_permissions_screen.dart';
import '../admin/audit_logs_screen.dart';
import '../admin/system_settings_screen.dart';
import '../../services/audit_log_service.dart';
import '../../services/user_service.dart';

class DashboardScreen extends StatefulWidget {
  final AppUser user;

  const DashboardScreen({
    super.key,
    required this.user,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedPageIndex = 0;

  void _onNavigate(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width >= 800;

    Widget bodyContent;
    switch (_selectedPageIndex) {
      case 0:
        bodyContent = _buildDashboardContent(context);
        break;
      case 1:
        bodyContent = UserManagementScreen(adminUser: widget.user);
        break;
      case 2:
        bodyContent = const RolesPermissionsScreen();
        break;
      case 3:
        bodyContent = const AuditLogsScreen();
        break;
      case 4:
        bodyContent = const SystemSettingsScreen();
        break;
      case 5:
        bodyContent = _buildProfileWorkspace();
        break;
      default:
        bodyContent = _buildDashboardContent(context);
    }

    final topAppBar = AppBar(
      title: Text(_getPageTitle()),
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: const Color(0xFFF8FAFC),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFEFF6FF),
            child: Text(
              widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'A',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
        ),
      ],
    );

    if (isWideScreen) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Row(
          children: [
            _buildSidebar(context),
            const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: Scaffold(
                backgroundColor: const Color(0xFFF8FAFC),
                appBar: topAppBar,
                body: bodyContent,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: topAppBar,
      drawer: Drawer(
        child: _buildDrawerContent(context),
      ),
      body: bodyContent,
    );
  }

  String _getPageTitle() {
    switch (_selectedPageIndex) {
      case 0:
        return 'System Administration';
      case 1:
        return 'Users';
      case 2:
        return 'Roles & Permissions';
      case 3:
        return 'Audit Logs';
      case 4:
        return 'System Settings';
      case 5:
        return 'Profile';
      default:
        return 'System Administration';
    }
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 250,
      color: const Color(0xFF0F172A),
      child: _buildDrawerContent(context),
    );
  }

  Widget _buildDrawerContent(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      color: const Color(0xFF0F172A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDrawerHeader(),
          const Divider(height: 1, thickness: 1, color: Color(0xFF1E293B)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              children: [
                _buildCategoryHeader('Main'),
                _buildNavItem(0, 'Dashboard', Icons.dashboard_outlined, isMobile),
                const SizedBox(height: 16),
                _buildCategoryHeader('Access'),
                _buildNavItem(1, 'Users', Icons.manage_accounts_outlined, isMobile),
                _buildNavItem(2, 'Roles & Permissions', Icons.security_outlined, isMobile),
                const SizedBox(height: 16),
                _buildCategoryHeader('System'),
                _buildNavItem(3, 'Audit Logs', Icons.receipt_long_outlined, isMobile),
                _buildNavItem(4, 'System Settings', Icons.settings_outlined, isMobile),
                const SizedBox(height: 16),
                _buildCategoryHeader('Account'),
                _buildNavItem(5, 'Profile', Icons.account_circle_outlined, isMobile),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFF1E293B)),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ListTile(
              leading: const Icon(Icons.logout_outlined, color: Color(0xFFFCA5A5), size: 20),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Color(0xFFFCA5A5),
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: _logout,
              hoverColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.only(top: 48, bottom: 24, left: 20, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Cluro HRMS',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            widget.user.name,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.user.email,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Text(
              'SYSTEM ADMIN',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF38BDF8),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 4, bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Inter',
          color: Color(0xFF475569),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon, bool isMobile) {
    final bool isSelected = _selectedPageIndex == index;
    final Color itemColor = isSelected ? Colors.white : const Color(0xFF94A3B8);
    final Color bgColor = isSelected ? const Color(0xFF2563EB) : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: bgColor,
        leading: Icon(icon, color: itemColor, size: 20),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            color: itemColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        hoverColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        onTap: () {
          if (isMobile) {
            Navigator.pop(context); // Close mobile drawer
          }
          _onNavigate(index);
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        dense: true,
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width >= 800;

    return StreamBuilder<List<AppUser>>(
      stream: UserService.streamUsers(),
      builder: (context, snapshot) {
        final bool isFirestoreOperational = snapshot.hasData && !snapshot.hasError;
        final String firestoreStatus = snapshot.hasError 
            ? 'Error / Offline' 
            : (snapshot.connectionState == ConnectionState.waiting ? 'Initializing...' : 'Operational');

        final users = snapshot.data ?? [];
        final int totalUsers = users.length;
        final int activeUsers = users.where((u) => u.status == 'active').length;
        final int inactiveUsers = users.where((u) => u.status == 'inactive').length;
        const int systemRoles = 3;

        return Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(),
                const SizedBox(height: 24),
                _buildSummaryGrid(
                  context: context,
                  totalUsers: totalUsers,
                  activeUsers: activeUsers,
                  inactiveUsers: inactiveUsers,
                  systemRoles: systemRoles,
                  isLoading: snapshot.connectionState == ConnectionState.waiting,
                ),
                const SizedBox(height: 28),
                _buildQuickActions(context),
                const SizedBox(height: 28),
                if (isWideScreen)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildRecentActivity(),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildSystemHealth(isFirestoreOperational, firestoreStatus),
                            const SizedBox(height: 24),
                            _buildProfileSummaryCard(),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildRecentActivity(),
                      const SizedBox(height: 24),
                      _buildSystemHealth(isFirestoreOperational, firestoreStatus),
                      const SizedBox(height: 24),
                      _buildProfileSummaryCard(),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 4),
        Text(
          'System overview and access management',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryGrid({
    required BuildContext context,
    required int totalUsers,
    required int activeUsers,
    required int inactiveUsers,
    required int systemRoles,
    required bool isLoading,
  }) {
    final double width = MediaQuery.of(context).size.width;
    final int crossAxisCount = width < 600 ? 1 : (width < 1100 ? 2 : 4);

    final double childAspectRatio;
    if (crossAxisCount == 1) {
      childAspectRatio = 4.2;
    } else if (crossAxisCount == 2) {
      childAspectRatio = 2.4;
    } else {
      childAspectRatio = 1.9;
    }

    final summaryItems = [
      _SummaryCardData(
        title: 'Total Users',
        value: isLoading ? '...' : totalUsers.toString(),
        icon: Icons.people_outline,
        color: const Color(0xFF2563EB),
      ),
      _SummaryCardData(
        title: 'Active Users',
        value: isLoading ? '...' : activeUsers.toString(),
        icon: Icons.verified_user_outlined,
        color: const Color(0xFF10B981),
      ),
      _SummaryCardData(
        title: 'Inactive Users',
        value: isLoading ? '...' : inactiveUsers.toString(),
        icon: Icons.toggle_off_outlined,
        color: const Color(0xFFEF4444),
      ),
      _SummaryCardData(
        title: 'System Roles',
        value: systemRoles.toString(),
        icon: Icons.admin_panel_settings_outlined,
        color: const Color(0xFF8B5CF6),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: summaryItems.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        return _buildSummaryCard(summaryItems[index]);
      },
    );
  }

  Widget _buildSummaryCard(_SummaryCardData data) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: data.color.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(data.icon, color: data.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.value,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
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
  }

  Widget _buildQuickActions(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final int crossAxisCount = width < 600 ? 2 : 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: width < 600 ? 2.6 : 3.4,
          children: [
            _buildActionCard('Manage Users', Icons.manage_accounts_outlined, 1),
            _buildActionCard('Roles & Permissions', Icons.security_outlined, 2),
            _buildActionCard('System Settings', Icons.settings_outlined, 4),
            _buildActionCard('Audit Logs', Icons.receipt_long_outlined, 3),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String label, IconData icon, int targetIndex) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: () => _onNavigate(targetIndex),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF2563EB)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt_long_outlined, color: Color(0xFF0F172A), size: 18),
                SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<AuditLogEntry>>(
              stream: AuditLogService.streamAuditLogs(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Unable to load activity',
                            style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Please try again.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {});
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }

                final logs = snapshot.data ?? [];
                if (logs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: Text(
                        'No recent administrative activity',
                        style: TextStyle(fontFamily: 'Inter', color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ),
                  );
                }

                final displayLogs = logs.take(4).toList();

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayLogs.length,
                  separatorBuilder: (context, index) => const Divider(height: 20, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final log = displayLogs[index];
                    final timeStr = log.createdAt.toLocal().toString().substring(11, 16);
                    
                    final IconData logIcon = switch (log.action) {
                      'USER_CREATED' => Icons.person_add_outlined,
                      'ROLE_CHANGED' => Icons.manage_accounts_outlined,
                      'STATUS_CHANGED' => Icons.toggle_off_outlined,
                      'USER_UPDATED' => Icons.edit_outlined,
                      _ => Icons.info_outlined,
                    };

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(logIcon, size: 14, color: const Color(0xFF475569)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    log.action,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    timeStr,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 10,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                log.description,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'actor: ${log.actorEmail}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemHealth(bool isFirestoreOperational, String firestoreStatus) {
    final bool isAuthConnected = FirebaseAuth.instance.currentUser != null;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.dns_outlined, color: Color(0xFF0F172A), size: 18),
                SizedBox(width: 8),
                Text(
                  'Infrastructure Health',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildHealthIndicator(
              'Firebase Authentication',
              isAuthConnected ? 'Connected' : 'Disconnected',
              isAuthConnected,
            ),
            const SizedBox(height: 12),
            _buildHealthIndicator(
              'Firestore Database',
              firestoreStatus,
              isFirestoreOperational,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthIndicator(String service, String status, bool isHealthy) {
    return Row(
      children: [
        Icon(
          isHealthy ? Icons.check_circle_outline : Icons.error_outline,
          color: isHealthy ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          size: 16,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            service,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        Text(
          status,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isHealthy ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSummaryCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.badge_outlined, color: Color(0xFF0F172A), size: 18),
                SizedBox(width: 8),
                Text(
                  'My Profile',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProfileRow('Administrator', widget.user.name),
            _buildProfileRow('Email ID', widget.user.email),
            _buildProfileRow('System Role', widget.user.role.name.toUpperCase()),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value, {bool isCode = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: isCode ? 'monospace' : 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isCode ? const Color(0xFF64748B) : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileWorkspace() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Profile Banner Header Card
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                // Top accent strip
                Container(
                  height: 96,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -32),
                  child: Column(
                    children: [
                      // Large floating circular avatar with initials
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: const Color(0xFF2563EB),
                          child: Text(
                            widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'A',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.user.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.user.email,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Text(
                              widget.user.role.name.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF2563EB),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF065F46),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 2. Structured Information Details Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 640;
              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildProfileDetailsCard()),
                        const SizedBox(width: 20),
                        Expanded(child: _buildSecurityPrivilegesCard()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildProfileDetailsCard(),
                        const SizedBox(height: 20),
                        _buildSecurityPrivilegesCard(),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailsCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.badge_outlined, color: Color(0xFF0F172A), size: 18),
                SizedBox(width: 8),
                Text(
                  'Account Details',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFE2E8F0)),
            _buildInfoRow('Full Name', widget.user.name),
            _buildInfoRow('Registered Email', widget.user.email),
            _buildCopyableRow('Account UID', widget.user.uid),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityPrivilegesCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lock_person_outlined, color: Color(0xFF0F172A), size: 18),
                SizedBox(width: 8),
                Text(
                  'Access & Permissions',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFE2E8F0)),
            _buildInfoRow('Account Status', 'Active & Operational'),
            _buildInfoRow('System Privileges', 'Root / Administrative Access (Level 3)'),
            _buildInfoRow('System Settings Policy', 'Read-Write Access Permitted'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_outlined, size: 16, color: Color(0xFF2563EB)),
                tooltip: 'Copy to Clipboard',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account UID copied to clipboard.', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white)),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}