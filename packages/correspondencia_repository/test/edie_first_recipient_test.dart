import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_repository/src/features/correspondence/mappers/correspondence_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mapper preserva el receptor y su único destino inicial',
      () {
    const input = CreateCorrespondenceInput(
      correspondenceType: 'EXTERNAL',
      documentTypeId: 'edie',
      priority: 'LOW',
      firstRecipientEmployeeId: 'secretary',
      initialToUnitId: 'receiver-unit',
      initialToUserId: 'receiver-user',
    );
    final json = input.toRequest().toJson();
    expect(json['first_recipient_employee_id'], 'secretary');
    expect(json['initial_to_unit_id'], 'receiver-unit');
    expect(json['initial_to_user_id'], 'receiver-user');
  });
}
