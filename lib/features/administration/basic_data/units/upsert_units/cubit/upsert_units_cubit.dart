import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'upsert_units_state.dart';

class UpsertUnitsCubit extends Cubit<UpsertUnitsState> {
  UpsertUnitsCubit(this._repository) : super(const UpsertUnitsState());

  final repo.OrganizationalUnitsAdminRepository _repository;

  Future<void> init({repo.OrganizationalUnitAdmin? editing}) async {
    final result = await _repository.list(
      page: 1,
      pageSize: 100,
      isActive: true,
    );

    result.when(
      ok: (pageResult) {
        final parents = _parentCatalog(
          units: pageResult.items,
          editing: editing,
        );
        emit(
          state.copyWith(
            parentUnits: parents,
            catalogLoaded: true,
          ),
        );
      },
      err: (failure) {
        emit(
          state.copyWith(
            catalogLoaded: true,
            generalStatus: GeneralStatus.error,
            dialogMessage: DialogMessage(
              title: 'Error',
              message: FailureGeneric.message(
                failure: failure,
                messageResult: 'No se pudo cargar el catálogo de unidades',
              ),
            ),
          ),
        );
      },
    );
  }

  List<repo.OrganizationalUnitAdmin> parentOptions({String? excludeUnitId}) {
    return state.parentUnits
        .where((unit) => unit.id != excludeUnitId)
        .toList();
  }

  Future<void> save({
    required String code,
    required String name,
    String? description,
    String? parentId,
  }) async {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(
          message: 'Registrando unidad organizacional...',
        ),
      ),
    );

    final result = await _repository.create(
      repo.OrganizationalUnitInput(
        code: code.trim(),
        name: name.trim(),
        description: _optional(description),
        parentId: _optional(parentId),
      ),
    );

    result.when(
      ok: (_) {
        emit(
          state.copyWith(
            generalStatus: GeneralStatus.success,
            dialogMessage: const DialogMessage(
              title: 'Éxito',
              message: 'Unidad registrada correctamente.',
            ),
          ),
        );
      },
      err: (failure) {
        emit(
          state.copyWith(
            generalStatus: GeneralStatus.error,
            dialogMessage: DialogMessage(
              title: 'Error',
              message: FailureGeneric.message(
                failure: failure,
                messageResult: 'Error al registrar unidad',
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> update({
    required repo.OrganizationalUnitAdmin entity,
    required String name,
    String? description,
    String? parentId,
  }) async {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(
          message: 'Actualizando unidad organizacional...',
        ),
      ),
    );

    final result = await _repository.update(
      entity.id,
      repo.OrganizationalUnitInput(
        code: entity.code ?? '',
        name: name.trim(),
        description: _optional(description),
        parentId: _optional(parentId),
      ),
    );

    result.when(
      ok: (_) {
        emit(
          state.copyWith(
            generalStatus: GeneralStatus.success,
            dialogMessage: const DialogMessage(
              title: 'Éxito',
              message: 'Unidad actualizada correctamente.',
            ),
          ),
        );
      },
      err: (failure) {
        emit(
          state.copyWith(
            generalStatus: GeneralStatus.error,
            dialogMessage: DialogMessage(
              title: 'Error',
              message: FailureGeneric.message(
                failure: failure,
                messageResult: 'Error al actualizar unidad',
              ),
            ),
          ),
        );
      },
    );
  }

  List<repo.OrganizationalUnitAdmin> _parentCatalog({
    required List<repo.OrganizationalUnitAdmin> units,
    repo.OrganizationalUnitAdmin? editing,
  }) {
    if (editing?.parentId == null) return units;

    final hasCurrentParent = units.any((unit) => unit.id == editing!.parentId);
    if (hasCurrentParent) return units;

    return [
      ...units,
      repo.OrganizationalUnitAdmin(
        id: editing!.parentId!,
        code: null,
        name: editing.parentName ?? editing.parentId!,
        isActive: false,
        createdAt: editing.createdAt,
        updatedAt: editing.updatedAt,
      ),
    ];
  }

  String? _optional(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
