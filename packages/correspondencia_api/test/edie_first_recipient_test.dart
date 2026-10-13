import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EDIE serializa receptor único con destino inicial consistente', () {
    const request = CreateCorrespondenceRequest(
      correspondenceType: 'EXTERNAL',
      documentTypeId: 'edie',
      priority: 'LOW',
      firstRecipientEmployeeId: 'secretary-employee',
      initialToUnitId: 'receiver-unit',
      initialToUserId: 'receiver-user',
    );
    expect(
        request.toJson()['first_recipient_employee_id'], 'secretary-employee');
    expect(request.toJson()['initial_to_user_id'], 'receiver-user');
    expect(request.toJson().containsKey('mayor_employee_id'), isFalse);
  });
  test('otros perfiles omiten primer destinatario', () {
    const request = CreateCorrespondenceRequest(
      correspondenceType: 'EXTERNAL',
      documentTypeId: 'letter',
      priority: 'LOW',
      initialToUnitId: 'unit',
    );
    expect(
        request.toJson().containsKey('first_recipient_employee_id'), isFalse);
  });
}
