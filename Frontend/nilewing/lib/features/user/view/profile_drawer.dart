import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nilewing/core/theme/app_colors.dart';
import 'package:nilewing/core/providers/auth_provider.dart';
import 'package:nilewing/features/auth/service/login_service.dart';
import 'package:nilewing/features/user/viewmodel/user_view_model.dart';

class ProfileDrawer extends ConsumerWidget {
  const ProfileDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(userViewModelProvider);
    final profile = viewModel.userProfile;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Profile Header Section
            _buildProfileHeader(context, ref, profile),

            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // View Profile
                  _buildMenuItem(
                    context: context,
                    icon: Icons.person_outline,
                    title: 'View Profile',
                    subtitle: 'See and update  your complete profile',
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Future.delayed(const Duration(milliseconds: 100), () {
                        context.go('/profile');
                      });
                    },
                  ),

                  // Edit your information
                  // _buildMenuItem(
                  //   context: context,
                  //   icon: Icons.edit_outlined,
                  //   title: 'Edit your information',
                  //   subtitle: 'Update your profile details',
                  //   onTap: () {
                  //     Navigator.pop(context); // Close drawer
                  //     Future.delayed(const Duration(milliseconds: 100), () {
                  //       context.go('/profile');
                  //       // Trigger edit mode - you may need to add a parameter or state
                  //     });
                  //   },
                  // ),

                  // const Divider(height: 1),

                  // About Nile Wing
                  _buildMenuItem(
                    context: context,
                    icon: Icons.info_outline,
                    title: 'About Nile Wing',
                    subtitle: 'Learn about our mission',
                    onTap: () => _showAboutDialog(context),
                  ),

                  // App info & developer credits
                  _buildMenuItem(
                    context: context,
                    icon: Icons.code_outlined,
                    title: 'App info & developer credits',
                    subtitle: 'Version and credits',
                    onTap: () => _showAppInfoDialog(context),
                  ),

                  const Divider(height: 1),

                  // Hotel Suggestions
                  _buildMenuItem(
                    context: context,
                    icon: Icons.hotel_outlined,
                    title: 'Hotel Suggestions',
                    subtitle: 'Find nearby accommodations',
                    onTap: () => _navigateToRecommendations(context),
                  ),

                  // Find nearby accommodations
                  _buildMenuItem(
                    context: context,
                    icon: Icons.location_on_outlined,
                    title: 'Find nearby accommodations',
                    subtitle: 'Search hotels near you',
                    onTap: () => _navigateToRecommendations(context),
                  ),

                  const Divider(height: 1),

                  // Safe Woman
                  _buildMenuItem(
                    context: context,
                    icon: Icons.shield_outlined,
                    title: 'Safe Woman',
                    subtitle: 'Safety features & resources',
                    onTap: () => _showSafeWomanComingSoon(context),
                  ),

                  // Reports/Blocked
                  _buildMenuItem(
                    context: context,
                    icon: Icons.block_outlined,
                    title: 'Reports/Blocked',
                    subtitle: 'Manage blocked users',
                    onTap: () => _showBlockedUsers(context),
                  ),

                  const Divider(height: 1),

                  // Help and Support
                  _buildMenuItem(
                    context: context,
                    icon: Icons.help_outline,
                    title: 'Help and Support',
                    subtitle: 'Get assistance',
                    onTap: () => _showHelpSupport(context),
                  ),

                  // Terms of Use
                  _buildMenuItem(
                    context: context,
                    icon: Icons.description_outlined,
                    title: 'Terms of Use',
                    subtitle: 'Legal information',
                    onTap: () => _showTermsOfUse(context),
                  ),

                  const Divider(height: 1),

                  // Settings
                  _buildMenuItem(
                    context: context,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'App preferences',
                    onTap: () => _showSettings(context),
                  ),

                  // Account
                  _buildMenuItem(
                    context: context,
                    icon: Icons.account_circle_outlined,
                    title: 'Account',
                    subtitle: 'Manage your account',
                    onTap: () => _showAccountSettings(context),
                  ),

                  const Divider(height: 1),

                  // Delete Account
                  _buildMenuItem(
                    context: context,
                    icon: Icons.delete_outline,
                    title: 'Delete Account',
                    subtitle: 'Permanently remove account',
                    textColor: Colors.red,
                    iconColor: Colors.red,
                    onTap: () => _handleDeleteAccount(context, ref),
                  ),

                  const SizedBox(height: 8),

                  // Logout
                  _buildMenuItem(
                    context: context,
                    icon: Icons.logout,
                    title: 'Logout',
                    subtitle: 'Sign out of your account',
                    textColor: Colors.red,
                    iconColor: Colors.red,
                    onTap: () => _handleLogout(context, ref),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    WidgetRef ref,
    dynamic profile,
  ) {
    final profileImageUrl = profile?.profileImageUrl;
    final fullName = profile?.fullName ?? 'User';
    final email = profile?.email ?? '';
    final nationality = profile?.nationality ?? 'Not specified';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, bottom: 24, left: 20, right: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context); // Close drawer
          Future.delayed(const Duration(milliseconds: 100), () {
            context.go('/profile');
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Photo - Larger, more prominent
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: profileImageUrl != null && profileImageUrl.isNotEmpty
                    ? Image.network(
                        profileImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultAvatar();
                        },
                      )
                    : _buildDefaultAvatar(),
              ),
            ),
            const SizedBox(height: 20),

            // Name - Larger, bolder
            Text(
              fullName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Email - More visible
            if (email.isNotEmpty)
              Row(
                children: [
                  const Icon(
                    Icons.email_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      email,
                      style: const TextStyle(fontSize: 15, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

            if (email.isNotEmpty &&
                nationality.isNotEmpty &&
                nationality != 'Not specified')
              const SizedBox(height: 6),

            // Nationality - More visible
            if (nationality.isNotEmpty && nationality != 'Not specified')
              Row(
                children: [
                  const Icon(
                    Icons.flag_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    nationality,
                    style: const TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.white.withOpacity(0.2),
      child: const Icon(Icons.person, size: 40, color: Colors.white),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    final isDestructive = textColor == Colors.red;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon with background
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),

            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDestructive ? Colors.red[300] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  // Menu Item Actions
  void _showAboutDialog(BuildContext context) {
    Navigator.of(context).pop(); // Close drawer first
    Future.delayed(const Duration(milliseconds: 100), () {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('About Nile Wing'),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nile Wing',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  'Nile Wing is a travel companion app designed to help travelers connect with like-minded people on their journeys.',
                ),
                SizedBox(height: 12),
                Text(
                  'Our Mission:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'To make travel safer, more social, and more enjoyable by connecting travelers who share similar routes, destinations, and interests.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    });
  }

  void _showAppInfoDialog(BuildContext context) {
    Navigator.of(context).pop(); // Close drawer first
    Future.delayed(const Duration(milliseconds: 100), () {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('App Information'),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nile Wing',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Version: 1.0.0'),
                SizedBox(height: 16),
                Text(
                  'Developer Credits:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Developed by Nile Wing Team'),
                SizedBox(height: 8),
                Text('© 2025 Nile Wing. All rights reserved.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    });
  }

  void _navigateToRecommendations(BuildContext context) {
    Navigator.of(context).pop(); // Close drawer
    Future.delayed(const Duration(milliseconds: 100), () {
      context.go('/recommendations');
    });
  }

  void _showSafeWomanComingSoon(BuildContext context) {
    Navigator.of(context).pop(); // Close drawer
    Future.delayed(const Duration(milliseconds: 100), () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Safe Woman feature coming soon!'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  void _showBlockedUsers(BuildContext context) {
    Navigator.of(context).pop(); // Close drawer
    Future.delayed(const Duration(milliseconds: 100), () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Blocked Users management coming soon!'),
          duration: Duration(seconds: 2),
        ),
      );
    });
    // TODO: Navigate to blocked users screen
  }

  void _showHelpSupport(BuildContext context) {
    Navigator.of(context).pop(); // Close drawer first
    Future.delayed(const Duration(milliseconds: 100), () {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Help & Support'),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get Assistance',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 12),
                Text('Email: support@nilewing.com'),
                SizedBox(height: 8),
                Text('Phone: +1 (555) 123-4567'),
                SizedBox(height: 8),
                Text('Hours: Mon-Fri, 9 AM - 6 PM'),
                SizedBox(height: 12),
                Text(
                  'Common Questions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• How to add a flight?'),
                Text('• How to connect with travelers?'),
                Text('• How to report a user?'),
                Text('• How to update my profile?'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Open email client
                Navigator.pop(dialogContext);
              },
              child: const Text('Contact Support'),
            ),
          ],
        ),
      );
    });
  }

  void _showTermsOfUse(BuildContext context) {
    Navigator.of(context).pop(); // Close drawer first
    Future.delayed(const Duration(milliseconds: 100), () {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Terms of Use'),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Legal Information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 12),
                Text('By using Nile Wing, you agree to the following terms:'),
                SizedBox(height: 8),
                Text('1. You must be 18 years or older to use this app.'),
                SizedBox(height: 8),
                Text(
                  '2. You are responsible for your interactions with other users.',
                ),
                SizedBox(height: 8),
                Text('3. You must not share false information.'),
                SizedBox(height: 8),
                Text(
                  '4. We reserve the right to suspend accounts that violate our terms.',
                ),
                SizedBox(height: 12),
                Text(
                  'For the complete terms of service, please visit our website.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    });
  }

  void _showSettings(BuildContext context) {
    Navigator.of(context).pop(); // Close drawer
    Future.delayed(const Duration(milliseconds: 100), () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings screen coming soon!'),
          duration: Duration(seconds: 2),
        ),
      );
    });
    // TODO: Navigate to settings screen
  }

  void _showAccountSettings(BuildContext context) {
    Navigator.of(context).pop(); // Close drawer
    Future.delayed(const Duration(milliseconds: 100), () {
      context.go('/profile');
      // TODO: Navigate to account settings screen
    });
  }

  Future<void> _handleDeleteAccount(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop(); // Close drawer

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // TODO: Implement delete account API call
      await Future.delayed(const Duration(seconds: 1));

      if (context.mounted) {
        Navigator.pop(context); // Close loading

        // Logout after deletion
        final loginService = LoginService();
        await loginService.logout();
        ref.read(authStateProvider.notifier).logout();

        if (context.mounted) {
          context.go('/login');
        }
      }
    }
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop(); // Close drawer

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final loginService = LoginService();
      await loginService.logout();

      ref.read(authStateProvider.notifier).logout();

      if (context.mounted) {
        context.go('/login');
      }
    }
  }
}
