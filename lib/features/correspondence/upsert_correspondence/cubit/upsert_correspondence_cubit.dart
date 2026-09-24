import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/mappers/correspondence_entity_mapper.dart';
import 'package:equatable/equatable.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'upsert_correspondence_state.dart';

class UpsertCorrespondenceCubit extends Cubit<UpsertCorrespondenceState> {
  UpsertCorrespondenceCubit({
    required repo.CorrespondenceRepository correspondenceRepository,
    required repo.OrganizationRepository organizationRepository,
  })  : _correspondenceRepository = correspondenceRepository,
        _organizationRepository = organizationRepository,
        super(const UpsertCorrespondenceState());

  final repo.CorrespondenceRepository _correspondenceRepository;
  final repo.OrganizationRepository _organizationRepository;

  Future<void> init() async {
    final typesResult = await _correspondenceRepository.listDocumentTypes();
    final unitsResult = await _organizationRepository.listActiveUnits();

    if (typesResult case Err(:final failure)) {
      emit(
        state.copyWith(
          catalogLoaded: true,
          generalStatus: GeneralStatus.error,
          dialogMessage: DialogMessage(
            title: 'Error',
            message: FailureGeneric.message(
              failure: failure,
              messageResult: 'No se pudieron cargar los tipos de documento',
            ),
          ),
        ),
      );
      return;
    }

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
        documentTypes: typesResult.valueOrNull() ?? const [],
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

  Future<void> create({
    required String subject,
    required CorrespondenceTypeCode type,
    required String priorityLabel,
    required String documentTypeId,
    required String initialToUnitId,
    String? reference,
    String? initialToUserId,
    String? initialInstruction,
    String? senderName,
    String? senderDocument,
    String? senderContact,
    String? originDescription,
  }) async {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        clearCreatedCorrespondence: true,
        dialogMessage: const DialogMessage(
          message: 'Registrando correspondencia...',
        ),
      ),
    );

    final isExternal = type == CorrespondenceTypeCode.ce;
    final input = repo.CreateCorrespondenceInput(
      correspondenceType: correspondenceTypeCodeFromUi(type),
      documentTypeId: documentTypeId,
      subject: subject.trim(),
      priority: priorityCodeFromLabel(priorityLabel),
      reference: _optional(reference),
      senderName: isExternal ? _required(senderName) : null,
      senderDocument: isExternal ? _optional(senderDocument) : null,
      senderContact: isExternal ? _optional(senderContact) : null,
      originDescription: isExternal ? _optional(originDescription) : null,
      initialToUnitId: initialToUnitId,
      initialToUserId: _optional(initialToUserId),
      initialInstruction: _optional(initialInstruction),
    );

    final result = await _correspondenceRepository.createCorrespondence(input);

    result.when(
      ok: (created) {
        emit(
          state.copyWith(
            createdCorrespondence: created,
            generalStatus: GeneralStatus.success,
            dialogMessage: DialogMessage(
              title: 'Registro exitoso',
              message:
                  'La correspondencia fue registrada correctamente. ${created.routeNumber}',
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
                messageResult: 'No se pudo registrar la correspondencia',
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

  String _required(String? value) => value?.trim() ?? '';
}
