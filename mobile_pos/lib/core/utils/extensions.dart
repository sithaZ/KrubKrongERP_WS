import 'package:flutter_screenutil/flutter_screenutil.dart';

/// App spacing constants using responsive sizing
class AppSpacing {
  AppSpacing._();

  static double get xs => 4.w;
  static double get sm => 8.w;
  static double get md => 16.w;
  static double get lg => 24.w;
  static double get xl => 32.w;
  static double get xxl => 48.w;

  static double get heightXs => 4.h;
  static double get heightSm => 8.h;
  static double get heightMd => 16.h;
  static double get heightLg => 24.h;
  static double get heightXl => 32.h;
  static double get heightXxl => 48.h;
}

/// App radius constants
class AppRadius {
  AppRadius._();

  static double get sm => 8.r;
  static double get md => 12.r;
  static double get lg => 16.r;
  static double get xl => 24.r;
  static double get xxl => 32.r;
  static double get circular => 999.r;
}

/// String extensions
extension StringExtension on String {
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Convert to title case
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Mask email for privacy (e.g., j***@example.com)
  String get maskEmail {
    if (isEmpty || !contains('@')) return this;
    final parts = split('@');
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return this;
    final masked = '${name.substring(0, 2)}${'*' * (name.length - 2)}@$domain';
    return masked;
  }

  /// Format phone number
  String get formatPhone {
    if (length != 10) return this;
    return '(${substring(0, 3)}) ${substring(3, 6)}-${substring(6)}';
  }
}

/// DateTime extensions
extension DateTimeExtension on DateTime {
  String get formattedDate {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[month - 1]} $day, $year';
  }

  String get formattedShortDate {
    return '$month/$day/$year';
  }

  String get formattedTime {
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final period = hour < 12 ? 'AM' : 'PM';
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hour12:$minuteStr $period';
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

/// Currency formatting
class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(double amount, {String symbol = '\$', int decimals = 2}) {
    final formatted = amount.toStringAsFixed(decimals);
    final parts = formatted.split('.');
    final whole = parts[0];
    final fraction = parts.length > 1 ? '.${parts[1]}' : '';
    
    final buffer = StringBuffer();
    var count = 0;
    for (var i = whole.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write(',');
      buffer.write(whole[i]);
      count++;
    }
    
    return '$symbol${buffer.toString().split('').reversed.join()}$fraction';
  }
}