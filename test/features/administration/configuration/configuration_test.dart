import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/presentation/widget/responsive_breakpoints.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/configuration/cubit/configuration_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/configuration/views/configuration_page.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Auth extends Fake implements AuthenticationRepository {}
class _Settings extends Fake implements SystemSettingsAdminRepository {
  Result<InstitutionalSettings, Failure> result = const Ok(InstitutionalSettings(mayorDisplayName: 'Titular'));
  String? saved;
  int calls = 0;
  @override
  Future<Result<InstitutionalSettings, Failure>> getInstitutionalSettings() async => result;
  @override
  Future<Result<InstitutionalSettings, Failure>> updateInstitutionalSettings({required String? mayorDisplayName}) async {
    calls++;
    saved = mayorDisplayName;
    return result;
  }
}
void main() {
  test('load y save normalizan vacío sin perder el pipeline de Failure', () async {
    final repository = _Settings();
    final cubit = ConfigurationCubit(repository);
    await cubit.load();
    expect(cubit.state.loaded, isTrue);
    expect(cubit.state.mayorDisplayName, 'Titular');
    await cubit.save('   ');
    expect(repository.saved, isNull);
    repository.result = const Err(ValidationFailure('Dato inválido'));
    await cubit.save('Otro');
    expect(cubit.state.generalStatus, GeneralStatus.error);
    expect(cubit.state.dialogMessage.message, 'Dato inválido');
    await cubit.close();
  });
  for (final manage in [false, true]) {
    testWidgets('configuración manage=$manage respeta permissions', (tester) async {
      final repository = _Settings();
      final cubit = ConfigurationCubit(repository);
      final session = AppSessionCubit(authRepository: _Auth());
      session.onSignedIn(UserSession(id: 'custom', username: 'custom', isActive: true,
          permissions: [Permissions.systemSettingsRead, if (manage) Permissions.systemSettingsManage]));
      addTearDown(cubit.close);
      addTearDown(session.close);
      await tester.pumpWidget(MultiBlocProvider(providers: [
        BlocProvider<ConfigurationCubit>.value(value: cubit),
        BlocProvider<AppSessionCubit>.value(value: session),
      ], child: const MaterialApp(builder: ResponsiveBreakpointsConfig.builder, home: Scaffold(body: Column(children: [ConfigurationView()])))));
      await tester.pumpAndSettle();
      expect(find.text('Titular'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).readOnly, !manage);
      expect(find.text('Guardar'), manage ? findsOneWidget : findsNothing);
      if (manage) {
        await tester.enterText(find.byType(TextFormField), ' Nuevo ');
        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle();
        expect(repository.saved, 'Nuevo');
        expect(repository.calls, 1);
      }
    });
  }
}
