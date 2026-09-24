import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/views/correspondence_detail_page.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/list_correspondence/cubit/correspondence_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/cubit/upsert_correspondence_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/correspondence_basic_information_section.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/correspondence_destination_section.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/correspondence_external_origin_section.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
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

  bool get _isExternal => _selectedType == CorrespondenceTypeCode.ce;

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
          return const AlertDialog(
            title: Text('Nueva correspondencia'),
            content: SizedBox(
              width: 480,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }

        if (!state.catalogReady) {
          return AlertDialog(
            title: const Text('Nueva correspondencia'),
            content: const Text(
              'No se pudieron cargar los catálogos necesarios.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          );
        }

        final isLoading = state.generalStatus == GeneralStatus.loading;
        final canSubmit = !isLoading && !state.unitUsersLoading;

        return AlertDialog(
          title: const Text('Nueva correspondencia'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Form(
                key: inherited.formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CorrespondenceBasicInformationSection(
                      documentTypes: state.documentTypes,
                      onTypeChanged: _onTypeChanged,
                    ),
                    CorrespondenceDestinationSection(
                      organizationalUnits: state.organizationalUnits,
                      unitUsers: state.unitUsers,
                      unitUsersLoading: state.unitUsersLoading,
                    ),
                    if (_isExternal)
                      const CorrespondenceExternalOriginSection(),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: canSubmit ? () => _submit(upsertCubit, inherited) : null,
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Registrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submit(
    UpsertCorrespondenceCubit upsertCubit,
    UpsertCorrespondenceInherited inherited,
  ) async {
    final validResult = inherited.valid(isExternal: _isExternal);
    if (!validResult.isPassed) return;

    final type = inherited.type.get();
    final priority = inherited.priority.get();
    final documentTypeId = inherited.documentType.get();
    final toUnitId = inherited.toUnit.get();
    if (type == null ||
        priority == null ||
        documentTypeId == null ||
        toUnitId == null ||
        toUnitId.isEmpty) {
      return;
    }

    final selectedUser =
        inherited.toUser.isExist() ? inherited.toUser.get() : null;

    await upsertCubit.create(
      subject: inherited.subject.getValue(),
      reference: inherited.reference.getValue(),
      type: type,
      priorityLabel: priority,
      documentTypeId: documentTypeId,
      initialToUnitId: toUnitId,
      initialToUserId: selectedUser != null && selectedUser.isNotEmpty
          ? selectedUser
          : null,
      initialInstruction: inherited.initialInstruction.getValue(),
      senderName: inherited.senderName.getValue(),
      senderDocument: inherited.senderDocument.getValue(),
      senderContact: inherited.senderContact.getValue(),
      originDescription: inherited.originDescription.getValue(),
    );
  }
}
