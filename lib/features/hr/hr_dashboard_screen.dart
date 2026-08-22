import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../app/routes.dart';

class HrDashboardScreen extends StatefulWidget {
  final AppUser user;

  const HrDashboardScreen({
    super.key,
    required this.user,
  });

  @override
  State<HrDashboardScreen> createState() => _HrDashboardScreenState();
}

class _HrDashboardScreenState extends State<HrDashboardScreen> {
  int _selectedPageIndex = 0;

  // Mock HR workspace stats
  final Map<String, dynamic> _mockStats = {
    'totalEmployees': 48,
    'presentToday': 42,
    'pendingLeaves': 5,
    'payrollStatus': 'Processed',
  };

  // Mock HR activity log entries
  final List<Map<String, String>> _mockHrLogs = [
    {
      'action': 'Leave Request Approved',
      'details': 'Approved 3 days of medical leave for John Smith (EMP-024)',
      'time': '15 minutes ago',
      'actor': 'hr_manager',
    },
    {
      'action': 'New Employee Registered',
      'details': 'Added profile details for Sarah Jenkins (HR Specialist)',
      'time': '2 hours ago',
      'actor': 'hr_manager',
    },
    {
      'action': 'Attendance Record Adjusted',
      'details': 'Manually corrected clock-in mismatch for Robert Chen (EMP-012)',
      'time': '5 hours ago',
      'actor': 'hr_coordinator',
    },
    {
      'action': 'Payroll Slip Finalized',
      'details': 'Monthly payslips calculated and finalized for August 2026',
      'time': '1 day ago',
      'actor': 'payroll_admin',
    },
  ];

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
        bodyContent = _buildPlaceholderContent('Employee Directory', Icons.people_outline);
        break;
      case 2:
        bodyContent = _buildPlaceholderContent('Attendance Logs', Icons.access_time);
        break;
      case 3:
        bodyContent = _buildPlaceholderContent('Leave Management', Icons.event_available_outlined);
        break;
      case 4:
        bodyContent = _buildPlaceholderContent('Payroll Processing', Icons.payments_outlined);
        break;
      case 5:
        bodyContent = _buildProfileWorkspace();
        break;
      default:
        bodyContent = _buildDashboardContent(context);
    }

    if (isWideScreen) {
      return Scaffold(
        body: Row(
          children: [
            _buildSidebar(context),
            const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE5E7EB)),
            Expanded(
              child: Scaffold(
                backgroundColor: const Color(0xFFF7F8FA),
                appBar: AppBar(
                  title: Text(_getPageTitle()),
                  elevation: 0,
                ),
                body: bodyContent,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(_getPageTitle()),
        elevation: 0,
      ),
      drawer: Drawer(
        child: _buildDrawerContent(context),
      ),
      body: bodyContent,
    );
  }

  String _getPageTitle() {
    switch (_selectedPageIndex) {
      case 0:
        return 'HR Workspace';
      case 1:
        return 'Employees';
      case 2:
        return 'Attendance';
      case 3:
        return 'Leave Management';
      case 4:
        return 'Payroll';
      case 5:
        return 'My Profile';
      default:
        return 'HR Workspace';
    }
  }

  Widget _buildSidebar(BuildContext context) {
    return SizedBox(
      width: 280,
      child: _buildDrawerContent(context),
    );
  }

  Widget _buildDrawerContent(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDrawerHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              _buildCategoryHeader('Main'),
              _buildNavItem(0, 'Dashboard', Icons.dashboard_outlined, isMobile),
              const SizedBox(height: 12),
              _buildCategoryHeader('People'),
              _buildNavItem(1, 'Employees', Icons.people_outline, isMobile),
              _buildNavItem(2, 'Attendance', Icons.access_time, isMobile),
              _buildNavItem(3, 'Leave Management', Icons.event_available_outlined, isMobile),
              const SizedBox(height: 12),
              _buildCategoryHeader('Payroll'),
              _buildNavItem(4, 'Payroll', Icons.payments_outlined, isMobile),
              const SizedBox(height: 12),
              _buildCategoryHeader('Account'),
              _buildNavItem(5, 'My Profile', Icons.account_circle_outlined, isMobile),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.only(top: 48, bottom: 20, left: 20, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.business_center_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Cluro HRMS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            widget.user.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.user.email,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'HR REPRESENTATIVE',
              style: TextStyle(
                color: Color(0xFFC084FC),
                fontSize: 10,
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
      padding: const EdgeInsets.only(left: 12, top: 8, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon, bool isMobile) {
    final bool isSelected = _selectedPageIndex == index;
    final Color itemColor = isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF475569);
    final Color bgColor = isSelected ? const Color(0xFFF5F3FF) : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: bgColor,
        leading: Icon(icon, color: itemColor, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: itemColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: () {
          if (isMobile) {
            Navigator.pop(context); // Close mobile drawer
          }
          _onNavigate(index);
        },
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width >= 800;

    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            _buildSummaryGrid(context),
            const SizedBox(height: 24),
            _buildQuickActions(context),
            const SizedBox(height: 24),
            if (isWideScreen)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildRecentActivity(),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: _buildHealthIndicatorCard(),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildRecentActivity(),
                  const SizedBox(height: 20),
                  _buildHealthIndicatorCard(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'HR Operations Dashboard',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Track staff count, process attendance registers, approve leaves, and finalize month-end payroll payslips.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final int crossAxisCount = width < 600 ? 1 : (width < 1100 ? 2 : 4);

    final double childAspectRatio;
    if (crossAxisCount == 1) {
      childAspectRatio = 3.5;
    } else if (crossAxisCount == 2) {
      childAspectRatio = 2.2;
    } else {
      childAspectRatio = 1.8;
    }

    final summaryItems = [
      _SummaryCardData(
        title: 'Total Employees',
        value: _mockStats['totalEmployees'].toString(),
        icon: Icons.people_outline,
        color: const Color(0xFF8B5CF6),
      ),
      _SummaryCardData(
        title: 'Present Today',
        value: _mockStats['presentToday'].toString(),
        icon: Icons.watch_later_outlined,
        color: const Color(0xFF10B981),
      ),
      _SummaryCardData(
        title: 'Pending Leaves',
        value: _mockStats['pendingLeaves'].toString(),
        icon: Icons.event_available_outlined,
        color: const Color(0xFFF59E0B),
      ),
      _SummaryCardData(
        title: 'Payroll Status',
        value: _mockStats['payrollStatus'],
        icon: Icons.payments_outlined,
        color: const Color(0xFF2563EB),
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
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: data.color.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(data.icon, color: data.color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.title,
                    style: const TextStyle(
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
          'Operational Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: width < 600 ? 2.5 : 3.0,
          children: [
            _buildActionCard('Add Employee', Icons.person_add_alt_1_outlined, 1),
            _buildActionCard('Clock Registry', Icons.watch_later_outlined, 2),
            _buildActionCard('Leave Approvals', Icons.event_note_outlined, 3),
            _buildActionCard('Process Payroll', Icons.payments_outlined, 4),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String label, IconData icon, int targetIndex) {
    return InkWell(
      onTap: () => _onNavigate(targetIndex),
      borderRadius: BorderRadius.circular(8),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
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
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history_outlined, color: Color(0xFF8B5CF6), size: 20),
                SizedBox(width: 8),
                Text(
                  'Recent HR Activity Logs',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mockHrLogs.length,
              separatorBuilder: (context, index) => const Divider(height: 24, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final log = _mockHrLogs[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8B5CF6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log['action']!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            log['details']!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time, size: 12, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 4),
                                  Text(
                                    log['time']!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person_outline, size: 12, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'actor: ${log['actor']}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthIndicatorCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 20),
                SizedBox(width: 8),
                Text(
                  'Workspace Integrity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildHealthIndicator('Access Rights', 'HR MANAGER', true),
            const SizedBox(height: 12),
            _buildHealthIndicator('Operation Database', 'Operational', true),
            const SizedBox(height: 12),
            _buildHealthIndicator('Privacy Regulations', 'Enforced', true),
            const SizedBox(height: 12),
            _buildHealthIndicator('Audit Logging', 'Active', true),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthIndicator(String service, String status, bool isHealthy) {
    return Row(
      children: [
        Icon(
          isHealthy ? Icons.check_circle : Icons.error,
          color: isHealthy ? const Color(0xFF10B981) : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            service,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          status,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileWorkspace() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_box_outlined, color: Color(0xFF8B5CF6), size: 24),
                  SizedBox(width: 8),
                  Text(
                    'HR Representative Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildProfileField('Full Name', widget.user.name),
              _buildProfileField('Email Address', widget.user.email),
              _buildProfileField('Workspace Access Role', widget.user.role.name.toUpperCase()),
              _buildProfileField('Account Database UID', widget.user.uid, isCode: true),
              _buildProfileField('Security Clearances', 'Level 2 (HR Officer)'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String value, {bool isCode = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: isCode ? 'monospace' : null,
              color: isCode ? const Color(0xFF475569) : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderContent(String title, IconData icon) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F3FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 48,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'HR Representative Workspace',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B5CF6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This operations module is currently a placeholder. HR tools, lists, and underlying records for $title can be managed here once the backend models are integrated.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  OutlinedButton.icon(
                    onPressed: () => _onNavigate(0),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Return to Dashboard'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
