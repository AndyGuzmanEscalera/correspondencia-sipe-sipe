import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:flutter_test/flutter_test.dart';

class Http extends Fake implements ApiMethod {
  String? path;
  @override
  Future<List<Map<String, dynamic>>> getList(String path,
      {Map<String, dynamic>? queryParameters, String? operation}) async {
    this.path = path;
    return [
      {
        'id': 'm',
        'code': 'MEMORANDUM',
        'name': 'Memorándum',
        'profile': 'MEMORANDUM',
        'is_operational': true,
        'creation_permission': 'correspondence.create.memorandum',
        'minimum_hierarchy_id': 'jefe'
      }
    ];
  }

  @override
  Future<List<int>> downloadBytes(
      {required String path,
      Map<String, dynamic>? queryParameters,
      String? operation}) async {
    this.path = path;
    return [37, 80, 68, 70];
  }
}

void main() {
  test(
      'creation catalog requests backend-filtered route and structural metadata',
      () async {
    final http = Http();
    final api = CorrespondenceApi(mainApi: http);
    final types = await api.listDocumentTypes();
    expect(http.path, '/document-types/available-for-create');
    expect(types.single.profile, 'MEMORANDUM');
    expect(types.single.isOperational, isTrue);
    expect(types.single.creationPermission, 'correspondence.create.memorandum');
    expect(types.single.minimumHierarchyId, 'jefe');
  });
  test('new PDF and legacy PDF have distinct endpoints', () async {
    final http = Http();
    final api = CorrespondenceApi(mainApi: http);
    await api.downloadDocumentPdf('doc');
    expect(http.path, '/correspondences/doc/document.pdf');
    await api.downloadChainingPdf('doc');
    expect(http.path, '/correspondences/doc/encadenamiento.pdf');
  });
  test('auth me transports hierarchy without additional lookup', () {
    final user = UserResponse.fromJson({
      'id': 'u',
      'username': 'u',
      'is_active': true,
      'employee': {
        'id': 'e',
        'full_name': 'Funcionario',
        'position': {
          'id': 'p',
          'name': 'Cargo',
          'hierarchy': {
            'id': 'h',
            'code': 'JEFE',
            'name': 'Jefe',
            'rank': 3,
            'is_active': true
          }
        }
      }
    });
    expect(user.employee!.position!.hierarchy!.rank, 3);
    expect(user.employee!.position!.hierarchy!.code, 'JEFE');
  });
  test('admin DTO preserves protected minimum hierarchy description', () {
    final row = DocumentTypeAdminResponse.fromJson({
      'id': 'm',
      'code': 'MEMORANDUM',
      'name': 'Memo',
      'created_at': '2026-10-26T00:00:00Z',
      'updated_at': '2026-10-26T00:00:00Z',
      'profile': 'MEMORANDUM',
      'is_operational': true,
      'minimum_hierarchy_id': 'h',
      'minimum_hierarchy_name': 'Jefe',
      'creation_permission': 'correspondence.create.memorandum'
    });
    expect(row.minimumHierarchyName, 'Jefe');
    expect(const UpdateDocumentTypeRequest(name: 'Nombre visible').toJson(),
        {'name': 'Nombre visible'});
  });
}
