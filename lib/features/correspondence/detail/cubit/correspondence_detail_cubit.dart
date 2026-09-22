import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_movement_entity.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/mappers/correspondence_entity_mapper.dart';
import 'package:equatable/equatable.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'correspondence_detail_state.dart';

class DeriveCorrespondenceFormData {
  const DeriveCorrespondenceFormData({
    required this.toUnitId,
    this.toUserId,
    this.instruction,
    this.observation,
  });

  final String toUnitId;
  final String? toUserId;
  final String? instruction;
  final String? observation;
}

class CorrespondenceDetailCubit extends Cubit<CorrespondenceDetailState> {
  CorrespondenceDetailCubit({
    required repo.CorrespondenceRepository repository,
    required repo.OrganizationRepository organizationRepository,
    required String correspondenceId,
  })  : _repository = repository,
        _organizationRepository = organizationRepository,
        _correspondenceId = correspondenceId,
        super(const CorrespondenceDetailState());

  final repo.CorrespondenceRepository _repository;
  final repo.OrganizationRepository _organizationRepository;
  final String _correspondenceId;

  Future<void> init() async {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(message: 'Cargando detalle...'),
      ),
    );

    final unitsResult = await _organizationRepository.listActiveUnits();
    if (unitsResult case Err(:final failure)) {
      emit(
        state.copyWith(
          generalStatus: GeneralStatus.error,
          dialogMessage: DialogMessage(message: failure.message),
        ),
      );
      emit(state.copyWith(generalStatus: GeneralStatus.initial));
      return;
    }

    emit(
      state.copyWith(
        organizationalUnits: unitsResult.valueOrNull() ?? const [],
      ),
    );

    await _loadDetail(showSuccess: false);
  }

  Future<void> loadUsersForUnit(String unitId) async {
    final usersResult = await _organizationRepository.listUsersByUnit(unitId);
    if (usersResult case Err(:final failure)) {
      emit(
        state.copyWith(
          generalStatus: GeneralStatus.error,
          dialogMessage: DialogMessage(message: failure.message),
        ),
      );
      emit(state.copyWith(generalStatus: GeneralStatus.initial));
      return;
    }

    emit(state.copyWith(unitUsers: usersResult.valueOrNull() ?? const []));
  }

  Future<void> derive(DeriveCorrespondenceFormData form) async {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(message: 'Derivando trámite...'),
      ),
    );

    final result = await _repository.deriveCorrespondence(
      _correspondenceId,
      repo.DeriveCorrespondenceInput(
        toUnitId: form.toUnitId,
        toUserId: form.toUserId,
        instruction: form.instruction,
        observation: form.observation,
      ),
    );

    if (result case Err(:final failure)) {
      emit(
        state.copyWith(
          generalStatus: GeneralStatus.error,
          dialogMessage: DialogMessage(message: failure.message),
        ),
      );
      emit(state.copyWith(generalStatus: GeneralStatus.initial));
      return;
    }

    await _loadDetail(
      showSuccess: true,
      successMessage: 'La correspondencia fue derivada correctamente.',
      successTitle: 'Derivación exitosa',
    );
  }

  Future<void> _loadDetail({
    bool showSuccess = false,
    String? successMessage,
    String? successTitle,
  }) async {
    final detailResult = await _repository.getCorrespondence(_correspondenceId);
    if (detailResult case Err(:final failure)) {
      emit(
        state.copyWith(
          generalStatus: GeneralStatus.error,
          dialogMessage: DialogMessage(message: failure.message),
        ),
      );
      emit(state.copyWith(generalStatus: GeneralStatus.initial));
      return;
    }

    final movementsResult =
        await _repository.listMovements(_correspondenceId);
    if (movementsResult case Err(:final failure)) {
      emit(
        state.copyWith(
          generalStatus: GeneralStatus.error,
          dialogMessage: DialogMessage(message: failure.message),
        ),
      );
      emit(state.copyWith(generalStatus: GeneralStatus.initial));
      return;
    }

    final detail = detailResult.valueOrNull()!.toUiEntity();
    final movements = movementsResult
            .valueOrNull()
            ?.map((item) => item.toUiEntity())
            .toList() ??
        const <CorrespondenceMovementEntity>[];

    emit(
      state.copyWith(
        correspondence: detail,
        movements: movements,
        generalStatus: showSuccess ? GeneralStatus.success : GeneralStatus.initial,
        dialogMessage: showSuccess
            ? DialogMessage(
                title: successTitle,
                message: successMessage ?? '',
              )
            : const DialogMessage.empty(),
      ),
    );

    if (showSuccess) {
      emit(state.copyWith(generalStatus: GeneralStatus.initial));
    }
  }
}
