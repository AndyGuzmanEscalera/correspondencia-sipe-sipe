import 'package:correspondencia_repository/correspondencia_repository.dart';

class SessionHeaderLabels {
  const SessionHeaderLabels({
    required this.primaryLine,
    required this.secondaryLine,
  });

  final String primaryLine;
  final String secondaryLine;

  static SessionHeaderLabels forSession(UserSession? session, {required bool compact}) {
    if (session == null) {
      return const SessionHeaderLabels(
        primaryLine: 'Usuario',
        secondaryLine: '',
      );
    }

    final context = session.institutionalContext;
    if (context != null) {
      final subtitle = compact ? context.mobileSubtitle : context.desktopSubtitle;
      return SessionHeaderLabels(
        primaryLine: context.employeeName,
        secondaryLine: subtitle ?? session.username,
      );
    }

    if (session.employeeId == null) {
      return SessionHeaderLabels(
        primaryLine: 'Administrador del sistema',
        secondaryLine: session.username,
      );
    }

    return SessionHeaderLabels(
      primaryLine: session.username,
      secondaryLine: session.username,
    );
  }
}
