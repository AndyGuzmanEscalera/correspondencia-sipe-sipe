import 'package:intl/intl.dart';

/// Presentation only: DB/API instants remain UTC. America/La_Paz is UTC-04:00.
/// Always format the original instant; never store the shifted wall-clock value.
String institutionalDate(DateTime date,
        {String pattern = 'dd/MM/yyyy HH:mm'}) =>
    DateFormat(pattern).format(date.toUtc().subtract(const Duration(hours: 4)));
