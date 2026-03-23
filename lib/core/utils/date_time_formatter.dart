import 'package:intl/intl.dart';

class DateTimeFormatter {
  static final DateFormat _dateTime = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _date = DateFormat('dd/MM/yyyy');

  static String formatDateTime(DateTime dateTime) {
    return _dateTime.format(dateTime);
  }

  static String formatDate(DateTime date) {
    return _date.format(date);
  }
}
