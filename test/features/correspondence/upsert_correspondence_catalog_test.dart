import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/document_type_profiles.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/cubit/upsert_correspondence_cubit.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCorrespondenceRepository implements repo.CorrespondenceRepository {
  _FakeCorrespondenceRepository({this.employees = const []});

  final List<repo.EmployeeOption> employees;

  @override
  Future<Result<List<repo.DocumentType>, Failure>> listDocumentTypes() async {
    return Ok([
      repo.DocumentType(id: 'dt-edie', code: 'EDIE', name: 'Encadenamiento'),
      repo.DocumentType(id: 'dt-informe', code: 'INFORME', name: 'Informe Técnico'),
      repo.DocumentType(id: 'dt-nota', code: 'NOTA', name: 'Nota Interna'),
    ]);
  }

  @override
  Future<Result<List<repo.EmployeeOption>, Failure>> listEmployees() async {
    return Ok(employees);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOrganizationRepository implements repo.OrganizationRepository {
  @override
  Future<Result<List<repo.OrganizationalUnit>, Failure>>
      listActiveUnits() async {
    return Ok([
      repo.OrganizationalUnit(id: 'unit-1', code: 'SYS', name: 'Sistemas'),
    ]);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

UpsertCorrespondenceState _loadedState({List<repo.EmployeeOption> employees = const []}) {
  return UpsertCorrespondenceState(
    catalogLoaded: true,
    documentTypes: const [
      repo.DocumentType(id: 'dt-edie', code: 'EDIE', name: 'Encadenamiento'),
      repo.DocumentType(id: 'dt-informe', code: 'INFORME', name: 'Informe Técnico'),
      repo.DocumentType(id: 'dt-nota', code: 'NOTA', name: 'Nota Interna'),
    ],
    organizationalUnits: const [
      repo.OrganizationalUnit(id: 'unit-1', code: 'SYS', name: 'Sistemas'),
    ],
    employees: employees,
  );
}

void main() {
  group('UpsertCorrespondenceState.isCatalogReadyFor', () {
    test('EDIE EXTERNAL funciona con employees vacío', () {
      final state = _loadedState();

      expect(
        state.isCatalogReadyFor(
          profile: DocumentFormProfile.chaining,
          isExternal: true,
        ),
        isTrue,
      );
    });

    test('EDIE INTERNAL no permite continuar sin employee', () {
      final state = _loadedState();

      expect(
        state.isCatalogReadyFor(
          profile: DocumentFormProfile.chaining,
          isExternal: false,
        ),
        isFalse,
      );

      final withEmployee = _loadedState(
        employees: const [
          repo.EmployeeOption(id: 'emp-1', fullName: 'Juan Pérez'),
        ],
      );
      expect(
        withEmployee.isCatalogReadyFor(
          profile: DocumentFormProfile.chaining,
          isExternal: false,
        ),
        isTrue,
      );
    });

    test('INFORME requiere employee', () {
      final state = _loadedState();

      expect(
        state.isCatalogReadyFor(
          profile: DocumentFormProfile.technicalReport,
          isExternal: false,
        ),
        isFalse,
      );
    });

    test('NOTA requiere employee', () {
      final state = _loadedState();

      expect(
        state.isCatalogReadyFor(
          profile: DocumentFormProfile.internalNote,
          isExternal: false,
        ),
        isFalse,
      );
    });
  });

  group('UpsertCorrespondenceCubit.init', () {
    test('init con employees vacío deja base catalog lista para EDIE EXTERNAL',
        () async {
      final cubit = UpsertCorrespondenceCubit(
        correspondenceRepository: _FakeCorrespondenceRepository(),
        organizationRepository: _FakeOrganizationRepository(),
      );

      await cubit.init();

      expect(cubit.state.hasBaseCatalog, isTrue);
      expect(cubit.state.employees, isEmpty);
      expect(
        cubit.state.isCatalogReadyFor(
          profile: DocumentFormProfile.chaining,
          isExternal: true,
        ),
        isTrue,
      );
      await cubit.close();
    });
  });
}
