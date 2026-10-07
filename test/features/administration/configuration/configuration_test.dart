import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/presentation/widget/responsive_breakpoints.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/configuration/cubit/configuration_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/configuration/views/configuration_page.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_dropdown.dart';
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
const _other = AuthorityEmployee(
    employeeId: 'employee-b',
    employeeName: 'Nueva Autoridad',
    positionName: 'Responsable Institucional',
    unitName: 'Secretaría',
    documentNumber: '987654');

class _Auth extends Fake implements AuthenticationRepository {}

class _Settings extends Fake implements SystemSettingsAdminRepository {
  Result<InstitutionalSettings, Failure> result = const Ok(
      InstitutionalSettings(mayorEmployeeId: 'employee-a', mayor: _authority));
  String? saved;
  int calls = 0;
  int candidateCalls = 0;
  @override
  Future<Result<InstitutionalSettings, Failure>>
      getInstitutionalSettings() async => result;
  @override
  Future<Result<List<AuthorityEmployee>, Failure>>
      getAuthorityEmployees() async {
    candidateCalls++;
    return const Ok([_authority, _other]);
  }

  @override
  Future<Result<InstitutionalSettings, Failure>> updateInstitutionalSettings(
      {required String? mayorEmployeeId}) async {
    calls++;
    saved = mayorEmployeeId;
    if (result is Err) return result;
    return Ok(InstitutionalSettings(
        mayorEmployeeId: mayorEmployeeId,
        mayor: mayorEmployeeId == _other.employeeId ? _other : _authority));
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
  test('guardar referencia y conservar validación de dominio', () async {
    final repository = _Settings();
    final cubit = ConfigurationCubit(repository);
    await cubit.load(canManage: true);
    cubit.selectMayor(_other);
    await cubit.save();
    expect(repository.saved, 'employee-b');
    expect(cubit.state.settings.mayor, _other);
    repository.result = const Err(ValidationFailure('Funcionario inactivo'));
    await cubit.save();
    expect(cubit.state.generalStatus, GeneralStatus.error);
    expect(cubit.state.dialogMessage.message, 'Funcionario inactivo');
    await cubit.close();
  });
  for (final manage in [false, true]) {
    testWidgets('configuración manage=$manage respeta permissions',
        (tester) async {
      final repository = _Settings();
      await _pump(tester, repository, manage: manage);
      expect(find.text('Autoridad Actual'), findsOneWidget);
      expect(find.text('Dirección Ejecutiva · Despacho'), findsOneWidget);
      final dropdown = tester.widget<AppDropdown<AuthorityEmployee>>(
          find.byType(AppDropdown<AuthorityEmployee>));
      expect(dropdown.enabled, manage);
      expect(repository.candidateCalls, manage ? 1 : 0);
      expect(find.text('Guardar'), manage ? findsOneWidget : findsNothing);
      if (!manage) {
        await tester.tap(find.byIcon(Icons.search_rounded));
        await tester.pumpAndSettle();
        expect(find.byType(DraggableScrollableSheet), findsNothing);
      }
    });
  }
  for (final query in [
    'Nueva Autoridad',
    '987654',
    'Responsable Institucional',
    'Secretaría'
  ]) {
    testWidgets('buscar funcionario por $query y guardar ID', (tester) async {
      final repository = _Settings();
      await _pump(tester, repository);
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.descendant(
              of: find.byType(DraggableScrollableSheet),
              matching: find.byType(TextField)),
          query);
      await tester.pumpAndSettle();
      final option = find.byWidgetPredicate(
          (widget) => widget is Text && widget.data == 'Nueva Autoridad');
      expect(option, findsOneWidget);
      await tester.tap(option);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(repository.saved, 'employee-b');
      expect(repository.calls, 1);
    });
  }
  testWidgets('sin autoridad muestra instrucción clara', (tester) async {
    final repository = _Settings()..result = const Ok(InstitutionalSettings());
    await _pump(tester, repository);
    expect(
        find.text(
            'Debe configurar al Alcalde/Máxima Autoridad Ejecutiva antes de registrar documentos EDIE.'),
        findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });
}
