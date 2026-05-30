import 'package:intl/intl.dart';

class Formatters {
  static String currency(int amount) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  static String distance(double km) {
    return '${km.toStringAsFixed(0)} km';
  }

  static String duration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0 && mins > 0) return '${hours}j ${mins}m';
    if (hours > 0) return '${hours}j';
    return '${mins}m';
  }

  static String date(DateTime dt) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(dt);
  }

  static String time(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }

  static String dateTime(DateTime dt) {
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
  }

  static String dayName(DateTime dt) {
    return DateFormat('EEEE', 'id_ID').format(dt);
  }
}
