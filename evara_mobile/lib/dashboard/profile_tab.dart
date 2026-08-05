import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/token_storage.dart';
import '../core/api_client.dart';
import '../core/api_config.dart';
import '../core/app_colors.dart';
import '../onboarding/auth_page_three.dart';
import '../onboarding/onboarding_container.dart';
import '../screens/edit_profile_sheet.dart';
import '../screens/privacy_policy_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isLoading = true;

  // Profile data matching backend response
  String _username = '';
  String _email = '';
  String? _profilePictureUrl;
  String _createdAt = '';
  int _chaptersCount = 0;
  int _capsulesCount = 0;
  int _openedCapsulesCount = 0;
  int _reflectionsCount = 0;

  // Notification settings mapping to backend
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _reminders = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
    _fetchNotificationSettings();
  }

  Future<void> _fetchProfileData() async {
    try {
      final response = await ApiClient.get(ApiConfig.profile);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _username = data['username'] ?? '';
          _email = data['email'] ?? '';
          _profilePictureUrl = data['profile_picture'];
          _createdAt = data['created_at'] ?? '';
          _chaptersCount = data['chapters_count'] ?? 0;
          _capsulesCount = data['capsules_count'] ?? 0;
          _openedCapsulesCount = data['opened_capsules_count'] ?? 0;
          _reflectionsCount = data['reflections_count'] ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Failed to load profile data.', isError: true);
    }
  }

  Future<void> _fetchNotificationSettings() async {
    try {
      final response = await ApiClient.get(ApiConfig.notificationSettings);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _emailNotifications = data['email_notifications'] ?? true;
          _pushNotifications = data['push_notifications'] ?? true;
          _reminders = data['reminders'] ?? true;
        });
      }
    } catch (e) {
      // Handle silently
    }
  }

  Future<void> _updateNotificationSetting(String key, bool value) async {
    setState(() {
      if (key == 'email_notifications') _emailNotifications = value;
      if (key == 'push_notifications') _pushNotifications = value;
      if (key == 'reminders') _reminders = value;
    });

    try {
      final headers = await ApiClient.authHeaders();
      final response = await http.patch(
        Uri.parse(ApiConfig.notificationSettings),
        headers: headers,
        body: jsonEncode({key: value}),
      );

      if (response.statusCode != 200) {
        throw Exception();
      }
    } catch (e) {
      setState(() {
        if (key == 'email_notifications') _emailNotifications = !value;
        if (key == 'push_notifications') _pushNotifications = !value;
        if (key == 'reminders') _reminders = !value;
      });
      _showSnackBar('Failed to update notification settings.', isError: true);
    }
  }

  String _calculateStorySpan() {
    if (_createdAt.isEmpty) return '0 years';
    try {
      final createdDate = DateTime.parse(_createdAt);
      final difference = DateTime.now().difference(createdDate);
      final years = difference.inDays ~/ 365;
      if (years < 1) {
        final months = difference.inDays ~/ 30;
        if (months < 1) return 'less than a month'; // Lowercase 'l'
        return '$months month${months > 1 ? 's' : ''}';
      }
      return '$years year${years > 1 ? 's' : ''}';
    } catch (e) {
      return '0 years';
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.lavender,
      ),
    );
  }

  void _openEditProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => EditProfileSheet(
        currentUsername: _username,
        currentProfilePicture: _profilePictureUrl,
        onProfileUpdated: () {
          _fetchProfileData();
        },
      ),
    );
  }

  void _openDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete your account? All your data, chapters, and capsules will be permanently removed.',
          style: TextStyle(color: Color(0xFF5A5A5A)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final response = await ApiClient.delete(ApiConfig.deleteAccount);
                if (response.statusCode == 200) {
                  await TokenStorage.clearTokens();
                  // Navigate to OnboardingContainer so the user experiences the app fresh from the beginning
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const OnboardingContainer()),
                        (route) => false,
                  );
                }
              } catch (e) {
                _showSnackBar('Failed to delete account.', isError: true);
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    await TokenStorage.clearTokens();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthPageThree()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.lavender))
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), // Extra bottom padding so bottom nav bar doesn't hide content
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 20),

              // Profile Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.lavender.withOpacity(0.2),
                      backgroundImage: _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty
                          ? NetworkImage(ApiConfig.buildMediaUrl(_profilePictureUrl))
                          : null,
                      child: _profilePictureUrl == null || _profilePictureUrl!.isEmpty
                          ? Text(
                        _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.lavender,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _username,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your story spans\n${_calculateStorySpan()}.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF666666),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _openEditProfileSheet,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.lavender.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.lavender,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats Grid (2x2) - Centered numbers & Black text
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    icon: Icons.inventory_2_outlined,
                    title: 'Capsules created',
                    count: _capsulesCount,
                    color: AppColors.twilightPurple,
                  ),
                  _buildStatCard(
                    icon: Icons.mail_outline_rounded,
                    title: 'Opened',
                    count: _openedCapsulesCount,
                    color: AppColors.rosePink,
                  ),
                  _buildStatCard(
                    icon: Icons.menu_book_rounded,
                    title: 'Life chapters',
                    count: _chaptersCount,
                    color: AppColors.lavender,
                  ),
                  _buildStatCard(
                    icon: Icons.lightbulb_outline_rounded,
                    title: 'Reflections',
                    count: _reflectionsCount,
                    color: AppColors.mauve,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Settings Section Header
              const Text(
                'SETTINGS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Color(0xFF7A7A7A),
                ),
              ),
              const SizedBox(height: 12),

              // Settings Container Block
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Email Notifications',
                      value: _emailNotifications,
                      onChanged: (val) => _updateNotificationSetting('email_notifications', val),
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildSwitchTile(
                      icon: Icons.phone_android_rounded,
                      title: 'Push Notifications',
                      value: _pushNotifications,
                      onChanged: (val) => _updateNotificationSetting('push_notifications', val),
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildSwitchTile(
                      icon: Icons.alarm_rounded,
                      title: 'Reminders',
                      value: _reminders,
                      onChanged: (val) => _updateNotificationSetting('reminders', val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // About Section Header
              const Text(
                'ABOUT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Color(0xFF7A7A7A),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded, color: AppColors.lavender),
                      title: const Text('Version', style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF2D2D2D))),
                      trailing: const Text('1.0.0', style: TextStyle(color: Color(0xFF7A7A7A))),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.lavender),
                      title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF2D2D2D))),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Account Actions Section Header
              const Text(
                'ACCOUNT ACTIONS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Color(0xFF7A7A7A),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout_rounded, color: Color(0xFF7A7A7A)),
                      title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF2D2D2D))),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                      onTap: _logout,
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                      title: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.error)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                      onTap: _openDeleteAccountDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A), // Centered black text color
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7A7A7A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.lavender, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D2D2D),
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.lavender,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}