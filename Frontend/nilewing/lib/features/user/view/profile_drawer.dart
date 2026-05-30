import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nilewing/core/theme/app_colors.dart';
import 'package:nilewing/core/providers/auth_provider.dart';
import 'package:nilewing/core/routes/app_router.dart';
import 'package:nilewing/features/auth/service/login_service.dart';
import 'package:nilewing/features/user/viewmodel/user_view_model.dart';
import 'package:nilewing/features/safety/view/safe_woman_dashboard.dart';

class ProfileDrawer extends ConsumerWidget {
  const ProfileDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(userViewModelProvider);
    final profile = viewModel.userProfile;

    return Drawer(
      backgroundColor: const Color(0xFFF5F7FA), // Light, premium background
      child: Column(
        children: [
          // Elevated Profile Header
          _buildProfileHeader(context, ref, profile),

          // Menu Items - Scrollable area
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              children: [
                // GROUP 1: Account
                _buildMenuGroup(
                  title: 'Account Settings',
                  children: [
                    _buildMenuItem(
                      context: context,
                      icon: Icons.person_outline,
                      iconBackgroundColor: Colors.blue.shade100,
                      iconColor: Colors.blue.shade700,
                      title: 'View Profile',
                      subtitle: 'See and update your profile',
                      onTap: () => _delayedGo(context, '/profile'),
                      isLast: true,
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                // GROUP 2: Discover & Safety
                _buildMenuGroup(
                  title: 'Discover & Safety',
                  children: [
                    _buildMenuItem(
                      context: context,
                      icon: Icons.hotel_outlined,
                      iconBackgroundColor: Colors.teal.shade100,
                      iconColor: Colors.teal.shade700,
                      title: 'Nearby Accommodations',
                      subtitle: 'Find hotels and places near you',
                      onTap: () => _delayedGo(context, '/recommendations'),
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.shield_outlined,
                      iconBackgroundColor: Colors.purple.shade100,
                      iconColor: Colors.purple.shade700,
                      title: 'Safe Woman',
                      subtitle: 'Safety features & resources',
                      onTap: () => _showSafeWoman(context),
                      isLast: true,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // GROUP 3: Support
                _buildMenuGroup(
                  title: 'Support & Info',
                  children: [
                    _buildMenuItem(
                      context: context,
                      icon: Icons.help_outline,
                      iconBackgroundColor: Colors.green.shade100,
                      iconColor: Colors.green.shade700,
                      title: 'Help & Support',
                      subtitle: 'Get assistance and FAQs',
                      onTap: () => _showHelpSupport(context),
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.info_outline,
                      iconBackgroundColor: Colors.indigo.shade100,
                      iconColor: Colors.indigo.shade700,
                      title: 'About Nile Wing',
                      subtitle: 'Learn about our mission',
                      onTap: () => _showAboutDialog(context),
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.description_outlined,
                      iconBackgroundColor: Colors.blueGrey.shade100,
                      iconColor: Colors.blueGrey.shade700,
                      title: 'Terms of Use',
                      subtitle: 'Legal information',
                      onTap: () => _showTermsOfUse(context),
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.code_outlined,
                      iconBackgroundColor: Colors.brown.shade100,
                      iconColor: Colors.brown.shade700,
                      title: 'App Info',
                      subtitle: 'Version and developer credits',
                      onTap: () => _showAppInfoDialog(context),
                      isLast: true,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // GROUP 4: Danger Zone
                _buildMenuGroup(
                  title: 'Danger Zone',
                  children: [
                    _buildMenuItem(
                      context: context,
                      icon: Icons.logout,
                      iconBackgroundColor: Colors.red.shade50,
                      iconColor: Colors.red.shade600,
                      textColor: Colors.red.shade600,
                      title: 'Logout',
                      subtitle: 'Sign out of your account',
                      onTap: () => _handleLogout(context, ref),
                      isLast: true,
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _delayedGo(BuildContext context, String route) {
    Navigator.pop(context); // Close drawer
    Future.delayed(const Duration(milliseconds: 150), () {
      context.go(route);
    });
  }

  Widget _buildProfileHeader(BuildContext context, WidgetRef ref, dynamic profile) {
    final profileImageUrl = profile?.profileImageUrl;
    final fullName = profile?.fullName ?? 'Traveler';
    final email = profile?.email ?? '';
    final nationality = profile?.nationality ?? 'Not specified';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _delayedGo(context, '/profile'),
        splashColor: Colors.white24,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Photo with glowing ring
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: ClipOval(
                  child: profileImageUrl != null && profileImageUrl.isNotEmpty
                      ? Image.network(
                          profileImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
                        )
                      : _buildDefaultAvatar(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Name
            Text(
              fullName,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 6),

            // Email tag
            if (email.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.email_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      email,
                      style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

            if (nationality.isNotEmpty && nationality != 'Not specified')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.public, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      nationality,
                      style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(Icons.person_rounded, size: 45, color: Colors.grey.shade400),
    );
  }

  Widget _buildMenuGroup({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required Color iconBackgroundColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: !isLast
                ? Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1))
                : null,
          ),
          child: Row(
            children: [
              // Squircle Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),

              // Texts
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
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: textColor != null ? textColor.withOpacity(0.7) : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- Actions ---

  void _showAboutDialog(BuildContext context) {
    Navigator.of(context).pop();
    Future.delayed(const Duration(milliseconds: 100), () {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('About Nile Wing', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'Nile Wing is a travel companion app designed to help travelers connect with like-minded people on their journeys.\n\nOur Mission: To make travel safer, more social, and more enjoyable.',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    });
  }

  void _showAppInfoDialog(BuildContext context) {
    Navigator.of(context).pop();
    Future.delayed(const Duration(milliseconds: 100), () {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('App Information', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'Version: 1.0.0\n\nDeveloped by Nile Wing Team\n© 2025 Nile Wing. All rights reserved.',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    });
  }

  void _showSafeWoman(BuildContext context) {
    Navigator.of(context).pop();
    Future.delayed(const Duration(milliseconds: 100), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SafeWomanDashboard()),
      );
    });
  }

  void _showBlockedUsers(BuildContext context) {
    Navigator.of(context).pop();
    Future.delayed(const Duration(milliseconds: 100), () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Blocked Users management coming soon!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    });
  }

  void _showHelpSupport(BuildContext context) {
    Navigator.of(context).pop();
    Future.delayed(const Duration(milliseconds: 100), () {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'Email: afomiaandualem@gmail.com\nPhone: +251936337889\nHours: Mon-Fri, 9 AM - 6 PM',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
    });
  }

  void _showTermsOfUse(BuildContext context) {
    Navigator.of(context).pop();
    Future.delayed(const Duration(milliseconds: 100), () {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Terms of Use', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            '1. Must be 18 years or older.\n2. Responsible for interactions.\n3. No false information.',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
    });
  }

  void _showSettings(BuildContext context) {
    Navigator.of(context).pop();
    Future.delayed(const Duration(milliseconds: 100), () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Settings screen coming soon!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    });
  }

  Future<void> _handleDeleteAccount(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
        content: const Text('Are you sure you want to permanently delete your account? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (context.mounted) {
        Navigator.pop(context); // close loading
        final authNotifier = ref.read(authStateProvider.notifier);
        await authNotifier.logout();
        ref.read(routerProvider).go('/login');
      }
    }
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authNotifier = ref.read(authStateProvider.notifier);
      final router = ref.read(routerProvider);
      if (context.mounted) Navigator.of(context).pop(); // close drawer
      await LoginService().logout();
      await authNotifier.logout();
      router.go('/login');
    }
  }
}
