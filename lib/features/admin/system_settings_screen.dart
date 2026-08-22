import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/audit_log_service.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orgNameController = TextEditingController();
  final _timeoutController = TextEditingController();
  
  String _selectedTimezone = 'Asia/Kolkata'; // Default
  String _selectedDateFormat = 'YYYY-MM-DD';
  bool _emailNotificationsEnabled = true;

  // Track loaded settings to identify unsaved changes
  String _loadedOrgName = '';
  String _loadedTimezone = 'Asia/Kolkata';
  String _loadedDateFormat = 'YYYY-MM-DD';
  int _loadedTimeout = 30;
  bool _loadedEmailNotifications = true;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  final List<String> _timezones = ['Asia/Kolkata', 'UTC', 'GMT', 'IST', 'EST', 'CST', 'MST', 'PST'];
  final List<String> _dateFormats = ['YYYY-MM-DD', 'DD/MM/YYYY', 'MM/DD/YYYY'];

  @override
  void initState() {
    super.initState();
    _orgNameController.addListener(_onFieldChanged);
    _timeoutController.addListener(_onFieldChanged);
    _loadSettings();
  }

  @override
  void dispose() {
    _orgNameController.removeListener(_onFieldChanged);
    _timeoutController.removeListener(_onFieldChanged);
    _orgNameController.dispose();
    _timeoutController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool _hasUnsavedChanges() {
    final currentOrgName = _orgNameController.text.trim();
    final currentTimeout = int.tryParse(_timeoutController.text.trim()) ?? 30;
    return currentOrgName != _loadedOrgName ||
        _selectedTimezone != _loadedTimezone ||
        _selectedDateFormat != _loadedDateFormat ||
        currentTimeout != _loadedTimeout ||
        _emailNotificationsEnabled != _loadedEmailNotifications;
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('general')
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          final orgName = data['organizationName'] as String? ?? 'Cluro HRMS';
          final timeout = data['sessionTimeoutMinutes'] as int? ?? 30;
          final timezone = data['timezone'] as String? ?? 'Asia/Kolkata';
          final dateFormat = data['dateFormat'] as String? ?? 'YYYY-MM-DD';
          final emailNotif = data['emailNotificationsEnabled'] as bool? ?? true;

          _orgNameController.text = orgName;
          _timeoutController.text = timeout.toString();
          
          if (_timezones.contains(timezone)) {
            _selectedTimezone = timezone;
          }
          if (_dateFormats.contains(dateFormat)) {
            _selectedDateFormat = dateFormat;
          }
          _emailNotificationsEnabled = emailNotif;

          // Save loaded states
          _loadedOrgName = orgName;
          _loadedTimezone = _selectedTimezone;
          _loadedDateFormat = _selectedDateFormat;
          _loadedTimeout = timeout;
          _loadedEmailNotifications = _emailNotificationsEnabled;
        }
      } else {
        _orgNameController.text = 'Cluro HRMS';
        _timeoutController.text = '30';
        _selectedTimezone = 'Asia/Kolkata';
        
        _loadedOrgName = 'Cluro HRMS';
        _loadedTimezone = 'Asia/Kolkata';
        _loadedDateFormat = 'YYYY-MM-DD';
        _loadedTimeout = 30;
        _loadedEmailNotifications = true;
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load system settings: ${e.toString()}';
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final orgName = _orgNameController.text.trim();
      final timeout = int.parse(_timeoutController.text.trim());

      await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('general')
          .set({
        'organizationName': orgName,
        'timezone': _selectedTimezone,
        'dateFormat': _selectedDateFormat,
        'sessionTimeoutMinutes': timeout,
        'emailNotificationsEnabled': _emailNotificationsEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedByUid': user?.uid ?? 'unknown',
      });

      // Audit Log for System Settings modification
      await AuditLogService.logEvent(
        action: 'SYSTEM_SETTINGS_UPDATED',
        targetType: 'system',
        targetId: 'general',
        description: "Updated system settings for '$orgName'.",
        metadata: {
          'organizationName': orgName,
          'timezone': _selectedTimezone,
          'dateFormat': _selectedDateFormat,
          'sessionTimeoutMinutes': timeout,
          'emailNotificationsEnabled': _emailNotificationsEnabled,
        },
      );

      setState(() {
        _isSaving = false;
        _successMessage = 'System settings updated successfully.';
        
        // Reset loaded states to current saved states
        _loadedOrgName = orgName;
        _loadedTimezone = _selectedTimezone;
        _loadedDateFormat = _selectedDateFormat;
        _loadedTimeout = timeout;
        _loadedEmailNotifications = _emailNotificationsEnabled;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Failed to save system settings: ${e.toString()}';
      });
    }
  }

  void _cancelChanges() {
    setState(() {
      _orgNameController.text = _loadedOrgName;
      _selectedTimezone = _loadedTimezone;
      _selectedDateFormat = _loadedDateFormat;
      _timeoutController.text = _loadedTimeout.toString();
      _emailNotificationsEnabled = _loadedEmailNotifications;
      _errorMessage = null;
      _successMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          height: 28,
          width: 28,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final bool isWideScreen = MediaQuery.of(context).size.width >= 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              _buildAlert(
                color: const Color(0xFFFEE2E2),
                borderColor: const Color(0xFFFCA5A5),
                textColor: const Color(0xFF991B1B),
                icon: Icons.error_outline,
                message: _errorMessage!,
              ),
              const SizedBox(height: 16),
            ],
            if (_successMessage != null) ...[
              _buildAlert(
                color: const Color(0xFFD1FAE5),
                borderColor: const Color(0xFFA7F3D0),
                textColor: const Color(0xFF065F46),
                icon: Icons.check_circle_outline,
                message: _successMessage!,
              ),
              const SizedBox(height: 16),
            ],
            
            // 1. Organization Card (Full width)
            _buildSettingsSection(
              title: 'ORGANIZATION',
              description: 'Manage organization identity and regional preferences.',
              child: Column(
                children: [
                  TextFormField(
                    controller: _orgNameController,
                    enabled: !_isSaving,
                    decoration: const InputDecoration(
                      labelText: 'Organization Name',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Organization name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (isWideScreen)
                    Row(
                      children: [
                        Expanded(child: _buildTimezoneDropdown()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDateFormatDropdown()),
                      ],
                    )
                  else ...[
                    _buildTimezoneDropdown(),
                    const SizedBox(height: 16),
                    _buildDateFormatDropdown(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // 2. Security and Notifications (Side-by-side on wide screens, stacked on mobile)
            if (isWideScreen)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildSecurityCard()),
                  const SizedBox(width: 20),
                  Expanded(child: _buildNotificationsCard()),
                ],
              )
            else ...[
              _buildSecurityCard(),
              const SizedBox(height: 20),
              _buildNotificationsCard(),
            ],
            
            const SizedBox(height: 32),
            
            // 3. Action bar at bottom
            _buildActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Settings',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Configure how Cluro HRMS behaves across your organization.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildAlert({
    required Color color,
    required Color borderColor,
    required Color textColor,
    required IconData icon,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Inter',
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
            const Divider(height: 24, color: Color(0xFFE2E8F0)),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard() {
    return _buildSettingsSection(
      title: 'Security',
      description: 'Control administrator and staff session behavior.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _timeoutController,
            enabled: !_isSaving,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Session Timeout (Minutes)',
              prefixIcon: Icon(Icons.timer_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Session timeout is required';
              }
              final valInt = int.tryParse(value.trim());
              if (valInt == null || valInt < 5 || valInt > 1440) {
                return 'Timeout must be between 5 and 1440 minutes';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Users may be required to sign in again after prolonged inactivity.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard() {
    return _buildSettingsSection(
      title: 'Notifications',
      description: 'Control system-generated account notifications.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Email Notifications',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _emailNotificationsEnabled ? 'Enabled' : 'Disabled',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _emailNotificationsEnabled ? const Color(0xFF10B981) : const Color(0xFF64748B),
                ),
              ),
              Switch.adaptive(
                value: _emailNotificationsEnabled,
                onChanged: _isSaving
                    ? null
                    : (val) {
                        setState(() {
                          _emailNotificationsEnabled = val;
                        });
                      },
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Send email logs to staff members when account profile parameters are modified.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    final bool hasChanges = _hasUnsavedChanges();

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (hasChanges && !_isSaving) ...[
          const Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Color(0xFFF59E0B)),
              SizedBox(width: 6),
              Text(
                'Unsaved changes',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFB45309),
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
        ],
        TextButton(
          onPressed: (_isSaving || !hasChanges) ? null : _cancelChanges,
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveSettings,
          icon: const Icon(Icons.save_outlined, size: 16),
          label: Text(
            _isSaving
                ? 'Saving...'
                : (_successMessage != null && !hasChanges ? 'Saved' : 'Save Changes'),
          ),
        ),
      ],
    );
  }

  Widget _buildTimezoneDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedTimezone,
      decoration: const InputDecoration(
        labelText: 'Timezone',
        prefixIcon: Icon(Icons.public_outlined),
      ),
      items: _timezones.map((tz) {
        return DropdownMenuItem(value: tz, child: Text(tz));
      }).toList(),
      onChanged: _isSaving
          ? null
          : (val) {
              if (val != null) {
                setState(() {
                  _selectedTimezone = val;
                });
              }
            },
    );
  }

  Widget _buildDateFormatDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedDateFormat,
      decoration: const InputDecoration(
        labelText: 'Date Format',
        prefixIcon: Icon(Icons.date_range_outlined),
      ),
      items: _dateFormats.map((df) {
        return DropdownMenuItem(value: df, child: Text(df));
      }).toList(),
      onChanged: _isSaving
          ? null
          : (val) {
              if (val != null) {
                setState(() {
                  _selectedDateFormat = val;
                });
              }
            },
    );
  }
}
