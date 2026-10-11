import 'package:intl/intl.dart';
/// Formats a DateTime like "11 Oct 2026, 10:53".
String formatDate(DateTime date) {
  final localDate = date.toLocal();
  return DateFormat('d MMM yyyy, HH:mm').format(localDate);
}
