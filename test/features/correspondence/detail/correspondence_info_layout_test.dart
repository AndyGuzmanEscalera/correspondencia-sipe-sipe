import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/widgets/correspondence_info_section.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sample = CorrespondenceEntity(
    id: 'preview',
    uniqueNumber: 4,
    year: 2026,
    cite: 'HR-2026-000004',
    routeNumber: 'HR-2026-000004',
    type: CorrespondenceTypeCode.ce,
    priority: 'Media',
    subject:
        'Solicitud de revisión de documentación administrativa y antecedentes del trámite',
    registeredAt: DateTime.utc(2026, 10, 15, 15, 51),
    status: 'ACTIVE',
    statusLabel: 'Activa',
    documentTypeCode: 'EDIE',
    documentTypeName: 'ENCADENAMIENTO DE DOCUMENTOS INTERNOS Y EXTERNOS',
    documentNumber: '4',
    senderName: 'Remitente de prueba',
    currentUnitName: 'Secretaría Municipal Administrativa y Financiera',
    currentUserName: 'Funcionario responsable de prueba',
    createdByUsername: 'usuario.registro',
  );
  for (final width in [390.0, 768.0, 1366.0, 1870.0]) {
    testWidgets(
        'grouped detail at $width has no clipped status or overflowing long text',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
        child: CorrespondenceInfoSection(item: sample),
      ))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(StatusBadge), findsOneWidget);
      expect(
          find.text('CITE'), findsNothing); // Equal to HR: no duplicate field.
      expect(find.text(sample.documentTypeName), findsOneWidget);
      final badge = tester.getRect(find.byType(StatusBadge));
      expect(badge.top, greaterThanOrEqualTo(0));
      expect(badge.bottom, lessThan(900));
      expect(badge.right, lessThanOrEqualTo(width));
      final panel = tester.getRect(find.byType(CorrespondenceInfoSection));
      final docType = tester.getRect(find.text(sample.documentTypeName));
      expect(docType.left, greaterThanOrEqualTo(panel.left));
      expect(docType.right, lessThanOrEqualTo(panel.right));
      expect(docType.bottom, lessThanOrEqualTo(panel.bottom));
    });
  }
}
