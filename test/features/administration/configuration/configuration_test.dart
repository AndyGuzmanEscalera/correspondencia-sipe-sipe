import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/presentation/widget/responsive_breakpoints.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/configuration/cubit/configuration_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/configuration/views/configuration_page.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_dropdown.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

const _authority = AuthorityEmployee(
    employeeId: 'employee-a',
    employeeName: 'Autoridad Actual',
    positionName: 'Dirección Ejecutiva',
    unitName: 'Despacho',
    documentNumber: '123456');

class _Auth extends Fake implements AuthenticationRepository {}

class _Settings extends Fake implements SystemSettingsAdminRepository {
  Result<InstitutionalSettings, Failure> result = const Ok(
      InstitutionalSettings(
          mayorEmployeeId: 'employee-a',
          mayor: _authority,
          institutionalEmail: 'actual@sipesipe.gob.bo'));
  String? saved;
  String? savedText;
  String? savedEmail;
  List<String>? savedRecipients;
  int calls = 0;
  int candidateCalls = 0;
  List<AuthorityEmployee> candidates = const [_authority];
  @override
  Future<Result<InstitutionalSettings, Failure>>
      getInstitutionalSettings() async => result;
  @override
  Future<Result<List<AuthorityEmployee>, Failure>>
      getAuthorityEmployees() async {
    candidateCalls++;
    return Ok(candidates);
  }

  @override
  Future<Result<List<OrganizationalUnit>, Failure>> getIntakeUnits() async =>
      const Ok([]);
  @override
  Future<Result<InstitutionalSettings, Failure>> updateInstitutionalSettings(
      {required String? mayorEmployeeId,
      String? mayorDisplayName,
      String? institutionalEmail,
      String? intakeUnitId,
      List<String>? initialRecipientEmployeeIds}) async {
    calls++;
    saved = mayorEmployeeId;
    savedText = mayorDisplayName;
    savedEmail = institutionalEmail;
    savedRecipients = initialRecipientEmployeeIds;
    if (result is Err) return result;
    return Ok(InstitutionalSettings(
        mayorEmployeeId: mayorEmployeeId,
        mayor: _authority,
        institutionalEmail: institutionalEmail,
        mayorDisplayName: mayorDisplayName));
  }
}

Future<void> _pump(WidgetTester tester, _Settings repository,
    {bool manage = true}) async {
  final cubit = ConfigurationCubit(repository);
  final session = AppSessionCubit(authRepository: _Auth());
  session.onSignedIn(UserSession(
      id: 'custom',
      username: 'custom',
      isActive: true,
      permissions: [
        Permissions.systemSettingsRead,
        if (manage) Permissions.systemSettingsManage
      ]));
  addTearDown(cubit.close);
  addTearDown(session.close);
  await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider<ConfigurationCubit>.value(value: cubit),
        BlocProvider<AppSessionCubit>.value(value: session),
      ],
      child: const MaterialApp(
          builder: ResponsiveBreakpointsConfig.builder,
          home: Scaffold(body: Column(children: [ConfigurationView()])))));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'correo institucional carga valor existente y guarda cambios con trim',
      (tester) async {
    final repository = _Settings();
    await _pump(tester, repository);
    final email = find.byKey(const Key('institutional-email'));
    expect(tester.widget<TextFormField>(email).controller!.text,
        'actual@sipesipe.gob.bo');
    await tester.ensureVisible(email);
    await tester.enterText(email, '  nuevo@sipesipe.gob.bo  ');
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(repository.savedEmail, 'nuevo@sipesipe.gob.bo');
    expect(find.text('COMUNICACIONES'), findsOneWidget);
  });

  testWidgets('correo invalido impide guardar y vacio esta permitido',
      (tester) async {
    final repository = _Settings();
    await _pump(tester, repository);
    final email = find.byKey(const Key('institutional-email'));
    await tester.ensureVisible(email);
    await tester.enterText(email, 'correo invalido');
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(repository.calls, 0);
    expect(find.text('Ingrese un correo institucional válido'), findsOneWidget);
    await tester.ensureVisible(email);
    await tester.enterText(email, '');
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(repository.savedEmail, '');
  });

  testWidgets('selecciona dos receptores desde el buscador y los guarda',
      (tester) async {
    const second = AuthorityEmployee(
        employeeId: 'employee-b',
        employeeName: 'Receptor Prueba B',
        positionName: 'Secretaría',
        unitName: 'Despacho');
    final repository = _Settings()..candidates = const [_authority, second];
    await _pump(tester, repository);
    for (final employee in repository.candidates) {
      final dropdown = find.byWidgetPredicate((widget) =>
          widget is AppDropdown<AuthorityEmployee> &&
          widget.label == 'Receptores iniciales de Alcaldía');
      final search = find.descendant(
          of: dropdown, matching: find.byIcon(Icons.search_rounded));
      await tester.ensureVisible(search);
      await tester.tap(search);
      await tester.pumpAndSettle();
      await tester.tap(find.text(employee.employeeName).last);
      await tester.pumpAndSettle();
    }
    expect(find.byType(InputChip), findsNWidgets(2));
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(repository.savedRecipients, ['employee-a', 'employee-b']);
  });

  testWidgets('texto y funcionario se muestran y guardan por separado',
      (tester) async {
    final repository = _Settings();
    await _pump(tester, repository);
    await tester.enterText(
        find.descendant(
            of: find.byWidgetPredicate((w) =>
                w is AppTextField &&
                w.label == 'Texto de la Máxima Autoridad para documentos'),
            matching: find.byType(TextFormField)),
        '  Fredy Patzi Barrios  ');
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(repository.savedText, 'Fredy Patzi Barrios');
    expect(repository.saved, 'employee-a');
    expect(repository.candidateCalls, 1);
    expect(find.byType(AppDropdown<AuthorityEmployee>), findsNWidgets(2));
    expect(find.text('Máxima autoridad institucional'), findsOneWidget);
    expect(find.text('Texto de la Máxima Autoridad para documentos'),
        findsOneWidget);
  });
  for (final manage in [false, true]) {
    testWidgets('texto institucional manage=$manage respeta permissions',
        (tester) async {
      final repository = _Settings();
      await _pump(tester, repository, manage: manage);
      expect(tester.widget<TextField>(find.byType(TextField).last).readOnly,
          !manage);
      expect(repository.candidateCalls, manage ? 1 : 0);
      expect(
          tester
              .widget<AppDropdown<AuthorityEmployee>>(
                  find.byType(AppDropdown<AuthorityEmployee>).last)
              .enabled,
          manage);
      expect(find.text('Guardar'), manage ? findsOneWidget : findsNothing);
    });
  }
  test('rechazo de guardado conserva validación de dominio', () async {
    final repository = _Settings();
    final cubit = ConfigurationCubit(repository);
    await cubit.load();
    repository.result = const Err(ValidationFailure('Texto inválido'));
    await cubit.save(mayorDisplayName: 'Autoridad');
    expect(cubit.state.generalStatus, GeneralStatus.error);
    expect(cubit.state.dialogMessage.message, 'Texto inválido');
    await cubit.close();
  });
}
