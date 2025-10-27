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
}
