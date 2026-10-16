import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/widgets/side_menu_widget.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/app_form_dialog.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final isDialog in [true, false]) {
    testWidgets(
        'desktop ${isDialog ? "dialog" : "sidebar"} scrolls with an unattached primary controller',
        (tester) async {
      tester.view.physicalSize = const Size(1366, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final unusedPrimary = ScrollController();
      final cubit = SideMenuCubit()..init();
      addTearDown(unusedPrimary.dispose);
      addTearDown(cubit.close);
      final content = isDialog
          ? AppFormDialog(
              title: 'Formulario de correspondencia',
              child:
                  Column(children: List.generate(50, (i) => Text('Campo $i'))),
            )
          : const SideMenuWidget();
      Widget app() => MaterialApp(
            theme: ThemeData(
              platform: TargetPlatform.windows,
              scrollbarTheme: const ScrollbarThemeData(
                thumbVisibility: WidgetStatePropertyAll(true),
              ),
            ),
            home: Scaffold(
              body: PrimaryScrollController(
                controller: unusedPrimary,
                child: BlocProvider.value(value: cubit, child: content),
              ),
            ),
          );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(unusedPrimary.hasClients, isFalse);
      final scroll = find.byType(isDialog ? SingleChildScrollView : ListView);
      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await pointer.addPointer(location: tester.getCenter(scroll));
      await tester.pump();
      await tester.sendEventToBinding(PointerScrollEvent(
        position: tester.getCenter(scroll),
        scrollDelta: const Offset(0, 180),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Rebuild during form/menu updates, then remove the route/widget.
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await pointer.removePointer();
    });
  }
}
