import 'package:correspondencia_sipe_sipe/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App loads public consult screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CorrespondenciaApp());
    await tester.pumpAndSettle();

    expect(find.text('Consulta de trámite'), findsOneWidget);
    expect(find.text('Consultar trámite'), findsOneWidget);
  });
}
