import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/derive_correspondence/cubit/derive_correspondence_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/derive_correspondence/helpers/derive_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/derive_correspondence/widgets/derive_correspondence_form_section.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/cubit/correspondence_detail_cubit.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeriveCorrespondencePage extends StatelessWidget {
  const DeriveCorrespondencePage({
    required this.correspondenceId,
    this.scrollable = true,
    super.key,
  });

  final String correspondenceId;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return DeriveCorrespondenceInherited(
      child: BlocProvider(
        create: (_) => getIt<DeriveCorrespondenceCubit>(
          param1: correspondenceId,
        ),
        child: DeriveCorrespondenceView(scrollable: scrollable),
      ),
    );
  }
}

class DeriveCorrespondenceView extends StatelessWidget {
  const DeriveCorrespondenceView({
    this.scrollable = true,
    super.key,
  });

  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final deriveCubit = context.read<DeriveCorrespondenceCubit>();

    return MultiBlocListener(
      listeners: [
        ListenerPro<DeriveCorrespondenceCubit, DeriveCorrespondenceState>()
            .listen(
          onPressedSuccess: () {
            DeriveCorrespondenceInherited.of(context).clear();
          },
        ),
        ListenerPro<DeriveCorrespondenceCubit, DeriveCorrespondenceState>()
            .event(
          onSuccess: (_) {
            context.read<CorrespondenceDetailCubit>().refresh();
          },
        ),
      ],
      child: FullWidgetGeneric(
        onInit: () {
          DeriveCorrespondenceInherited.of(context).clear();
          deriveCubit.init();
        },
        onDispose: DeriveCorrespondenceInherited.of(context).dispose,
        child: DeriveCorrespondenceBody(scrollable: scrollable),
      ),
    );
  }
}

class DeriveCorrespondenceBody extends StatelessWidget {
  const DeriveCorrespondenceBody({
    this.scrollable = true,
    super.key,
  });

  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final inherited = DeriveCorrespondenceInherited.of(context);
    final deriveCubit = context.read<DeriveCorrespondenceCubit>();

    return BlocBuilder<DeriveCorrespondenceCubit, DeriveCorrespondenceState>(
      builder: (context, state) {
        if (!state.catalogLoaded) {
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (!state.catalogReady) {
          return const Text(
            'No hay unidades organizacionales activas disponibles.',
          );
        }

        final isLoading = state.generalStatus == GeneralStatus.loading;
        final canSubmit = !isLoading && !state.unitUsersLoading;

        final form = Form(
          key: inherited.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DeriveCorrespondenceFormSection(
                organizationalUnits: state.organizationalUnits,
                unitUsers: state.unitUsers,
                unitUsersLoading: state.unitUsersLoading,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed:
                      canSubmit ? () => _submit(deriveCubit, inherited) : null,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.forward_rounded),
                  label: const Text('Derivar'),
                ),
              ),
            ],
          ),
        );

        if (!scrollable) {
          return form;
        }

        return SingleChildScrollView(child: form);
      },
    );
  }

  Future<void> _submit(
    DeriveCorrespondenceCubit deriveCubit,
    DeriveCorrespondenceInherited inherited,
  ) async {
    final validResult = inherited.valid();
    if (!validResult.isPassed) return;

    final unitId = inherited.toUnit.get();
    if (unitId == null || unitId.isEmpty) return;

    final selectedUser =
        inherited.toUser.isExist() ? inherited.toUser.get() : null;

    await deriveCubit.derive(
      toUnitId: unitId,
      toUserId: selectedUser != null && selectedUser.isNotEmpty
          ? selectedUser
          : null,
      instruction: inherited.instruction.getValue(),
      observation: inherited.observation.getValue(),
    );
  }
}
