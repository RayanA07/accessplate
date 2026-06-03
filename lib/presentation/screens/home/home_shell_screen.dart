import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../profile/settings_screen.dart';
import '../recommendations/recommendations_screen.dart';
import 'logged_meals_screen.dart';
import 'macro_targets_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

enum _HomeTab { meals, logged, targets, profile }

class _HomeShellScreenState extends State<HomeShellScreen> {
  _HomeTab _selectedTab = _HomeTab.meals;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedTab.index,
        children: [
          RecommendationsScreen(
            embedded: true,
            onOpenProfile: () => _selectTab(_HomeTab.profile),
          ),
          const LoggedMealsScreen(),
          const MacroTargetsScreen(),
          const SettingsScreen(embedded: true),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        child: _BottomTabBar(selectedTab: _selectedTab, onSelected: _selectTab),
      ),
    );
  }

  void _selectTab(_HomeTab tab) {
    if (_selectedTab == tab) {
      return;
    }
    setState(() {
      _selectedTab = tab;
    });
  }
}

class _BottomTabBar extends StatelessWidget {
  const _BottomTabBar({required this.selectedTab, required this.onSelected});

  final _HomeTab selectedTab;
  final ValueChanged<_HomeTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1C16161C),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _TabButton(
              semanticLabel: 'Meals',
              icon: Icons.home_rounded,
              selected: selectedTab == _HomeTab.meals,
              onTap: () => onSelected(_HomeTab.meals),
            ),
            _TabButton(
              semanticLabel: 'Logged',
              icon: Icons.receipt_long_rounded,
              selected: selectedTab == _HomeTab.logged,
              onTap: () => onSelected(_HomeTab.logged),
            ),
            _TabButton(
              semanticLabel: 'Targets',
              icon: Icons.stars_rounded,
              selected: selectedTab == _HomeTab.targets,
              onTap: () => onSelected(_HomeTab.targets),
            ),
            _TabButton(
              semanticLabel: 'Profile',
              icon: Icons.person_outline_rounded,
              selected: selectedTab == _HomeTab.profile,
              onTap: () => onSelected(_HomeTab.profile),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.semanticLabel,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String semanticLabel;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? Colors.white : const Color(0xFF8E8D95);
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: selected ? NihPalette.success : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
      ),
    );
  }
}
