class ValidationHelper {
  /// Strip HTML tags and trim whitespace to prevent XSS / injection
  static String sanitize(String value) {
    return value.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) return 'Price is required';
    final v = double.tryParse(sanitize(value));
    if (v == null || v < 0) return 'Enter a valid price';
    return null;
  }

  static String? quantity(String? value) {
    if (value == null || value.trim().isEmpty) return 'Quantity is required';
    final v = int.tryParse(sanitize(value));
    if (v == null || v < 0) return 'Enter a valid quantity';
    return null;
  }

  static String? positiveNumber(String? value, [String field = 'Value']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    final v = double.tryParse(sanitize(value));
    if (v == null || v <= 0) return '$field must be greater than 0';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final phoneRegex = RegExp(r'^\+?[\d\s-]{7,15}$');
    if (!phoneRegex.hasMatch(value.trim())) return 'Enter a valid phone number';
    return null;
  }

  static String? barcode(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length < 4) return 'Barcode too short';
    return null;
  }
}
