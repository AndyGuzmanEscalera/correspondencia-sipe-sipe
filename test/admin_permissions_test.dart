import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('hasPermission', () {
    const session = UserSession(
      id: 'user-1',
      username: 'admin',
      isActive: true,
      permissions: [
        Permissions.employeesRead,
        Permissions.documentTypesManage,
      ],
    );

    test('returns true when permission is present', () {
      expect(hasPermission(session, Permissions.employeesRead), isTrue);
      expect(hasPermission(session, Permissions.documentTypesManage), isTrue);
    });

    test('returns false when permission is missing', () {
      expect(hasPermission(session, Permissions.usersRead), isFalse);
    });

    test('returns false for null session', () {
      expect(hasPermission(null, Permissions.employeesRead), isFalse);
    });
  });
}
