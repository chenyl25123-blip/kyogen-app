import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kyogen/theme/app_theme.dart';
import 'home_screen.dart';
import 'contact_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    ContactScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(
                icon:  Icons.shield_outlined,
                activeIcon: Icons.shield,
                label: '元気',
                index: 0,
                currentIndex: _currentIndex,
                onTap: _onTap,
              ),
              _NavItem(
                icon:  Icons.person_outline,
                activeIcon: Icons.person,
                label: '連絡先',
                index: 1,
                currentIndex: _currentIndex,
                onTap: _onTap,
              ),
              _NavItem(
                icon:  Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: '設定',
                index: 2,
                currentIndex: _currentIndex,
                onTap: _onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                size: 22,
                color: isActive ? AppColors.teal : AppColors.text3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                color: isActive ? AppColors.teal : AppColors.text3,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
