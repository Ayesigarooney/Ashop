import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/utils/security_helper.dart';

class SettingsRepository {
  Box get _box => Hive.box(AppConstants.settingsBox);

  /// Notifies only when theme mode changes (avoids rebuilding entire app on every setting)
  final ValueNotifier<bool> themeNotifier = ValueNotifier(true);

  // PIN brute-force lockout keys (non-sensitive, kept in settings box)
  static const _pinAttemptsKey = 'sec_pin_attempts';
  static const _pinLockoutKey = 'sec_pin_lockout_until';
  static const _pinLengthKey = 'sec_pin_length';

  String get shopName => _box.get(AppConstants.shopNameKey, defaultValue: 'My Shop');
  set shopName(String v) => _box.put(AppConstants.shopNameKey, v);

  String get shopAddress => _box.get(AppConstants.shopAddressKey, defaultValue: '');
  set shopAddress(String v) => _box.put(AppConstants.shopAddressKey, v);

  String get shopPhone => _box.get(AppConstants.shopPhoneKey, defaultValue: '');
  set shopPhone(String v) => _box.put(AppConstants.shopPhoneKey, v);

  String? get shopLogo => _box.get(AppConstants.shopLogoKey);
  set shopLogo(String? v) => _box.put(AppConstants.shopLogoKey, v);

  String get currency => _box.get(AppConstants.currencyKey, defaultValue: AppConstants.defaultCurrency);
  set currency(String v) => _box.put(AppConstants.currencyKey, v);

  String get receiptHeader => _box.get(AppConstants.receiptHeaderKey, defaultValue: '');
  set receiptHeader(String v) => _box.put(AppConstants.receiptHeaderKey, v);

  String get receiptFooter => _box.get(AppConstants.receiptFooterKey, defaultValue: AppConstants.defaultReceiptFooter);
  set receiptFooter(String v) => _box.put(AppConstants.receiptFooterKey, v);

  bool get isDarkMode => _box.get(AppConstants.darkModeKey, defaultValue: true);
  set isDarkMode(bool v) {
    _box.put(AppConstants.darkModeKey, v);
    themeNotifier.value = v;
  }

  bool get isPinEnabled => _box.get(AppConstants.pinEnabledKey, defaultValue: false);
  set isPinEnabled(bool v) => _box.put(AppConstants.pinEnabledKey, v);

  /// Length of the configured PIN (used by the PIN screen to know when to verify)
  int get securedPinLength => _box.get(_pinLengthKey, defaultValue: 4);
  set securedPinLength(int v) => _box.put(_pinLengthKey, v);

  /// Store a hashed PIN (SHA-256 + random salt) in hardware-backed secure storage
  Future<void> setSecuredPin(String pin) async {
    await SecurityHelper.savePinCredentials(pin);
    _box.put(AppConstants.pinEnabledKey, true);
    _box.put(_pinLengthKey, pin.length);
    // Reset brute-force counters
    _box.put(_pinAttemptsKey, 0);
    _box.delete(_pinLockoutKey);
  }

  /// Verify a PIN against the stored salted hash in secure storage
  Future<bool> verifySecuredPin(String pin) async {
    return SecurityHelper.verifyStoredPin(pin);
  }

  /// Check if a secured PIN is configured
  Future<bool> hasSecuredPin() async {
    return SecurityHelper.hasStoredPin();
  }

  // ------ Brute-force lockout ------
  static const int maxPinAttempts = 5;
  static const Duration lockoutDuration = Duration(seconds: 30);

  /// Returns true if PIN entry is currently locked out
  bool isPinLockedOut() {
    final until = _box.get(_pinLockoutKey) as int?;
    if (until == null) return false;
    if (DateTime.now().millisecondsSinceEpoch >= until) {
      // Lockout expired, reset
      _box.put(_pinAttemptsKey, 0);
      _box.delete(_pinLockoutKey);
      return false;
    }
    return true;
  }

  /// Get remaining lockout duration in seconds
  int getPinLockoutRemaining() {
    final until = _box.get(_pinLockoutKey) as int?;
    if (until == null) return 0;
    final remaining = until - DateTime.now().millisecondsSinceEpoch;
    return (remaining / 1000).ceil().clamp(0, lockoutDuration.inSeconds);
  }

  /// Record a failed PIN attempt. Returns true if now locked out.
  bool recordFailedPinAttempt() {
    final attempts = (_box.get(_pinAttemptsKey) as int? ?? 0) + 1;
    _box.put(_pinAttemptsKey, attempts);
    if (attempts >= maxPinAttempts) {
      final lockoutUntil = DateTime.now().add(lockoutDuration).millisecondsSinceEpoch;
      _box.put(_pinLockoutKey, lockoutUntil);
      return true; // now locked out
    }
    return false;
  }

  /// Reset PIN attempts after successful entry
  void resetPinAttempts() {
    _box.put(_pinAttemptsKey, 0);
    _box.delete(_pinLockoutKey);
  }

  /// Remove stored PIN credentials and disable PIN
  Future<void> clearSecuredPin() async {
    await SecurityHelper.clearStoredPin();
    _box.delete(_pinLengthKey);
    _box.delete(_pinAttemptsKey);
    _box.delete(_pinLockoutKey);
    _box.put(AppConstants.pinEnabledKey, false);
  }

  int get lowStockThreshold => _box.get(AppConstants.lowStockThresholdKey, defaultValue: AppConstants.defaultLowStockThreshold);
  set lowStockThreshold(int v) => _box.put(AppConstants.lowStockThresholdKey, v);

  bool get taxEnabled => _box.get(AppConstants.taxEnabledKey, defaultValue: false);
  set taxEnabled(bool v) => _box.put(AppConstants.taxEnabledKey, v);

  double get taxRate => _box.get(AppConstants.taxRateKey, defaultValue: 0.18);
  set taxRate(double v) => _box.put(AppConstants.taxRateKey, v);

  bool get isFirstLaunch => _box.get('first_launch', defaultValue: true);
  set isFirstLaunch(bool v) => _box.put('first_launch', v);

  // Printer settings
  String get printerPaperSize => _box.get('printer_paper_size', defaultValue: '80mm');
  set printerPaperSize(String v) => _box.put('printer_paper_size', v);

  bool get printerShowLogo => _box.get('printer_show_logo', defaultValue: true);
  set printerShowLogo(bool v) => _box.put('printer_show_logo', v);

  bool get printerShowFooter => _box.get('printer_show_footer', defaultValue: true);
  set printerShowFooter(bool v) => _box.put('printer_show_footer', v);

  // Receipt template settings
  String get receiptTemplateStyle => _box.get('receipt_template_style', defaultValue: 'standard');
  set receiptTemplateStyle(String v) => _box.put('receipt_template_style', v);

  bool get enableEmailReceipts => _box.get('enable_email_receipts', defaultValue: false);
  set enableEmailReceipts(bool v) => _box.put('enable_email_receipts', v);

  // Scheduler settings
  String? get scheduledReportEmail => _box.get('scheduled_report_email');
  set scheduledReportEmail(String? v) => _box.put('scheduled_report_email', v);

  String? get scheduledReportFrequency => _box.get('scheduled_report_frequency');
  set scheduledReportFrequency(String? v) => _box.put('scheduled_report_frequency', v);
}
