import 'package:correspondencia_sipe_sipe/features/administration/common/admin_active_filter.dart';
import 'package:correspondencia_sipe_sipe/features/administration/common/admin_logical_delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'filtro envía true, false y null; desactivación requiere confirmación',
      (tester) async {
    final filters = <bool?>[];
    bool? confirmed;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Column(children: [
      AdminActiveFilter(onChanged: filters.add),
      Builder(
          builder: (context) => TextButton(
              onPressed: () async {
                confirmed = await confirmAdminLogicalDelete(context,
                    title: 'Desactivar', message: 'Conserva su historial');
              },
              child: const Text('Abrir'))),
    ]))));
    for (final label in ['Inactivos', 'Todos', 'Activos']) {
      await tester.tap(find
          .byWidgetPredicate((widget) => widget is DropdownButtonFormField));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }
    expect(filters, [false, null, true]);
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(confirmed, isFalse);
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desactivar').last);
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
  });
}
