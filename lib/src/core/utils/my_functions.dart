class MyFunctions {
  static String formatPhoneNumber(String phone) {
    if (phone.startsWith('998') && phone.length == 12) {
      return '+$phone';
    } else if (phone.startsWith('0') && phone.length == 9) {
      return '+998${phone.substring(1)}';
    } else if (phone.startsWith('+998') && phone.length == 13) {
      return phone;
    } else {
      return phone; // Return as is if it doesn't match expected formats
    }
  }

  static String formatDateTime(String dateTimeStr, {String format = 'dd.MM.yyyy, HH:mm'}) {
    try {
      final dateTime = DateTime.parse(dateTimeStr).toLocal();
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year.toString();
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');

      return format
          .replaceAll('dd', day)
          .replaceAll('MM', month)
          .replaceAll('yyyy', year)
          .replaceAll('HH', hour)
          .replaceAll('mm', minute);
    } catch (e) {
      return dateTimeStr; // Return original string if parsing fails
    }
  }

  static String formatDuration(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Sana stringini "dd.MM.yyyy (N days ago)" ko'rinishida qaytaradi.
  /// "today" / "yesterday" uchun maxsus shakl. Parse xatolik bersa
  /// - original stringni qaytaradi.
  static String formatDateWithRelative(String dateTimeStr) {
    try {
      final dt = DateTime.parse(dateTimeStr).toLocal();
      final today = DateTime.now();
      final base = '${dt.day.toString().padLeft(2, '0')}.'
          '${dt.month.toString().padLeft(2, '0')}.${dt.year}';
      final days = DateTime(today.year, today.month, today.day)
          .difference(DateTime(dt.year, dt.month, dt.day))
          .inDays;
      String relative;
      if (days < 0) {
        relative = base; // future date - fallback to plain date
        return relative;
      } else if (days == 0) {
        relative = 'today';
      } else if (days == 1) {
        relative = 'yesterday';
      } else {
        relative = '$days days ago';
      }
      return '$base ($relative)';
    } catch (_) {
      return dateTimeStr;
    }
  }

  /// "N days ago" / "today" / "yesterday" - sof relative format.
  static String relativeDate(String dateTimeStr) {
    try {
      final dt = DateTime.parse(dateTimeStr).toLocal();
      final today = DateTime.now();
      final days = DateTime(today.year, today.month, today.day)
          .difference(DateTime(dt.year, dt.month, dt.day))
          .inDays;
      if (days == 0) return 'today';
      if (days == 1) return 'yesterday';
      if (days < 0) return formatDateTime(dateTimeStr, format: 'dd.MM.yyyy');
      return '$days days ago';
    } catch (_) {
      return dateTimeStr;
    }
  }
}
