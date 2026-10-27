import 'package:correspondencia_api/correspondencia_api.dart' as api;
import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_repository/src/features/authentication/mappers/user_response_mapper.dart';
import 'package:correspondencia_repository/src/features/correspondence/mappers/correspondence_mapper.dart';
import 'package:correspondencia_repository/src/features/correspondence/mappers/document_type_admin_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog mapper preserves profile and creation policy metadata', () {
    const dto = api.DocumentTypeResponse(
        id: 'c',
        code: 'CIRCULAR',
        name: 'Circular',
        profile: 'CIRCULAR',
        isOperational: true,
        creationPermission: 'correspondence.create.circular',
        minimumHierarchyId: 'h');
    final type = dto.toEntity();
    expect(type.profile, 'CIRCULAR');
    expect(type.minimumHierarchyId, 'h');
    expect(type.isOperational, isTrue);
  });
  test('session hierarchy is available from auth me', () {
    final user = api.UserResponse.fromJson({
      'id': 'u',
      'username': 'u',
      'employee': {
        'id': 'e',
        'full_name': 'Actor',
        'position': {
          'id': 'p',
          'name': 'Cargo',
          'hierarchy': {
            'id': 'h',
            'code': 'DIRECTOR',
            'name': 'Director',
            'rank': 4,
            'is_active': true
          }
        }
      }
    });
    final session = user.toEntity();
    expect(session.institutionalContext!.hierarchyRank, 4);
    expect(session.institutionalContext!.hierarchyCode, 'DIRECTOR');
    expect(session.institutionalContext!.hierarchyIsActive, isTrue);
  });
  test('detail PDF availability and old defaults map safely', () {
    final data = {
      'id': 'c',
      'route_number': 'HR',
      'route_year': 2026,
      'route_sequence': 1,
      'correspondence_type': 'INTERNAL',
      'document_type_code': 'INFORME',
      'document_type_name': 'Informe',
      'subject': 'Contenido',
      'priority': 'LOW',
      'status': 'ACTIVE',
      'registered_at': '2026-10-26T00:00:00Z'
    };
    expect(api.CorrespondenceResponse.fromJson(data).toEntity().hasDocumentPdf,
        isFalse);
    expect(
        api.CorrespondenceResponse.fromJson({...data, 'has_document_pdf': true})
            .toEntity()
            .hasDocumentPdf,
        isTrue);
  });
  test('admin mapper preserves protected fields', () {
    final dto = api.DocumentTypeAdminResponse(
        id: 'm',
        code: 'MEMORANDUM',
        name: 'Memo',
        isActive: true,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        profile: 'MEMORANDUM',
        isOperational: true,
        minimumHierarchyId: 'h',
        minimumHierarchyName: 'Jefe');
    final type = dto.toEntity();
    expect(type.minimumHierarchyName, 'Jefe');
    expect(type.isOperational, isTrue);
  });
}
