import 'package:correspondencia_api/correspondencia_api.dart' as api;
import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_repository/src/features/correspondence/mappers/correspondence_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('capability mapper does not infer permissions from canOperate', () {
    final dto = api.CorrespondenceResponse(
        id: 'c',
        routeNumber: 'HR',
        routeYear: 2026,
        routeSequence: 1,
        correspondenceType: 'INTERNAL',
        documentTypeCode: 'CIRCULAR',
        documentTypeName: 'Circular',
        subject: 'Contenido',
        priority: 'LOW',
        status: 'ACTIVE',
        registeredAt: DateTime.utc(2026),
        canOperate: true,
        canConclude: false,
        canReopen: true,
        canManageAttachments: false);
    final value = dto.toEntity();
    expect(value.canOperate, isTrue);
    expect(value.canConclude, isFalse);
    expect(value.canReopen, isTrue);
    expect(value.canManageAttachments, isFalse);
  });
  test('permission catalog groups read create and operations independently',
      () {
    const examples = {
      'correspondence.read.all': 'Correspondencia - Lectura',
      'correspondence.create.circular': 'Correspondencia - Creación',
      'correspondence.derive': 'Correspondencia - Operación',
      'correspondence.attachments.manage': 'Correspondencia - Operación',
      'reports.view': 'Reportes',
      'master_data.roles.assign': 'Administración',
      'system.settings.manage': 'Configuración'
    };
    for (final item in examples.entries) {
      expect(
          PermissionOption(id: item.key, code: item.key).category, item.value);
    }
  });
}
