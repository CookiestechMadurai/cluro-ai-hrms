import 'package:flutter/material.dart';
import '../../services/audit_log_service.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedActionFilter = 'All';

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

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width >= 800;

    return StreamBuilder<List<AuditLogEntry>>(
      stream: AuditLogService.streamAuditLogs(),
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
                    'Error Loading Audit Logs',
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

        final logs = snapshot.data ?? [];

        // Apply filters
        final filteredLogs = logs.where((log) {
          final matchesSearch = log.actorEmail.toLowerCase().contains(_searchQuery) ||
              log.description.toLowerCase().contains(_searchQuery) ||
              log.targetId.toLowerCase().contains(_searchQuery);

          final matchesAction = _selectedActionFilter == 'All' ||
              log.action == _selectedActionFilter;

          return matchesSearch && matchesAction;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildFilterSection(isWideScreen),
              const SizedBox(height: 20),
              if (filteredLogs.isEmpty)
                _buildEmptyState()
              else if (isWideScreen)
                _buildDesktopTable(filteredLogs)
              else
                _buildMobileCardList(filteredLogs),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Audit Logs',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Track administrative and security-sensitive activity.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection(bool isWideScreen) {
    final searchField = TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        labelText: 'Search by Actor, Description, or Target ID',
        prefixIcon: Icon(Icons.search),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );

    final actionFilter = DropdownButtonFormField<String>(
      initialValue: _selectedActionFilter,
      decoration: const InputDecoration(
        labelText: 'Action Filter',
        prefixIcon: Icon(Icons.history),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: const [
        DropdownMenuItem(value: 'All', child: Text('All Actions')),
        DropdownMenuItem(value: 'USER_CREATED', child: Text('USER_CREATED')),
        DropdownMenuItem(value: 'USER_UPDATED', child: Text('USER_UPDATED')),
        DropdownMenuItem(value: 'ROLE_CHANGED', child: Text('ROLE_CHANGED')),
        DropdownMenuItem(value: 'STATUS_CHANGED', child: Text('STATUS_CHANGED')),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedActionFilter = val;
          });
        }
      },
    );

    if (isWideScreen) {
      return Row(
        children: [
          Expanded(flex: 2, child: searchField),
          const SizedBox(width: 12),
          Expanded(child: actionFilter),
        ],
      );
    }

    return Column(
      children: [
        searchField,
        const SizedBox(height: 12),
        actionFilter,
      ],
    );
  }

  Widget _buildDesktopTable(List<AuditLogEntry> filteredLogs) {
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
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('Timestamp', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
            DataColumn(label: Text('Action', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
            DataColumn(label: Text('Actor', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
            DataColumn(label: Text('Description', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
            DataColumn(label: Text('Target UID', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
          ],
          rows: filteredLogs.map((log) {
            final timestampStr = log.createdAt.toLocal().toString().substring(0, 19);
            return DataRow(
              cells: [
                DataCell(Text(timestampStr, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B)))),
                DataCell(_buildActionBadge(log.action)),
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log.actorEmail, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A))),
                      Text(log.actorUid, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontFamily: 'monospace')),
                    ],
                  ),
                ),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Text(
                      log.description,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF0F172A)),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ),
                DataCell(
                  SelectableText(
                    log.targetId,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF475569)),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileCardList(List<AuditLogEntry> filteredLogs) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredLogs.length,
      itemBuilder: (context, index) {
        final log = filteredLogs[index];
        final timestampStr = log.createdAt.toLocal().toString().substring(0, 19);

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
                    _buildActionBadge(log.action),
                    Text(
                      timestampStr,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  log.description,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFF1F5F9)),
                const SizedBox(height: 4),
                _buildMetaRow('Actor Email', log.actorEmail),
                _buildMetaRow('Actor UID', log.actorUid, isCode: true),
                _buildMetaRow('Target UID', log.targetId, isCode: true),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetaRow(String label, String value, {bool isCode = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 11,
                fontFamily: isCode ? 'monospace' : 'Inter',
                color: const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBadge(String action) {
    Color color;
    Color bgColor;

    switch (action) {
      case 'USER_CREATED':
        color = const Color(0xFF065F46);
        bgColor = const Color(0xFFD1FAE5);
        break;
      case 'USER_UPDATED':
        color = const Color(0xFF1E3A8A);
        bgColor = const Color(0xFFDBEAFE);
        break;
      case 'ROLE_CHANGED':
        color = const Color(0xFF5B21B6);
        bgColor = const Color(0xFFEDE9FE);
        break;
      case 'STATUS_CHANGED':
        color = const Color(0xFFB45309);
        bgColor = const Color(0xFFFEF3C7);
        break;
      default:
        color = const Color(0xFF475569);
        bgColor = const Color(0xFFF1F5F9);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        action,
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
            const Icon(Icons.history, size: 40, color: Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            const Text(
              'No audit logs found',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try refining your search terms or selecting a different action filter.',
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
                  _selectedActionFilter = 'All';
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
