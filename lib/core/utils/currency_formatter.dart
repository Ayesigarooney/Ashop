import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, {String currency = 'UGX'}) {
    final formatter = NumberFormat('#,##0', 'en_US');
    final formatted = formatter.format(amount);
    switch (currency) {
      case 'USD':
        return '\$$formatted';
      case 'EUR':
        return '€$formatted';
      case 'GBP':
        return '£$formatted';
      case 'NGN':
        return '₦$formatted';
      case 'GHS':
        return 'GH₵$formatted';
      default:
        return '$currency $formatted';
    }
  }

  static String formatCompact(double amount, {String currency = 'UGX'}) {
    if (amount >= 1000000) {
      return '$currency ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '$currency ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return format(amount, currency: currency);
  }
}
