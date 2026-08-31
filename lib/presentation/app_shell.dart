import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/config/app_theme.dart';
import 'home/home_screen.dart';
import 'pos/pos_screen.dart';
import 'products/products_screen.dart';
import 'analytics/analytics_screen.dart';
import 'notes/notes_screen.dart';
import 'settings/settings_screen.dart';

class AppShell extends StatefulWidget {
  final int initialIndex;
  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => AppShellState();

  static AppShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<AppShellState>();
}

class AppShellState extends State<AppShell> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void navigateTo(int index) {
    setState(() => _selectedIndex = index);
  }

  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.home_rounded,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.point_of_sale_outlined,
      activeIcon: Icons.point_of_sale_rounded,
      label: 'POS',
    ),
    _NavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
      label: 'Products',
    ),
    _NavItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: 'Reports',
    ),
    _NavItem(
      icon: Icons.note_alt_outlined,
      activeIcon: Icons.note_alt_rounded,
      label: 'Notes',
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;

    if (isTablet) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              labelType: NavigationRailLabelType.all,
              backgroundColor: isDark
                  ? AppTheme.darkSurface
                  : AppTheme.lightSurface,
              selectedIconTheme: const IconThemeData(
                color: AppTheme.primaryColor,
              ),
              unselectedIconTheme: IconThemeData(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              selectedLabelTextStyle: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
              unselectedLabelTextStyle: GoogleFonts.inter(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              destinations: _navItems
                  .map(
                    (item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.activeIcon),
                      label: Text(item.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: const [
                  HomeScreen(),
                  PosScreen(),
                  ProductsScreen(),
                  AnalyticsScreen(),
                  NotesScreen(),
                  SettingsScreen(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HomeScreen(),
          PosScreen(),
          ProductsScreen(),
          AnalyticsScreen(),
          NotesScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(_navItems.length, (index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;
                final isPOS = index == 1;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIndex = index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isPOS)
                            Container(
                              width: 44,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? AppTheme.primaryGradient
                                    : LinearGradient(
                                        colors: [
                                          AppTheme.primaryColor.withValues(
                                            alpha: 0.7,
                                          ),
                                          AppTheme.primaryLight.withValues(
                                            alpha: 0.7,
                                          ),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.45),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                isSelected ? item.activeIcon : item.icon,
                                color: Colors.white,
                                size: 18,
                              ),
                            )
                          else
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isSelected ? 36 : 26,
                              height: 26,
                              decoration: isSelected
                                  ? BoxDecoration(
                                      color: AppTheme.primaryColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    )
                                  : null,
                              child: Icon(
                                isSelected ? item.activeIcon : item.icon,
                                size: 19,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.4,
                                      ),
                              ),
                            ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : theme.colorScheme.onSurface.withValues(
                                      alpha: 0.4,
                                    ),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
