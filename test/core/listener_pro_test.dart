import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class TestState implements StatusState {
  const TestState(this.generalStatus, this.dialogMessage);
  @override
  final GeneralStatus generalStatus;
  @override
  final DialogMessage dialogMessage;
}

class TestCubit extends Cubit<TestState> {
  TestCubit()
      : super(const TestState(GeneralStatus.initial, DialogMessage.empty()));
  void change(GeneralStatus status, {bool loading = true}) => emit(TestState(
      status, DialogMessage(message: 'Resultado', showLoading: loading)));
}

void main() {
  for (final status in [GeneralStatus.error, GeneralStatus.success]) {
    for (final loading in [false, true]) {
      testWidgets(
          '$status cierra sólo su loading (opened=$loading) y conserva formulario',
          (tester) async {
        final cubit = TestCubit();
        addTearDown(cubit.close);
        late StateSetter rebuild;
        await tester.pumpWidget(MaterialApp(
            home: Builder(
                builder: (context) => ElevatedButton(
                    onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) =>
                            StatefulBuilder(builder: (context, setState) {
                              rebuild = setState;
                              return BlocProvider.value(
                                  value: cubit,
                                  child: MultiBlocListener(
                                      listeners: [
                                        ListenerPro<TestCubit, TestState>()
                                            .listen()
                                      ],
                                      child: const AlertDialog(
                                          title: Text('Formulario'))));
                            })),
                    child: const Text('Abrir')))));
        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();
        cubit.change(GeneralStatus.loading, loading: loading);
        await tester.pump();
        rebuild(() {});
        await tester.pump();
        cubit.change(status);
        await tester.pumpAndSettle();
        expect(find.text('Formulario'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Resultado'), findsOneWidget);
        await tester.tap(find.text('Cerrar'));
        await tester.pumpAndSettle();
        expect(find.text('Formulario'), findsOneWidget);
      });
    }
    testWidgets('$status inicial no cierra el formulario', (tester) async {
      final cubit = TestCubit();
      addTearDown(cubit.close);
      await tester.pumpWidget(MaterialApp(
          home: Builder(
              builder: (context) => ElevatedButton(
                  onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => BlocProvider.value(
                          value: cubit,
                          child: MultiBlocListener(
                              listeners: [
                                ListenerPro<TestCubit, TestState>().listen()
                              ],
                              child: const AlertDialog(
                                  title: Text('Formulario'))))),
                  child: const Text('Abrir')))));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      cubit.change(status);
      await tester.pumpAndSettle();
      expect(find.text('Formulario'), findsOneWidget);
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();
      expect(find.text('Formulario'), findsOneWidget);
    });
  }
}
