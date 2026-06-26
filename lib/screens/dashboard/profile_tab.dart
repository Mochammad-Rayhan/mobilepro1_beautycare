import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/user_model.dart';
import '../sign_in_screen.dart';

class ProfileTab extends StatelessWidget {
  final User user;

  const ProfileTab({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Clean, light grey background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            'Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111111),
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  _buildOptionsGroup(
                    context,
                    [
                      _ProfileOptionData(
                        icon: Icons.person_outline,
                        title: 'Edit Profile',
                        onTap: () {},
                      ),
                      _ProfileOptionData(
                        icon: Icons.notifications_none_outlined,
                        title: 'Notifications',
                        onTap: () {},
                      ),
                      _ProfileOptionData(
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildOptionsGroup(
                    context,
                    [
                      _ProfileOptionData(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () {},
                      ),
                      _ProfileOptionData(
                        icon: Icons.info_outline,
                        title: 'About App',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildOptionsGroup(
                    context,
                    [
                      _ProfileOptionData(
                        icon: Icons.logout_rounded,
                        title: 'Logout',
                        isDestructive: true,
                        onTap: () => _showLogoutDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100), // Space for bottom nav
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white, // Solid white background, no gradient
      padding: const EdgeInsets.only(top: 16, bottom: 32, left: 24, right: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF5F5F5),
              border: Border.all(color: const Color(0xFFEBEBEB), width: 1.5),
            ),
            child: const Center(
              child: Icon(
                Icons.person,
                size: 40,
                color: Color(0xFFCCCCCC),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111111),
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsGroup(BuildContext context, List<_ProfileOptionData> options) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA), width: 1), // Clean border
      ),
      child: Column(
        children: options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isLast = index == options.length - 1;

          return Column(
            children: [
              _buildProfileOption(
                context,
                icon: option.icon,
                title: option.title,
                onTap: option.onTap,
                isDestructive: option.isDestructive,
              ),
              if (!isLast)
                const Padding(
                  padding: EdgeInsets.only(left: 60, right: 16),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFF2F2F2),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final textColor = isDestructive ? const Color(0xFFD32F2F) : const Color(0xFF111111);
    final iconBgColor = isDestructive 
        ? const Color(0xFFFFF0F0) 
        : const Color(0xFFFDF1F3); // Very soft solid pink
    final iconColor = isDestructive 
        ? const Color(0xFFD32F2F) 
        : const Color(0xFFC98A8E); // Soft rose color for icon

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10), // Squircle feel
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (!isDestructive)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFFCCCCCC),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFD32F2F),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Are you sure you want to logout from your account?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF111111),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const SignInScreen()),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileOptionData {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  _ProfileOptionData({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });
}
