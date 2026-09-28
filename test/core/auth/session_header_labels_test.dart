import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/auth/session_header_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const institutional = InstitutionalContext(
    employeeId: 'e-1',
    employeeName: 'María López',
    positionName: 'Secretaria de Secretaría Técnica',
    unitName: 'Secretaría Técnica',
  );

  test('desktop labels use cargo · unidad', () {
    const session = UserSession(
      id: 'u-1',
      username: 'mlopez',
      isActive: true,
      institutionalContext: institutional,
    );

    final labels = SessionHeaderLabels.forSession(session, compact: false);

    expect(labels.primaryLine, 'María López');
    expect(labels.secondaryLine,
        'Secretaria de Secretaría Técnica · Secretaría Técnica');
  });

  test('mobile labels prefer unit name', () {
    const session = UserSession(
      id: 'u-1',
      username: 'mlopez',
      isActive: true,
      institutionalContext: institutional,
    );

    final labels = SessionHeaderLabels.forSession(session, compact: true);

    expect(labels.primaryLine, 'María López');
    expect(labels.secondaryLine, 'Secretaría Técnica');
  });

  test('admin without employee shows system administrator', () {
    const session = UserSession(
      id: 'admin-id',
      username: 'admin',
      isActive: true,
    );

    final labels = SessionHeaderLabels.forSession(session, compact: false);

    expect(labels.primaryLine, 'Administrador del sistema');
    expect(labels.secondaryLine, 'admin');
  });
}
