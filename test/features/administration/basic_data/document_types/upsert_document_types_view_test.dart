import 'dart:async';

import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/document_types/list_document_types/cubit/document_types_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/document_types/upsert_document_types/cubit/upsert_document_types_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/document_types/upsert_document_types/helpers/upsert_document_types_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/document_types/upsert_document_types/views/upsert_document_types_view.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpsertDocumentTypesView', () {
    late _TrackingDocumentTypesCubit listCubit;
    late _FakeDocumentTypesAdminRepository repository;

    setUp(() {
      listCubit = _TrackingDocumentTypesCubit(_FakeListRepository());
      repository = _FakeDocumentTypesAdminRepository();
    });

    tearDown(() async {
      await listCubit.close();
    });

    Future<void> pumpUpsertDialog(
      WidgetTester tester, {
      required TypeOperation typeOperation,
      DocumentTypeAdmin? selected,
    }) async {
      if (selected != null) {
        listCubit.changeSelected(selected);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<DocumentTypesCubit>.value(
            value: listCubit,
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (dialogContext) =>
                            BlocProvider<DocumentTypesCubit>.value(
                          value: listCubit,
                          child: UpsertDocumentTypesInherited(
                            typeOperation: typeOperation,
                            child: BlocProvider(
                              create: (_) =>
                                  UpsertDocumentTypesCubit(repository),
                              child: UpsertDocumentTypesView(
                                hostDialogContext: dialogContext,
                                ownerContext: context,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('create dialog muestra formulario vacío y code editable',
        (tester) async {
      await pumpUpsertDialog(tester, typeOperation: TypeOperation.create);

      expect(find.text('Nuevo tipo de documento'), findsOneWidget);
      expect(find.text('Registrar'), findsOneWidget);

      final codeField = tester.widget<AppTextField>(
        find.byType(AppTextField).first,
      );
      expect(codeField.readOnly, isFalse);
      expect(find.byType(TextFormField).at(0), findsOneWidget);
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField).at(0)).controller?.text,
        isEmpty,
      );
    });

    testWidgets('update dialog precarga setData y code es readonly',
        (tester) async {
      await pumpUpsertDialog(
        tester,
        typeOperation: TypeOperation.update,
        selected: _entity,
      );

      expect(find.text('Editar tipo de documento'), findsOneWidget);
      expect(find.text('CARTA'), findsOneWidget);
      expect(find.text('Carta'), findsOneWidget);

      final codeField = tester.widget<AppTextField>(
        find.byType(AppTextField).first,
      );
      expect(codeField.readOnly, isTrue);
    });

    testWidgets('error 409 mantiene el formulario abierto', (tester) async {
      repository.createResult = const Err(
        ValidationFailure(
          'Ya existe un tipo de documento con el código indicado.',
        ),
      );

      await pumpUpsertDialog(tester, typeOperation: TypeOperation.create);

      await tester.enterText(find.byType(TextFormField).at(0), 'CARTA');
      await tester.enterText(find.byType(TextFormField).at(1), 'Carta');
      await tester.tap(find.text('Registrar'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Nuevo tipo de documento'), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
      expect(
        find.text('Ya existe un tipo de documento con el código indicado.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo tipo de documento'), findsOneWidget);
      expect(find.text('Registrar'), findsOneWidget);
    });

    testWidgets('success refresca listado y cierra upsert al confirmar éxito',
        (tester) async {
      await pumpUpsertDialog(tester, typeOperation: TypeOperation.create);

      await tester.enterText(find.byType(TextFormField).at(0), 'MEMO');
      await tester.enterText(find.byType(TextFormField).at(1), 'Memorando');
      await tester.tap(find.text('Registrar'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(listCubit.getCallCount, 1);
      expect(find.text('Nuevo tipo de documento'), findsNothing);
      expect(find.text('Éxito'), findsOneWidget);
    });

    testWidgets('mobile 390px renderiza sin overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpUpsertDialog(tester, typeOperation: TypeOperation.create);

      expect(find.text('Nuevo tipo de documento'), findsOneWidget);
      expect(find.text('Registrar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('loading deshabilita submit', (tester) async {
      final createGate = Completer<void>();
      repository.createGate = createGate;

      await pumpUpsertDialog(tester, typeOperation: TypeOperation.create);

      await tester.enterText(find.byType(TextFormField).at(0), 'MEMO');
      await tester.enterText(find.byType(TextFormField).at(1), 'Memorando');
      await tester.tap(find.text('Registrar'));
      await tester.pump();

      expect(
        tester
            .widgetList<ElevatedButton>(find.byType(ElevatedButton))
            .last
            .onPressed,
        isNull,
      );

      createGate.complete();
      await tester.pumpAndSettle();
    });
  });
}

final _entity = DocumentTypeAdmin(
  id: 'dt-1',
  code: 'CARTA',
  name: 'Carta',
  isActive: true,
  createdAt: _date,
  updatedAt: _date,
);

final _date = DateTime.utc(2026, 1, 1);

class _TrackingDocumentTypesCubit extends DocumentTypesCubit {
  _TrackingDocumentTypesCubit(super.repository);

  int getCallCount = 0;

  @override
  Future<void> get() async {
    getCallCount++;
  }
}

class _FakeListRepository implements DocumentTypesAdminRepository {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDocumentTypesAdminRepository
    implements DocumentTypesAdminRepository {
  Result<DocumentTypeAdmin, Failure>? createResult;
  Completer<void>? createGate;

  @override
  Future<Result<DocumentTypeAdmin, Failure>> create(
    DocumentTypeInput input,
  ) async {
    if (createGate != null) await createGate!.future;
    return createResult ??
        Ok(
          DocumentTypeAdmin(
            id: 'dt-new',
            code: input.code,
            name: input.name,
            isActive: true,
            createdAt: _date,
            updatedAt: _date,
          ),
        );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
