import 'package:correspondencia_sipe_sipe/shared/widgets/official_logo.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final compact in [false, true]) {
    for (final white in [false, true]) {
      testWidgets(
          'official logo compact=$compact white=$white preserves image and semantics',
          (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(MaterialApp(
            home:
                Scaffold(body: OfficialLogo(compact: compact, white: white))));
        await tester.pumpAndSettle();
        final image = tester.widget<Image>(find.byType(Image));
        expect((image.image as AssetImage).assetName,
            'assets/branding/sipe_sipe_${compact ? 'crest' : 'horizontal'}${white ? '_white' : ''}.png');
        expect(image.fit, BoxFit.contain);
        expect(image.color, isNull);
        expect(
            find.bySemanticsLabel(
                'Escudo oficial del ${OfficialLogo.institution}'),
            findsOneWidget);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      });
    }
  }
  test('official green matches source and white text meets AA contrast', () {
    expect(UiColors.primary, const Color(0xFF08813A));
    final contrast = (Colors.white.computeLuminance() + .05) /
        (UiColors.primary.computeLuminance() + .05);
    expect(contrast, greaterThanOrEqualTo(4.5));
  });
}
