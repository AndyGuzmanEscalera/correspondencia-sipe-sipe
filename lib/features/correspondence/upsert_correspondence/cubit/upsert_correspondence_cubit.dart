import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/document_type_profiles.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/mappers/correspondence_entity_mapper.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/models/pending_attachment.dart';
import 'package:equatable/equatable.dart';
import 'package:crypto/crypto.dart';
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

  List<PendingAttachment> _failedAttachments = [];
  int _uploadedCount = 0;

  Future<void> init() async {
    if (state.generalStatus == GeneralStatus.loading) return;
    emit(state.copyWith(
        documentTypes: const [],
        clearRouteSheetAuthority: true,
        catalogLoaded: false,
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(
            message: "Cargando catálogos...", showLoading: false)));
    final policyResult = await _correspondenceRepository.getCreationPolicy();
    if (isClosed) return;
    if (policyResult case Err(:final failure)) {
      emit(state.copyWith(
          catalogLoaded: true,
          generalStatus: GeneralStatus.error,
          dialogMessage: DialogMessage(
              title: 'Error',
              message: FailureGeneric.message(
                  failure: failure,
                  messageResult:
                      'No se pudo validar la configuración de recepción inicial'))));
      return;
    }
    final typesResult = await _correspondenceRepository.listDocumentTypes();
    final unitsResult = await _organizationRepository.listActiveUnits();
    final employeesResult = await _correspondenceRepository.listEmployees();
    final recipientsResult =
        await _correspondenceRepository.listEdieFirstRecipients();

    if (isClosed) return;
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

    final documentTypes = typesResult.valueOrNull() ?? const [];
    final defaultType = resolveDefaultChainingDocumentType(documentTypes);
    final authority = documentTypes
            .any((type) => type.behavior == repo.DocumentBehavior.routeSheet)
        ? (await _correspondenceRepository.getRouteSheetAuthority())
            .valueOrNull()
        : null;
    if (isClosed) return;

    emit(
      state.copyWith(
        generalStatus: GeneralStatus.initial,
        dialogMessage: const DialogMessage.empty(),
        isIntake: policyResult.valueOrNull()!,
        documentTypes: documentTypes,
        routeSheetAuthority: authority,
        organizationalUnits: unitsResult.valueOrNull() ?? const [],
        employees: employeesResult.valueOrNull() ?? const [],
        firstRecipients: recipientsResult.valueOrNull() ?? const [],
        firstRecipientsError: recipientsResult.when(
          ok: (_) => '',
          err: (failure) => FailureGeneric.message(
            failure: failure,
            messageResult:
                'No se pudieron cargar los receptores iniciales configurados.',
          ),
        ),
        defaultDocumentTypeId: defaultType?.id,
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
    if (isClosed) return;

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
                messageResult:
                    'No se pudieron cargar los usuarios de la unidad',
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> create({
    required DocumentBehavior profile,
    required CorrespondenceTypeCode type,
    required String priorityLabel,
    required String documentTypeId,
    required String initialToUnitId,
    String? subject,
    String? reference,
    String? description,
    String? originEmployeeId,
    String? firstRecipientEmployeeId,
    String? initialToUserId,
    String? initialInstruction,
    String? senderName,
    String? senderDocument,
    String? senderContact,
    String? originDescription,
    List<PendingAttachment> pendingAttachments = const [],
  }) async {
    if (state.generalStatus == GeneralStatus.loading || state.createdCorrespondence != null) return;
    _uploadedCount = 0;
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        clearCreatedCorrespondence: true,
        clearAttachmentUploadFailures: true,
        dialogMessage: const DialogMessage(
          message: 'Registrando correspondencia...',
        ),
      ),
    );

    final input = _buildInput(
      pendingAttachments: pendingAttachments,
      profile: profile,
      type: type,
      priorityLabel: priorityLabel,
      documentTypeId: documentTypeId,
      initialToUnitId: initialToUnitId,
      subject: subject,
      reference: reference,
      description: description,
      originEmployeeId: originEmployeeId,
      firstRecipientEmployeeId: firstRecipientEmployeeId,
      initialToUserId: initialToUserId,
      initialInstruction: initialInstruction,
      senderName: senderName,
      senderDocument: senderDocument,
      senderContact: senderContact,
      originDescription: originDescription,
    );

    final result = await _correspondenceRepository.createCorrespondence(input);
    if (isClosed) return;

    if (result case Err(:final failure)) {
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
      return;
    }

    final created = result.valueOrNull()!;
    final uploadFailures = await _uploadPendingAttachments(
      correspondenceId: created.id,
      attachments: pendingAttachments,
    );

    final successMessage = uploadFailures.isEmpty
        ? 'La correspondencia fue registrada correctamente. ${created.routeNumber}'
        : 'La correspondencia fue registrada (${created.routeNumber}), '
            '$_uploadedCount adjunto(s) subidos; ${uploadFailures.length} fallido(s).';

    emit(
      state.copyWith(
        createdCorrespondence: created,
        attachmentUploadFailures: uploadFailures,
        generalStatus: GeneralStatus.success,
        dialogMessage: DialogMessage(
          title:
              uploadFailures.isEmpty ? 'Registro exitoso' : 'Registro parcial',
          message: successMessage,
        ),
      ),
    );
  }

  repo.CreateCorrespondenceInput _buildInput({
    List<PendingAttachment> pendingAttachments = const [],
    required DocumentBehavior profile,
    required CorrespondenceTypeCode type,
    required String priorityLabel,
    required String documentTypeId,
    required String initialToUnitId,
    String? subject,
    String? reference,
    String? description,
    String? originEmployeeId,
    String? firstRecipientEmployeeId,
    String? initialToUserId,
    String? initialInstruction,
    String? senderName,
    String? senderDocument,
    String? senderContact,
    String? originDescription,
  }) {
    final isContent = isContentProfile(profile);
    final isExternal = !isContent && type == CorrespondenceTypeCode.ce;
    final requiresOrigin = isContent ||
        ((profile == DocumentBehavior.legacyChaining ||
                profile == DocumentBehavior.routeSheet) &&
            !isExternal);
    return repo.CreateCorrespondenceInput(
      initialAttachments: pendingAttachments.map((a) => <String, dynamic>{
        'filename': a.filename, 'size': a.bytes.length,
        'sha256': sha256.convert(a.bytes).toString(),
      }).toList(),
      enablePublicTracking: profile == DocumentBehavior.routeSheet && isExternal && _optional(senderDocument) != null,
      correspondenceType:
          isContent ? 'INTERNAL' : correspondenceTypeCodeFromUi(type),
      documentTypeId: documentTypeId,
      subject: profile == DocumentBehavior.generic
          ? _required(subject)
          : _optional(subject),
      priority: priorityCodeFromLabel(priorityLabel),
      reference: _optional(reference),
      description: isContent || profile == DocumentBehavior.routeSheet
          ? _required(description)
          : null,
      originEmployeeId: isExternal
          ? null
          : requiresOrigin
              ? _required(originEmployeeId)
              : _optional(originEmployeeId),
      senderName: isExternal ? _required(senderName) : null,
      senderDocument: isExternal ? _optional(senderDocument) : null,
      senderContact: isExternal ? _optional(senderContact) : null,
      originDescription: isExternal ? _optional(originDescription) : null,
      firstRecipientEmployeeId: _optional(firstRecipientEmployeeId),
      initialToUnitId: initialToUnitId,
      initialToUserId: _optional(initialToUserId),
      initialInstruction: _optional(initialInstruction),
    );
  }

  Future<List<String>> _uploadPendingAttachments({
    required String correspondenceId,
    required List<PendingAttachment> attachments,
  }) async {
    if (attachments.isEmpty) return const [];

    final failures = <String>[];
    final failed = <PendingAttachment>[];
    for (final attachment in attachments) {
      final result = await _correspondenceRepository.uploadAttachment(
        correspondenceId: correspondenceId,
        input: repo.UploadAttachmentInput(
          filename: attachment.filename,
          bytes: attachment.bytes,
          mimeType: attachment.mimeType,
        ),
      );
      if (result case Err(:final failure)) {
        failed.add(attachment);
        failures.add(
          '${attachment.filename}: ${FailureGeneric.message(failure: failure)}',
        );
      } else {
        _uploadedCount++;
      }
    }
    _failedAttachments = failed;
    return failures;
  }

  Future<void> retryFailedAttachments() async {
    final created = state.createdCorrespondence;
    if (created == null || _failedAttachments.isEmpty || state.generalStatus == GeneralStatus.loading) return;
    emit(state.copyWith(generalStatus: GeneralStatus.loading,
      dialogMessage: const DialogMessage(message: 'Reintentando adjuntos...')));
    final failures = await _uploadPendingAttachments(
      correspondenceId: created.id, attachments: List.of(_failedAttachments));
    if (isClosed) return;
    emit(state.copyWith(generalStatus: GeneralStatus.success,
      attachmentUploadFailures: failures,
      dialogMessage: DialogMessage(title: failures.isEmpty ? 'Registro exitoso' : 'Registro parcial',
        message: '${created.routeNumber}: $_uploadedCount adjunto(s) subidos; ${failures.length} fallido(s).')));
  }

  String? _optional(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  String _required(String? value) => value?.trim() ?? '';
}
