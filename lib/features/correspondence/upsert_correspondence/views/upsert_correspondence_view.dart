import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/views/correspondence_detail_page.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/document_type_profiles.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/list_correspondence/cubit/correspondence_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/cubit/upsert_correspondence_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/attachments_section.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/chaining_fields.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/destination_section.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/document_type_section.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/generic_fields.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/internal_note_fields.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/origin_section.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/technical_report_fields.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/app_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpsertCorrespondencePage extends StatelessWidget {
  const UpsertCorrespondencePage({super.key, required this.typeOperation});

  final TypeOperation typeOperation;

  @override
  Widget build(BuildContext context) {
    return UpsertCorrespondenceInherited(
      typeOperation: typeOperation,
      child: BlocProvider(
        create: (context) => getIt<UpsertCorrespondenceCubit>(),
        child: const UpsertCorrespondenceView(),
      ),
    );
  }
}

class UpsertCorrespondenceView extends StatelessWidget {
  const UpsertCorrespondenceView({super.key});

  @override
  Widget build(BuildContext context) {
    final listCubit = context.read<CorrespondenceCubit>();
    final upsertCubit = context.read<UpsertCorrespondenceCubit>();

    return MultiBlocListener(
      listeners: [
        ListenerPro<UpsertCorrespondenceCubit, UpsertCorrespondenceState>()
            .listen(
          onPressedSuccess: () {
            final created = upsertCubit.state.createdCorrespondence;
            final navigator = Navigator.of(context, rootNavigator: true);
            navigator.pop();
            if (created != null) {
              navigator.push(
                MaterialPageRoute<void>(
                  builder: (_) => CorrespondenceDetailPage(
                    correspondenceId: created.id,
                  ),
                ),
              );
            }
          },
        ),
        ListenerPro<UpsertCorrespondenceCubit, UpsertCorrespondenceState>()
            .event(
          onSuccess: (_) {
            listCubit.get();
            context.read<SideMenuCubit>().refreshBadges();
          },
        ),
      ],
      child: FullWidgetGeneric(
        onInit: () {
          final inherited = UpsertCorrespondenceInherited.of(context);
          inherited.clear();
          upsertCubit.init();
        },
        onDispose: UpsertCorrespondenceInherited.of(context).dispose,
        child: const UpsertCorrespondenceBody(),
      ),
    );
  }
}

class UpsertCorrespondenceBody extends StatefulWidget {
  const UpsertCorrespondenceBody({super.key});

  @override
  State<UpsertCorrespondenceBody> createState() =>
      _UpsertCorrespondenceBodyState();
}

class _UpsertCorrespondenceBodyState extends State<UpsertCorrespondenceBody> {
  CorrespondenceTypeCode _selectedType = CorrespondenceTypeCode.ce;
  DocumentFormProfile _profile = DocumentFormProfile.chaining;
  bool _defaultsApplied = false;

  bool get _isExternal => _selectedType == CorrespondenceTypeCode.ce;

  void _applyDefaultDocumentType(UpsertCorrespondenceState state) {
    if (_defaultsApplied || state.defaultDocumentTypeId == null) return;

    final inherited = UpsertCorrespondenceInherited.of(context);
    FormOption<String>? defaultOption;
    for (final type in state.documentTypes) {
      if (type.id == state.defaultDocumentTypeId) {
        defaultOption = FormOption<String>(
          id: type.id.hashCode,
          text: type.code,
          description: type.name,
          value: type.id,
        );
        _profile = resolveDocumentFormProfile(type.code);
        break;
      }
    }
    if (defaultOption != null) {
      inherited.documentType.setDefaultValue(defaultOption);
      if (_profile == DocumentFormProfile.technicalReport ||
          _profile == DocumentFormProfile.internalNote) {
        inherited.type.setDefaultValue(
          UpsertCorrespondenceInherited.typeItems[1],
        );
        _selectedType = CorrespondenceTypeCode.ci;
      }
    }
    _defaultsApplied = true;
  }

  void _onDocumentTypeChanged(DocumentType documentType) {
    final profile = resolveDocumentFormProfile(documentType.code);
    setState(() {
      _profile = profile;
    });
    if (profile == DocumentFormProfile.technicalReport ||
        profile == DocumentFormProfile.internalNote) {
      _onTypeChanged(CorrespondenceTypeCode.ci);
    }
  }

  void _onTypeChanged(CorrespondenceTypeCode type) {
    setState(() {
      _selectedType = type;
    });
    if (type == CorrespondenceTypeCode.ci) {
      UpsertCorrespondenceInherited.of(context).clearExternalFields();
    }
  }

  @override
  Widget build(BuildContext context) {
    final inherited = UpsertCorrespondenceInherited.of(context);
    final upsertCubit = context.read<UpsertCorrespondenceCubit>();

    return BlocBuilder<UpsertCorrespondenceCubit, UpsertCorrespondenceState>(
      builder: (context, state) {
        if (!state.catalogLoaded) {
          return const AppFormDialog(
            title: 'Nueva correspondencia',
            maxWidth: 640,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (!state.hasBaseCatalog) {
          return const AppFormDialog(
            title: 'Nueva correspondencia',
            maxWidth: 640,
            onSubmit: null,
            child: Text(
              'No se pudieron cargar los catálogos necesarios.',
            ),
          );
        }

        _applyDefaultDocumentType(state);

        final isLoading = state.generalStatus == GeneralStatus.loading;
        final catalogReady = state.isCatalogReadyFor(
          profile: _profile,
          isExternal: _isExternal,
        );
        final canSubmit = catalogReady && !isLoading && !state.unitUsersLoading;

        return AppFormDialog(
          title: 'Nueva correspondencia',
          subtitle: 'Registro y clasificación institucional de trámite',
          maxWidth: 640,
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          isLoading: isLoading,
          isSubmitDisabled: !canSubmit,
          submitLabel: 'Registrar',
          cancelLabel: 'Cancelar',
          onSubmit: canSubmit ? () => _submit(upsertCubit, inherited) : null,
          onCancel: isLoading ? null : () => Navigator.pop(context),
          child: Form(
            key: inherited.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                DocumentTypeSection(
                  documentTypes: state.documentTypes,
                  onDocumentTypeChanged: _onDocumentTypeChanged,
                ),
                OriginSection(
                  profile: _profile,
                  employees: state.employees,
                  isExternal: _isExternal,
                  onTypeChanged: _onTypeChanged,
                ),
                if (_profile == DocumentFormProfile.chaining)
                  const ChainingFields(),
                if (_profile == DocumentFormProfile.technicalReport)
                  const TechnicalReportFields(),
                if (_profile == DocumentFormProfile.internalNote)
                  const InternalNoteFields(),
                if (_profile == DocumentFormProfile.generic)
                  const GenericFields(),
                DestinationSection(
                  organizationalUnits: state.organizationalUnits,
                  unitUsers: state.unitUsers,
                  unitUsersLoading: state.unitUsersLoading,
                ),
                const AttachmentsSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit(
    UpsertCorrespondenceCubit upsertCubit,
    UpsertCorrespondenceInherited inherited,
  ) async {
    final validResult = inherited.valid(
      profile: _profile,
      isExternal: _isExternal,
    );
    if (!validResult.isPassed) return;

    final type = inherited.type.get() ?? CorrespondenceTypeCode.ci;
    final priority = inherited.priority.get();
    final documentTypeId = inherited.documentType.get();
    final toUnitId = inherited.toUnit.get();
    if (priority == null ||
        documentTypeId == null ||
        toUnitId == null ||
        toUnitId.isEmpty) {
      return;
    }

    final selectedUser =
        inherited.toUser.isExist() ? inherited.toUser.get() : null;

    await upsertCubit.create(
      profile: _profile,
      subject: inherited.subject.getValue(),
      reference: inherited.reference.getValue(),
      description: inherited.description.getValue(),
      originEmployeeId: inherited.originEmployee.get(),
      type: type,
      priorityLabel: priority,
      documentTypeId: documentTypeId,
      initialToUnitId: toUnitId,
      initialToUserId:
          selectedUser != null && selectedUser.isNotEmpty ? selectedUser : null,
      initialInstruction: inherited.initialInstruction.getValue(),
      senderName: inherited.senderName.getValue(),
      senderDocument: inherited.senderDocument.getValue(),
      senderContact: inherited.senderContact.getValue(),
      originDescription: inherited.originDescription.getValue(),
      pendingAttachments: List.of(inherited.pendingAttachments),
    );
  }
}
