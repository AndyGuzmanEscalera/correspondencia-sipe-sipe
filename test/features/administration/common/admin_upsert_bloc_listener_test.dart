import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/administration/common/admin_upsert_bloc_listener.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminUpsertBlocListener', () {
    testWidgets('success cierra formulario antes del toast de éxito',
        (tester) async {
      final cubit = _TestUpsertCubit();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ownerContext) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: ownerContext,
                    builder: (dialogContext) {
                      return BlocProvider.value(
                        value: cubit,
                        child: AdminUpsertBlocListener<
                            _TestUpsertCubit, _TestUpsertState>(
                          hostDialogContext: dialogContext,
                          ownerContext: ownerContext,
                          child: const AlertDialog(
                            title: Text('Formulario admin'),
                          ),
                        ),
                      );
                    },
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Formulario admin'), findsOneWidget);

      cubit.emitSuccess();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Formulario admin'), findsNothing);
      expect(find.text('Éxito'), findsOneWidget);
      await cubit.close();
    });
  });
}

class _TestUpsertState extends Equatable implements StatusState {
  const _TestUpsertState({
    this.generalStatus = GeneralStatus.initial,
    this.dialogMessage = const DialogMessage.empty(),
  });

  @override
  final GeneralStatus generalStatus;

  @override
  final DialogMessage dialogMessage;

  @override
  List<Object?> get props => [generalStatus, dialogMessage];
}

class _TestUpsertCubit extends Cubit<_TestUpsertState> {
  _TestUpsertCubit() : super(const _TestUpsertState());

  void emitSuccess() {
    emit(
      const _TestUpsertState(
        generalStatus: GeneralStatus.success,
        dialogMessage: DialogMessage(
          title: 'Éxito',
          message: 'Guardado',
        ),
      ),
    );
  }
}
