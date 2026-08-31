class AppConstants {
  static const String appName = 'Ashop';
  static const String appTagline = 'Smart Shop Manager';
  static const String developerName = 'Aaron Codes and Computing Services';
  static const String developerPhone = '+256766088271';
  static const String appVersion = '1.0.0';

  // Hive Box Names
  static const String productsBox = 'products';
  static const String salesBox = 'sales';
  static const String settingsBox = 'settings';
  static const String notesBox = 'business_notes';

  // Settings Keys
  static const String shopNameKey = 'shop_name';
  static const String shopAddressKey = 'shop_address';
  static const String shopPhoneKey = 'shop_phone';
  static const String shopLogoKey = 'shop_logo';
  static const String currencyKey = 'currency';
  static const String receiptHeaderKey = 'receipt_header';
  static const String receiptFooterKey = 'receipt_footer';
  static const String darkModeKey = 'dark_mode';
  static const String pinEnabledKey = 'pin_enabled';
  static const String lowStockThresholdKey = 'low_stock_threshold';
  static const String receiptCounterKey = 'receipt_counter';
  static const String taxRateKey = 'tax_rate';
  static const String taxEnabledKey = 'tax_enabled';

  // Default Values
  static const String defaultCurrency = 'UGX';
  static const int defaultLowStockThreshold = 5;
  static const double defaultTaxRate = 0.18;
  static const String defaultReceiptFooter = 'Thank you for your business!';

  // Supported Currencies
  static const List<Map<String, String>> currencies = [
    {'code': 'UGX', 'name': 'Ugandan Shilling', 'symbol': 'UGX'},
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
    {'code': 'KES', 'name': 'Kenyan Shilling', 'symbol': 'KES'},
    {'code': 'TZS', 'name': 'Tanzanian Shilling', 'symbol': 'TZS'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
    {'code': 'RWF', 'name': 'Rwandan Franc', 'symbol': 'RWF'},
    {'code': 'NGN', 'name': 'Nigerian Naira', 'symbol': '₦'},
    {'code': 'GHS', 'name': 'Ghanaian Cedi', 'symbol': 'GH₵'},
  ];
}
