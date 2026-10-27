import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> document() => {
      'id': 'c',
      'route_number': 'HR',
      'route_year': 2026,
      'route_sequence': 1,
      'correspondence_type': 'INTERNAL',
      'document_type_code': 'CIRCULAR',
      'document_type_name': 'Circular',
      'subject': 'Contenido',
      'priority': 'LOW',
      'status': 'ACTIVE',
      'registered_at': '2026-10-26T00:00:00Z'
    };
void main() {
  test('absent capabilities default to denied even when ownership is true', () {
    final dto =
        CorrespondenceResponse.fromJson({...document(), 'can_operate': true});
    expect(dto.canOperate, isTrue);
    expect(dto.canConclude, isFalse);
    expect(dto.canReopen, isFalse);
    expect(dto.canManageAttachments, isFalse);
  });
  test('distinct backend mutation capabilities are transported unchanged', () {
    final dto = CorrespondenceResponse.fromJson({
      ...document(),
      'can_operate': true,
      'can_derive': true,
      'can_conclude': false,
      'can_reopen': true,
      'can_manage_attachments': false
    });
    expect(dto.canDerive, isTrue);
    expect(dto.canConclude, isFalse);
    expect(dto.canReopen, isTrue);
    expect(dto.canManageAttachments, isFalse);
  });
}
