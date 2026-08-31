import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_theme.dart';
import '../../core/config/constants.dart';
import '../../core/di/locator.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../main.dart' as app;

class SplashScreen extends StatefulWidget {
  /// true = shown before Hive is ready (no go_router context)
  final bool simple;
  const SplashScreen({super.key, this.simple = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _scaleAnim = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    if (!widget.simple) _initialize();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await app.appReady;
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final settings = getIt<SettingsRepository>();
    if (settings.isFirstLaunch) {
      context.go('/onboarding');
    } else if (settings.isPinEnabled && await settings.hasSecuredPin()) {
      if (!mounted) return;
      context.go('/pin');
    } else {
      context.go('/app');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.5),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.point_of_sale_rounded,
                        color: Colors.white,
                        size: 52,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    AppConstants.appName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppConstants.appTagline,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.55),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 80),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.primaryColor.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Developed by ${AppConstants.developerName}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.25),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
