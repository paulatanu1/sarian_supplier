import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension ContextX on BuildContext {
  ThemeData  get theme       => Theme.of(this);
  TextTheme  get textTheme   => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  double get screenWidth  => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  void showSnack(String msg, {bool isError = false}) =>
      ScaffoldMessenger.of(this).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
}

extension DateTimeX on DateTime {
  String get display      => DateFormat('dd MMM yyyy').format(this);
  String get displayTime  => DateFormat('dd MMM yyyy, hh:mm a').format(this);
  String get monthYear    => DateFormat('MMM yyyy').format(this);

  String get timeAgo {
    final d = DateTime.now().difference(this);
    if (d.inMinutes < 1)  return 'Just now';
    if (d.inHours   < 1)  return '${d.inMinutes}m ago';
    if (d.inDays    < 1)  return '${d.inHours}h ago';
    if (d.inDays    < 30) return '${d.inDays}d ago';
    return display;
  }

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isThisWeek {
    final now = DateTime.now();
    return now.difference(this).inDays < 7;
  }

  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }
}

extension StringX on String {
  String get capitalised  => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  String get titleCase    => split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  bool   get isValidEmail => RegExp(r'^[\w._%+-]+@[\w.-]+\.[a-zA-Z]{2,}$').hasMatch(this);
  bool   get isValidPhone => RegExp(r'^[6-9]\d{9}$').hasMatch(trim());
  bool   get isValidPassword => length >= 6;
}

extension NumX on num {
  String get inr => '₹${NumberFormat('#,##,###.##').format(this)}';
  String get compact {
    if (this >= 10000000) return '${(this / 10000000).toStringAsFixed(1)}Cr';
    if (this >= 100000)   return '${(this / 100000).toStringAsFixed(1)}L';
    if (this >= 1000)     return '${(this / 1000).toStringAsFixed(1)}K';
    return toString();
  }
}

extension ListX<T> on List<T> {
  List<List<T>> chunked(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }
}
