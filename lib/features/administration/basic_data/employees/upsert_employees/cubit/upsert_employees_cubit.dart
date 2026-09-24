import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'upsert_employees_state.dart';

class UpsertEmployeesCubit extends Cubit<UpsertEmployeesState> {
  UpsertEmployeesCubit({
    required repo.EmployeesAdminRepository employeesRepository,
    required repo.OrganizationalUnitsAdminRepository unitsRepository,
    required repo.PositionsAdminRepository positionsRepository,
  })  : _employeesRepository = employeesRepository,
        _unitsRepository = unitsRepository,
        _positionsRepository = positionsRepository,
        super(const UpsertEmployeesState());

  final repo.EmployeesAdminRepository _employeesRepository;
  final repo.OrganizationalUnitsAdminRepository _unitsRepository;
  final repo.PositionsAdminRepository _positionsRepository;

  Future<void> init({repo.EmployeeAdmin? editing}) async {
    final unitsResult = await _unitsRepository.list(
      page: 1,
      pageSize: 100,
      isActive: true,
    );
    final positionsResult = await _positionsRepository.list(
      page: 1,
      pageSize: 100,
      isActive: true,
    );

    if (unitsResult case Err(:final failure)) {
      emit(
        state.copyWith(
          catalogLoaded: true,
          generalStatus: GeneralStatus.error,
          dialogMessage: DialogMessage(
            title: 'Error',
            message: FailureGeneric.message(
              failure: failure,
              messageResult: 'No se pudieron cargar unidades activas',
            ),
          ),
        ),
      );
      return;
    }

    if (positionsResult case Err(:final failure)) {
      emit(
        state.copyWith(
          catalogLoaded: true,
          generalStatus: GeneralStatus.error,
          dialogMessage: DialogMessage(
            title: 'Error',
            message: FailureGeneric.message(
              failure: failure,
              messageResult: 'No se pudieron cargar cargos activos',
            ),
          ),
        ),
      );
      return;
    }

    final unitsPage = unitsResult.valueOrNull()!;
    final positionsPage = positionsResult.valueOrNull()!;

    emit(
      state.copyWith(
        units: _unitsCatalog(
          units: unitsPage.items,
          editing: editing,
        ),
        positions: _positionsCatalog(
          positions: positionsPage.items,
          editing: editing,
        ),
        catalogLoaded: true,
      ),
    );
  }

  Future<void> save({
    required String firstName,
    required String lastName,
    required String documentNumber,
    required String unitId,
    required String positionId,
    String? email,
    String? phone,
  }) async {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(
          message: 'Registrando funcionario...',
        ),
      ),
    );

    final result = await _employeesRepository.create(
      repo.EmployeeInput(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        documentNumber: documentNumber.trim(),
        unitId: unitId,
        positionId: positionId,
        email: _optional(email),
        phone: _optional(phone),
      ),
    );

    result.when(
      ok: (_) {
        emit(
          state.copyWith(
            generalStatus: GeneralStatus.success,
            dialogMessage: const DialogMessage(
              title: 'Éxito',
              message: 'Funcionario registrado correctamente.',
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
                messageResult: 'Error al registrar funcionario',
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> update({
    required repo.EmployeeAdmin entity,
    required String firstName,
    required String lastName,
    required String documentNumber,
    required String unitId,
    required String positionId,
    String? email,
    String? phone,
  }) async {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(
          message: 'Actualizando funcionario...',
        ),
      ),
    );

    final result = await _employeesRepository.update(
      entity.id,
      repo.EmployeeInput(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        documentNumber: documentNumber.trim(),
        unitId: unitId,
        positionId: positionId,
        email: _optional(email),
        phone: _optional(phone),
      ),
    );

    result.when(
      ok: (_) {
        emit(
          state.copyWith(
            generalStatus: GeneralStatus.success,
            dialogMessage: const DialogMessage(
              title: 'Éxito',
              message: 'Funcionario actualizado correctamente.',
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
                messageResult: 'Error al actualizar funcionario',
              ),
            ),
          ),
        );
      },
    );
  }

  List<repo.OrganizationalUnitAdmin> _unitsCatalog({
    required List<repo.OrganizationalUnitAdmin> units,
    repo.EmployeeAdmin? editing,
  }) {
    if (editing?.unitId == null) return units;

    final hasCurrentUnit = units.any((unit) => unit.id == editing!.unitId);
    if (hasCurrentUnit) return units;

    return [
      ...units,
      repo.OrganizationalUnitAdmin(
        id: editing!.unitId!,
        code: null,
        name: editing.unitName ?? editing.unitId!,
        isActive: false,
        createdAt: editing.createdAt,
        updatedAt: editing.updatedAt,
      ),
    ];
  }

  List<repo.PositionAdmin> _positionsCatalog({
    required List<repo.PositionAdmin> positions,
    repo.EmployeeAdmin? editing,
  }) {
    if (editing?.positionId == null) return positions;

    final hasCurrentPosition =
        positions.any((position) => position.id == editing!.positionId);
    if (hasCurrentPosition) return positions;

    return [
      ...positions,
      repo.PositionAdmin(
        id: editing!.positionId!,
        code: null,
        name: editing.positionName ?? editing.positionId!,
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
