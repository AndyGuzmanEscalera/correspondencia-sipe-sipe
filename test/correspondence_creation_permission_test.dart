import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/theme/app_theme.dart';
import 'package:correspondencia_sipe_sipe/core/presentation/widget/responsive_breakpoints.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/list_correspondence/cubit/correspondence_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/list_correspondence/views/correspondence_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Auth extends Fake implements AuthenticationRepository {}

class _Correspondence extends Fake implements CorrespondenceRepository {}

void main() {
  for (final example in <(bool, bool, bool)>[
    (false, true, false),
    (true, true, true),
    (true, false, false)
  ]) {
    testWidgets('Creación exige permission y funcionario: $example',
        (tester) async {
      final session = AppSessionCubit(authRepository: _Auth());
      final list = CorrespondenceCubit(_Correspondence());
      addTearDown(session.close);
      addTearDown(list.close);
      session.onSignedIn(UserSession(
          id: 'custom',
          username: 'custom',
          isActive: true,
          roles: const ['ADMIN'],
          employeeId: example.$2 ? 'employee' : null,
          permissions: [if (example.$1) 'correspondence.create']));
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light,
          builder: ResponsiveBreakpointsConfig.builder,
          home: Scaffold(
              body: Column(children: [
            MultiBlocProvider(providers: [
              BlocProvider.value(value: session),
              BlocProvider.value(value: list)
            ], child: const CorrespondenceBody())
          ]))));
      await tester.pumpAndSettle();
      expect(find.text('Nueva correspondencia'),
          example.$3 ? findsOneWidget : findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
