import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'derive_correspondence_state.dart';

class DeriveCorrespondenceCubit extends Cubit<DeriveCorrespondenceState> {
  DeriveCorrespondenceCubit({
    required repo.CorrespondenceRepository correspondenceRepository,
    required repo.OrganizationRepository organizationRepository,
    required String correspondenceId,
  })  : _correspondenceRepository = correspondenceRepository,
        _organizationRepository = organizationRepository,
        _correspondenceId = correspondenceId,
        super(const DeriveCorrespondenceState());

  final repo.CorrespondenceRepository _correspondenceRepository;
  final repo.OrganizationRepository _organizationRepository;
  final String _correspondenceId;

  Future<void> init() async {
    final unitsResult = await _organizationRepository.listActiveUnits();

    if (unitsResult case Err(:final failure)) {
      emit(
        state.copyWith(
          catalogLoaded: true,
          generalStatus: GeneralStatus.error,
          dialogMessage: DialogMessage(
            title: 'Error',
            message: FailureGeneric.message(
              failure: failure,
              messageResult:
                  'No se pudieron cargar las unidades organizacionales',
            ),
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        organizationalUnits: unitsResult.valueOrNull() ?? const [],
        catalogLoaded: true,
        clearUnitUsers: true,
      ),
    );
  }

  void clearUnitUsers() {
    emit(state.copyWith(clearUnitUsers: true));
  }

  Future<void> loadUnitUsers(String unitId) async {
    emit(
      state.copyWith(
        unitUsersLoading: true,
        clearUnitUsers: true,
      ),
    );

    final result = await _organizationRepository.listUsersByUnit(unitId);

    result.when(
      ok: (users) {
        emit(
          state.copyWith(
            unitUsersLoading: false,
            unitUsers: users,
          ),
        );
      },
      err: (failure) {
        emit(
          state.copyWith(
            unitUsersLoading: false,
            generalStatus: GeneralStatus.error,
            dialogMessage: DialogMessage(
              title: 'Error',
              message: FailureGeneric.message(
                failure: failure,
                messageResult: 'No se pudieron cargar los usuarios de la unidad',
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> derive({
    required String toUnitId,
    String? toUserId,
    String? instruction,
    String? observation,
  }) async {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(
          message: 'Derivando correspondencia...',
        ),
      ),
    );

    final result = await _correspondenceRepository.deriveCorrespondence(
      _correspondenceId,
      repo.DeriveCorrespondenceInput(
        toUnitId: toUnitId,
        toUserId: _optional(toUserId),
        instruction: _optional(instruction),
        observation: _optional(observation),
      ),
    );

    result.when(
      ok: (_) {
        emit(
          state.copyWith(
            generalStatus: GeneralStatus.success,
            dialogMessage: const DialogMessage(
              title: 'Derivación exitosa',
              message: 'La correspondencia fue derivada correctamente.',
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
                messageResult: 'No se pudo derivar la correspondencia',
              ),
            ),
          ),
        );
      },
    );
  }

  String? _optional(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
