// features/main_navigation/main_navigation_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainNavigationScreen extends StatefulWidget {
  final Widget child;

  const MainNavigationScreen({super.key, required this.child});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    if (location.startsWith('/myflights')) return 0;
    if (location.startsWith('/match')) return 1;
    if (location.startsWith('/chat')) return 2;
    if (location.startsWith('/recommendations')) return 3;
    if (location.startsWith('/home')) return 4;

    return 4; // Default to home
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/myflights');
        break;
      case 1:
        context.go('/match');
        break;
      case 2:
        context.go('/chat');
        break;
      case 3:
        context.go('/recommendations');
        break;
      case 4:
        context.go('/home');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _buildBottomNavigation(currentIndex, context),
    );
  }

  Widget _buildBottomNavigation(int currentIndex, BuildContext context) {
    final navItems = [
      _buildNavItem('My Flights', '✈️', 0, currentIndex, context),
      _buildNavItem('Match', '⚡', 1, currentIndex, context),
      _buildNavItem('Chat', '💬', 2, currentIndex, context),
      _buildNavItem('Recommendations', '🎯', 3, currentIndex, context),
      _buildNavItem('Home', '🏠', 4, currentIndex, context),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    String label,
    String icon,
    int index,
    int currentIndex,
    BuildContext context,
  ) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index, context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    Color(0xFF1E40AF).withOpacity(0.2),
                    Color(0xFF06B6D4).withOpacity(0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Color(0xFF1E40AF).withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              icon,
              style: TextStyle(
                fontSize: 18,
                color: isActive ? Color(0xFF1E40AF) : Colors.grey[600],
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? Color(0xFF1E40AF) : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
