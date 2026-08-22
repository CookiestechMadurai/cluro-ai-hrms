import 'package:flutter/material.dart';
import '../../models/user_role.dart';
import '../../models/role_permission.dart';

class RolesPermissionsScreen extends StatefulWidget {
  const RolesPermissionsScreen({super.key});

  @override
  State<RolesPermissionsScreen> createState() => _RolesPermissionsScreenState();
}

class _RolesPermissionsScreenState extends State<RolesPermissionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width >= 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildSecurityNotice(),
          const SizedBox(height: 24),
          if (isWideScreen)
            _buildDesktopMatrixTable()
          else
            _buildMobileRoleWorkspace(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Roles & Permissions',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Permissions determine which areas of Cluro HRMS each role can access.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: Color(0xFFD97706), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Application Configuration Security Notice',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'This matrix reflects client-side operational features mapped to system roles. Altering configurations here does NOT dynamically write or update Firestore Security Rules. Database security limits remain enforced by cloud configuration files.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFFB45309),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopMatrixTable() {
    final features = RolePermissionMatrix.initialMatrix;

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
          dataRowMinHeight: 48,
          dataRowMaxHeight: 48,
          horizontalMargin: 20,
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('Feature Name', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
            DataColumn(label: Text('Category', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
            DataColumn(label: Text('Admin', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
            DataColumn(label: Text('HR', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
            DataColumn(label: Text('Employee', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
          ],
          rows: features.map((feature) {
            return DataRow(
              cells: [
                DataCell(Text(feature.featureName, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)))),
                DataCell(Text(feature.category, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B)))),
                DataCell(_buildAccessBadge(feature.accessMap[UserRole.admin]!)),
                DataCell(_buildAccessBadge(feature.accessMap[UserRole.hr]!)),
                DataCell(_buildAccessBadge(feature.accessMap[UserRole.employee]!)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileRoleWorkspace() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF2563EB),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF2563EB),
            labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13),
            tabs: const [
              Tab(text: 'Admin'),
              Tab(text: 'HR'),
              Tab(text: 'Employee'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 520,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRolePermissionList(UserRole.admin),
              _buildRolePermissionList(UserRole.hr),
              _buildRolePermissionList(UserRole.employee),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRolePermissionList(UserRole role) {
    final features = RolePermissionMatrix.initialMatrix;
    
    // Group features by Category
    final Map<String, List<PermissionFeature>> grouped = {};
    for (var f in features) {
      grouped.putIfAbsent(f.category, () => []).add(f);
    }

    return ListView(
      shrinkWrap: true,
      children: grouped.entries.map((entry) {
        return Card(
          elevation: 0,
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFF1F5F9)),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: entry.value.length,
                  itemBuilder: (context, index) {
                    final item = entry.value[index];
                    final access = item.accessMap[role]!;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.featureName,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          _buildAccessBadge(access),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAccessBadge(AccessLevel access) {
    Color color;
    Color bgColor;

    switch (access) {
      case AccessLevel.allowed:
        color = const Color(0xFF065F46);
        bgColor = const Color(0xFFD1FAE5);
        break;
      case AccessLevel.manage:
        color = const Color(0xFF1E3A8A);
        bgColor = const Color(0xFFDBEAFE);
        break;
      case AccessLevel.viewOnly:
        color = const Color(0xFF5B21B6);
        bgColor = const Color(0xFFEDE9FE);
        break;
      case AccessLevel.hrUse:
        color = const Color(0xFFB45309);
        bgColor = const Color(0xFFFEF3C7);
        break;
      case AccessLevel.ownOnly:
        color = const Color(0xFF0369A1);
        bgColor = const Color(0xFFE0F2FE);
        break;
      case AccessLevel.denied:
        color = const Color(0xFF991B1B);
        bgColor = const Color(0xFFFEE2E2);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        access.shortSymbol,
        style: TextStyle(
          fontFamily: 'Inter',
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
