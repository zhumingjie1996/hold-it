import 'package:flutter/material.dart';

class AppColors {
  static const Color brand = Color(0xFF6AD86C);
  static const Color brandDark = Color(0xFF1F6B2A);
  static const Color green = Colors.green;
  static const Color background = Color(0xFFF2F2F7);
  static const Color cardBackground = Colors.white;
  static const Color secondaryText = Colors.grey;
}

enum SupportedCurrency {
  auto('auto', '跟随系统', ''),
  cny('CNY', '人民币 (¥)', '¥'),
  usd('USD', '美元 (\$)', '\$'),
  eur('EUR', '欧元 (€)', '€'),
  jpy('JPY', '日元 (¥)', '¥'),
  gbp('GBP', '英镑 (£)', '£'),
  hkd('HKD', '港元 (HK\$)', 'HK\$'),
  twd('TWD', '台币 (NT\$)', 'NT\$'),
  krw('KRW', '韩元 (₩)', '₩');

  final String code;
  final String displayName;
  final String symbol;

  const SupportedCurrency(this.code, this.displayName, this.symbol);

  static String get systemSymbol {
    return '¥';
  }

  static SupportedCurrency fromCode(String code) {
    return values.firstWhere(
      (c) => c.code == code,
      orElse: () => auto,
    );
  }
}

enum ThemeModeOption {
  system(0, '跟随系统', Icons.brightness_auto),
  light(1, '浅色', Icons.wb_sunny),
  dark(2, '深色', Icons.nights_stay);

  final int value;
  final String label;
  final IconData icon;

  const ThemeModeOption(this.value, this.label, this.icon);

  static ThemeModeOption fromValue(int value) {
    return values.firstWhere(
      (m) => m.value == value,
      orElse: () => system,
    );
  }
}

String formatAmount(double amount) {
  if (amount == amount.toInt()) {
    return amount.toInt().toString();
  }
  return amount.toStringAsFixed(1);
}

String relativeTimeString(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inSeconds < 60) return '刚刚';
  if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
  if (diff.inHours < 24) return '${diff.inHours}小时前';
  if (diff.inDays < 7) return '${diff.inDays}天前';
  return '${date.month}月${date.day}日';
}

String timeString(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
