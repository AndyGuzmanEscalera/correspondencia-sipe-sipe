import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/document_types/upsert_document_types/cubit/upsert_document_types_cubit.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpsertDocumentTypesCubit', () {
    late _FakeDocumentTypesAdminRepository repository;

    setUp(() {
      repository = _FakeDocumentTypesAdminRepository();
    });

    test('save create emite loading y success con DialogMessage', () async {
      final cubit = UpsertDocumentTypesCubit(repository);
      final states = <UpsertDocumentTypesState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.save(code: 'CARTA', name: 'Carta');

      expect(states[0].generalStatus, GeneralStatus.loading);
      expect(
        states[0].dialogMessage.message,
        'Registrando tipo de documento...',
      );
      expect(cubit.state.generalStatus, GeneralStatus.success);
      expect(
        cubit.state.dialogMessage.message,
        'Tipo de documento registrado correctamente.',
      );
      expect(repository.lastCreateInput?.code, 'CARTA');
      await sub.cancel();
      await cubit.close();
    });

    test('update emite loading y success con DialogMessage', () async {
      final cubit = UpsertDocumentTypesCubit(repository);
      final states = <UpsertDocumentTypesState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.update(name: 'Carta actualizada', entity: _entity);

      expect(states[0].generalStatus, GeneralStatus.loading);
      expect(
        states[0].dialogMessage.message,
        'Actualizando tipo de documento...',
      );
      expect(cubit.state.generalStatus, GeneralStatus.success);
      expect(
        cubit.state.dialogMessage.message,
        'Tipo de documento actualizado correctamente.',
      );
      expect(repository.lastUpdateId, 'dt-1');
      expect(repository.lastUpdateInput?.name, 'Carta actualizada');
      await sub.cancel();
      await cubit.close();
    });

    test('save conflict 409 emite error con mensaje funcional', () async {
      const conflictMessage =
          'Ya existe un tipo de documento con el código indicado.';
      repository.createResult = const Err(
        ValidationFailure(conflictMessage),
      );
      final cubit = UpsertDocumentTypesCubit(repository);

      await cubit.save(code: 'CARTA', name: 'Carta');

      expect(cubit.state.generalStatus, GeneralStatus.error);
      expect(cubit.state.dialogMessage.title, 'Error');
      expect(cubit.state.dialogMessage.message, conflictMessage);
      expect(
        cubit.state.dialogMessage.message,
        isNot(contains('DioException')),
      );
      expect(
        cubit.state.dialogMessage.message,
        isNot(contains('SQL')),
      );
      await cubit.close();
    });

    test('update error emite DialogMessage con FailureGeneric', () async {
      repository.updateResult = const Err(ServerFailure('Error del servidor'));
      final cubit = UpsertDocumentTypesCubit(repository);

      await cubit.update(name: 'Carta', entity: _entity);

      expect(cubit.state.generalStatus, GeneralStatus.error);
      expect(cubit.state.dialogMessage.message, 'Error del servidor');
      await cubit.close();
    });

    test('save error genérico usa FailureGeneric fallback', () async {
      repository.createResult = const Err(GenericFailure(''));
      final cubit = UpsertDocumentTypesCubit(repository);

      await cubit.save(code: 'CARTA', name: 'Carta');

      expect(cubit.state.generalStatus, GeneralStatus.error);
      expect(
        cubit.state.dialogMessage.message,
        'Error al registrar tipo de documento',
      );
      await cubit.close();
    });
  });
}

final _entity = DocumentTypeAdmin(
  id: 'dt-1',
  code: 'CARTA',
  name: 'Carta',
  isActive: true,
  createdAt: _date,
  updatedAt: _date,
);

final _date = DateTime.utc(2026, 1, 1);

class _FakeDocumentTypesAdminRepository
    implements DocumentTypesAdminRepository {
  Result<DocumentTypeAdmin, Failure>? createResult;
  Result<DocumentTypeAdmin, Failure>? updateResult;
  DocumentTypeInput? lastCreateInput;
  String? lastUpdateId;
  DocumentTypeUpdateInput? lastUpdateInput;

  @override
  Future<Result<DocumentTypeAdmin, Failure>> create(
    DocumentTypeInput input,
  ) async {
    lastCreateInput = input;
    return createResult ??
        Ok(
          DocumentTypeAdmin(
            id: 'dt-new',
            code: input.code,
            name: input.name,
            isActive: true,
            createdAt: _date,
            updatedAt: _date,
          ),
        );
  }

  @override
  Future<Result<DocumentTypeAdmin, Failure>> update(
    String id,
    DocumentTypeUpdateInput input,
  ) async {
    lastUpdateId = id;
    lastUpdateInput = input;
    return updateResult ??
        Ok(
          DocumentTypeAdmin(
            id: id,
            code: 'CARTA',
            name: input.name,
            isActive: true,
            createdAt: _date,
            updatedAt: _date,
          ),
        );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
