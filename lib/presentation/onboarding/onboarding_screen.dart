import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_theme.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../core/di/locator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final _pages = [
    _OnboardingPage(
      icon: Icons.point_of_sale_rounded,
      title: 'Smart Shop Management',
      description: 'Manage your shop inventory, process sales, and track business performance all in one place.',
      color: AppTheme.primaryColor,
    ),
    _OnboardingPage(
      icon: Icons.inventory_2_rounded,
      title: 'Track Inventory',
      description: 'Add products, manage stock levels, and get alerts when items run low.',
      color: AppTheme.accentColor,
    ),
    _OnboardingPage(
      icon: Icons.bar_chart_rounded,
      title: 'View Analytics',
      description: 'Monitor sales trends, profit margins, and make data-driven decisions for your business.',
      color: AppTheme.infoColor,
    ),
    _OnboardingPage(
      icon: Icons.receipt_long_rounded,
      title: 'Print Receipts & Invoices',
      description: 'Generate professional receipts and invoices. Export reports to CSV for your records.',
      color: AppTheme.successColor,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            if (_currentPage < _pages.length - 1)
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => _finish(),
                  child: const Text('Skip', style: TextStyle(color: Colors.white70)),
                ),
              ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: _pages.map((p) => _buildPage(p)).toList(),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i ? AppTheme.primaryColor : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    } else {
                      _finish();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Future<void> _finish() async {
    final settings = getIt<SettingsRepository>();
    settings.isFirstLaunch = false;
    final requiresPin = settings.isPinEnabled && await settings.hasSecuredPin();
    if (!mounted) return;
    if (requiresPin) {
      context.go('/pin');
    } else {
      context.go('/app');
    }
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 56, color: page.color),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.white.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  const _OnboardingPage({required this.icon, required this.title, required this.description, required this.color});
}
