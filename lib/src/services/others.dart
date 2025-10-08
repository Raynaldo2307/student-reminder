import 'package:intl/intl.dart';

String formatDate(DateTime date) {
  final formatter = DateFormat('EEEE, MMM d');
  return formatter.format(date);
}
