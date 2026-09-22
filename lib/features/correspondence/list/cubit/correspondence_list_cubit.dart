import 'dart:async';

import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:failures/failures.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/mappers/correspondence_entity_mapper.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'correspondence_list_state.dart';

class CreateCorrespondenceFormData {
  const CreateCorrespondenceFormData({
    required this.subject,
    required this.type,
    required this.priorityLabel,
    required this.documentTypeId,
    required this.initialToUnitId,
    this.reference,
    this.initialToUserId,
    this.initialInstruction,
    this.senderName,
    this.senderDocument,
    this.senderContact,
    this.originDescription,
  });

  final String subject;
  final CorrespondenceTypeCode type;
  final String priorityLabel;
  final String documentTypeId;
  final String initialToUnitId;
  final String? reference;
  final String? initialToUserId;
  final String? initialInstruction;
  final String? senderName;
  final String? senderDocument;
  final String? senderContact;
  final String? originDescription;
}

class CorrespondenceListCubit extends Cubit<CorrespondenceListState> {
  CorrespondenceListCubit({
    required repo.CorrespondenceRepository repository,
    required repo.OrganizationRepository organizationRepository,
  })  : _repository = repository,
        _organizationRepository = organizationRepository,
        super(const CorrespondenceListState());

  final repo.CorrespondenceRepository _repository;
  final repo.OrganizationRepository _organizationRepository;
  Timer? _searchDebounce;

  Future<void> init() async {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        catalogsLoading: true,
        dialogMessage: const DialogMessage(
          message: 'Cargando correspondencias...',
        ),
      ),
    );

    final typesResult = await _repository.listDocumentTypes();
    final unitsResult = await _organizationRepository.listActiveUnits();

    if (typesResult case Err(:final failure)) {
      _emitCatalogError(failure.message);
      return;
    }
    if (unitsResult case Err(:final failure)) {
      _emitCatalogError(failure.message);
      return;
    }

    final documentTypes = typesResult.valueOrNull() ?? const [];
    final organizationalUnits = unitsResult.valueOrNull() ?? const [];

    emit(
      state.copyWith(
        documentTypes: documentTypes,
        organizationalUnits: organizationalUnits,
        catalogsLoading: false,
      ),
    );

    await _loadList(search: state.query, showSuccess: false);
  }

  void resetCreateDestinationUsers() {
    emit(state.copyWith(clearCreateUnitUsers: true));
  }

  Future<void> loadCreateUnitUsers(String unitId) async {
    emit(state.copyWith(unitUsersLoading: true, clearCreateUnitUsers: true));
    final result = await _organizationRepository.listUsersByUnit(unitId);
    if (result case Err(:final failure)) {
      emit(
        state.copyWith(
          unitUsersLoading: false,
          generalStatus: GeneralStatus.error,
          dialogMessage: DialogMessage(message: failure.message),
        ),
      );
      emit(state.copyWith(generalStatus: GeneralStatus.initial));
      return;
    }
    emit(
      state.copyWith(
        unitUsersLoading: false,
        createUnitUsers: result.valueOrNull() ?? const [],
      ),
    );
  }

  void filter(String query) {
    emit(state.copyWith(query: query));
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _loadList(search: query.trim(), page: 1);
    });
  }

  Future<void> changePage(int page) async {
    await _loadList(search: state.query, page: page);
  }

  Future<void> changePageSize(int pageSize) async {
    await _loadList(search: state.query, page: 1, pageSize: pageSize);
  }

  Future<bool> create(CreateCorrespondenceFormData form) async {
    emit(state.copyWith(createInProgress: true));

    final isExternal = form.type == CorrespondenceTypeCode.ce;
    final input = repo.CreateCorrespondenceInput(
      correspondenceType: correspondenceTypeCodeFromUi(form.type),
      documentTypeId: form.documentTypeId,
      subject: form.subject,
      priority: priorityCodeFromLabel(form.priorityLabel),
      reference: _optional(form.reference),
      senderName: isExternal ? _required(form.senderName) : null,
      senderDocument: isExternal ? _optional(form.senderDocument) : null,
      senderContact: isExternal ? _optional(form.senderContact) : null,
      originDescription: isExternal ? _optional(form.originDescription) : null,
      initialToUnitId: form.initialToUnitId,
      initialToUserId: _optional(form.initialToUserId),
      initialInstruction: _optional(form.initialInstruction),
    );

    final result = await _repository.createCorrespondence(input);
    if (result case Err(:final failure)) {
      emit(
        state.copyWith(
          createInProgress: false,
          generalStatus: GeneralStatus.error,
          dialogMessage: DialogMessage(message: failure.message),
        ),
      );
      emit(state.copyWith(generalStatus: GeneralStatus.initial));
      return false;
    }

    await _loadList(
      search: state.query,
      showSuccess: true,
      successMessage: 'La correspondencia fue registrada correctamente.',
      successTitle: 'Registro exitoso',
    );
    emit(state.copyWith(createInProgress: false));
    return true;
  }

  void _emitCatalogError(String message) {
    emit(
      state.copyWith(
        catalogsLoading: false,
        generalStatus: GeneralStatus.error,
        dialogMessage: DialogMessage(message: message),
      ),
    );
    emit(state.copyWith(generalStatus: GeneralStatus.initial));
  }

  String? _optional(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  String _required(String? value) => value?.trim() ?? '';

  Future<void> _loadList({
    required String search,
    int? page,
    int? pageSize,
    bool showSuccess = false,
    String? successMessage,
    String? successTitle,
  }) async {
    final targetPage = page ?? state.page;
    final targetPageSize = pageSize ?? state.pageSize;
    emit(state.copyWith(listLoading: true));

    final result = await _repository.listCorrespondences(
      page: targetPage,
      pageSize: targetPageSize,
      search: search.isEmpty ? null : search,
    );

    if (result case Err(:final failure)) {
      emit(state.copyWith(listLoading: false));
      emit(
        state.copyWith(
          generalStatus: GeneralStatus.error,
          dialogMessage: DialogMessage(message: failure.message),
        ),
      );
      emit(state.copyWith(generalStatus: GeneralStatus.initial));
      return;
    }

    final pageResult = result.valueOrNull();
    final items =
        pageResult?.items.map((item) => item.toUiEntity()).toList() ?? [];

    emit(
      state.copyWith(
        items: items,
        page: pageResult?.page ?? targetPage,
        pageSize: pageResult?.pageSize ?? targetPageSize,
        total: pageResult?.total ?? 0,
        totalPages: pageResult?.totalPages ?? 0,
        listLoading: false,
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

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
