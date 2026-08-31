import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/config/app_theme.dart';
import '../../core/config/constants.dart';
import '../../features/settings/data/settings_repository.dart';

class PinScreen extends StatefulWidget {
  final SettingsRepository settings;
  const PinScreen({super.key, required this.settings});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen>
    with SingleTickerProviderStateMixin {
  String _entered = '';
  bool _error = false;
  String _errorMsg = '';
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  Timer? _lockoutTimer;
  int _lockoutRemaining = 0;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
    _checkLockoutOnInit();
  }

  void _checkLockoutOnInit() {
    if (widget.settings.isPinLockedOut()) {
      _startLockoutTimer();
    }
  }

  void _startLockoutTimer() {
    _lockoutRemaining = widget.settings.getPinLockoutRemaining();
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _lockoutRemaining = widget.settings.getPinLockoutRemaining();
      });
      if (_lockoutRemaining <= 0) {
        _lockoutTimer?.cancel();
        _lockoutTimer = null;
      }
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onKey(String digit) {
    if (_entered.length >= 6) return;
    if (widget.settings.isPinLockedOut()) return;
    setState(() {
      _entered += digit;
      _error = false;
      _errorMsg = '';
    });
    // Auto-verify once the entered PIN matches the configured length,
    // so 5/6-digit PINs are never rejected at 4 digits.
    if (_entered.length >= widget.settings.securedPinLength) {
      _verify();
    }
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _verify() async {
    if (_entered.isEmpty || widget.settings.isPinLockedOut()) return;

    final valid = await widget.settings.verifySecuredPin(_entered);
    if (!mounted) return;
    if (valid) {
      widget.settings.resetPinAttempts();
      context.go('/app');
    } else {
      final lockedOut = widget.settings.recordFailedPinAttempt();
      setState(() {
        _error = true;
        _entered = '';
        if (lockedOut) {
          final remaining = widget.settings.getPinLockoutRemaining();
          _errorMsg = 'Too many attempts. Locked for ${remaining}s';
          _startLockoutTimer();
        } else {
          _errorMsg = 'Incorrect PIN. Try again.';
        }
      });
      _shakeCtrl.forward().then((_) => _shakeCtrl.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 680;
    final lockedOut = widget.settings.isPinLockedOut();

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: 32,
            vertical: isSmall ? 16 : 32,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: size.height - 100),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                SizedBox(height: isSmall ? 16 : 24),
                Text(
                  AppConstants.appName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lockedOut
                      ? 'Too many attempts'
                      : 'Enter your PIN to continue',
                  style: GoogleFonts.inter(
                    color: lockedOut
                        ? AppTheme.dangerColor
                        : Colors.white.withValues(alpha: 0.55),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: isSmall ? 28 : 40),

                // PIN Dots
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(
                      _error
                          ? _shakeAnim.value *
                                (_entered.length % 2 == 0 ? 1 : -1)
                          : 0,
                      0,
                    ),
                    child: child,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (i) {
                      final filled = i < _entered.length && !lockedOut;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _error
                              ? AppTheme.dangerColor
                              : filled
                              ? AppTheme.primaryColor
                              : Colors.white.withValues(alpha: 0.15),
                          border: Border.all(
                            color: _error
                                ? AppTheme.dangerColor
                                : AppTheme.primaryColor,
                            width: 1.5,
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                if (_error && _errorMsg.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorMsg,
                    style: GoogleFonts.inter(
                      color: AppTheme.dangerColor,
                      fontSize: 13,
                    ),
                  ),
                ],

                if (lockedOut && _lockoutRemaining > 0) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Locked for $_lockoutRemaining s',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.dangerColor,
                    ),
                  ),
                ],

                SizedBox(height: isSmall ? 32 : 48),

                // Numpad (disabled during lockout)
                IgnorePointer(
                  ignoring: lockedOut,
                  child: Opacity(
                    opacity: lockedOut ? 0.4 : 1.0,
                    child: SizedBox(
                      width: 260,
                      child: GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.2,
                        children:
                            [
                                  '1',
                                  '2',
                                  '3',
                                  '4',
                                  '5',
                                  '6',
                                  '7',
                                  '8',
                                  '9',
                                  '',
                                  '0',
                                  '⌫',
                                ]
                                .map(
                                  (k) => k.isEmpty
                                      ? const SizedBox.shrink()
                                      : GestureDetector(
                                          onTap: () => k == '⌫'
                                              ? _onBackspace()
                                              : _onKey(k),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.07,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: Colors.white.withValues(
                                                  alpha: 0.08,
                                                ),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                k,
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                      fontSize: k == '⌫'
                                                          ? 18
                                                          : 22,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                )
                                .toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
