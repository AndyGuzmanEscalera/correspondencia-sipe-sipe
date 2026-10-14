import 'package:intl/intl.dart';

String institutionalDate(DateTime date) => DateFormat('dd/MM/yyyy HH:mm')
    .format(date.toUtc().subtract(const Duration(hours: 4)));
