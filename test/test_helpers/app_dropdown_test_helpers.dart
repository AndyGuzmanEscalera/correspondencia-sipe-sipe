import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openAppDropdown(
  WidgetTester tester, {
  int index = 0,
  Finder? scrollable,
}) async {
  final trigger = find.byIcon(Icons.search_rounded).at(index);
  if (scrollable != null) {
    await tester.scrollUntilVisible(trigger, 48, scrollable: scrollable);
  }
  await tester.pumpAndSettle();
  await tester.tap(trigger);
  await tester.pumpAndSettle();
}

Future<void> selectAppDropdownOption(
  WidgetTester tester, {
  required String optionText,
  int dropdownIndex = 0,
  String? searchQuery,
  Finder? scrollable,
}) async {
  await openAppDropdown(
    tester,
    index: dropdownIndex,
    scrollable: scrollable,
  );
  if (searchQuery != null) {
    await tester.enterText(
      find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.byType(TextField),
      ),
      searchQuery,
    );
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text(optionText).last);
  await tester.pumpAndSettle();
}
