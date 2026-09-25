import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/platform/file_download_service.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/attachments/cubit/correspondence_attachments_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/attachments/views/correspondence_attachments_page.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/attachments/widgets/correspondence_attachments_list.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingFileDownloadService implements FileDownloadService {
  @override
  Future<void> downloadBytes({
    required String filename,
    required List<int> bytes,
    String? mimeType,
  }) async {}

  @override
  Future<void> openPdfInNewTab({
    required List<int> bytes,
    String? title,
  }) async {}
}

class _FakeCorrespondenceRepository implements repo.CorrespondenceRepository {
  _FakeCorrespondenceRepository({this.attachments = const []});

  List<repo.CorrespondenceAttachment> attachments;

  @override
  Future<Result<List<repo.CorrespondenceAttachment>, Failure>>
      listAttachments(String correspondenceId) async {
    return Ok(attachments);
  }

  @override
  Future<Result<List<int>, Failure>> downloadAttachment({
    required String correspondenceId,
    required String attachmentId,
  }) async {
    return const Ok([1, 2, 3]);
  }

  @override
  Future<Result<repo.CorrespondenceAttachment, Failure>> deactivateAttachment({
    required String correspondenceId,
    required String attachmentId,
  }) async {
    attachments = attachments.where((item) => item.id != attachmentId).toList();
    return Ok(
      repo.CorrespondenceAttachment(
        id: attachmentId,
        correspondenceId: correspondenceId,
        isActive: false,
        createdByUserId: 'user-1',
        createdAt: DateTime.utc(2026, 1, 15),
      ),
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CorrespondenceAttachmentsCubit _buildCubit({
  required _FakeCorrespondenceRepository repository,
}) {
  return CorrespondenceAttachmentsCubit(
    repository: repository,
    correspondenceId: 'corr-1',
    fileDownloadService: _RecordingFileDownloadService(),
  );
}

void main() {
  group('CorrespondenceAttachments widgets', () {
    testWidgets('lista vacía no renderiza filas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CorrespondenceAttachmentsList(
              attachments: const [],
              downloadingAttachmentId: null,
              deactivatingAttachmentId: null,
            ),
          ),
        ),
      );

      expect(find.byType(CorrespondenceAttachmentsList), findsOneWidget);
      expect(find.text('No hay adjuntos registrados.'), findsNothing);
    });

    testWidgets('vista vacía muestra mensaje y botón agregar', (tester) async {
      final cubit = _buildCubit(
        repository: _FakeCorrespondenceRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: const CorrespondenceAttachmentsView(),
            ),
          ),
        ),
      );
      await cubit.init();
      await tester.pumpAndSettle();

      expect(find.text('No hay adjuntos registrados.'), findsOneWidget);
      expect(find.text('Agregar archivos'), findsOneWidget);
      await cubit.close();
    });

    testWidgets('lista muestra adjuntos recién creados al montar', (tester) async {
      final repository = _FakeCorrespondenceRepository(
        attachments: [
          repo.CorrespondenceAttachment(
            id: 'att-1',
            correspondenceId: 'corr-1',
            originalFilename: 'recien-subido.pdf',
            mimeType: 'application/pdf',
            sizeBytes: 2048,
            isActive: true,
            createdByUserId: 'user-1',
            createdByUsername: 'admin',
            createdAt: DateTime.utc(2026, 1, 15, 10, 30),
          ),
        ],
      );
      final cubit = _buildCubit(repository: repository);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: const CorrespondenceAttachmentsView(),
            ),
          ),
        ),
      );

      await cubit.init();
      await tester.pumpAndSettle();

      expect(find.text('recien-subido.pdf'), findsOneWidget);
      expect(find.text('Agregar archivos'), findsOneWidget);
      await cubit.close();
    });

    testWidgets('delete confirmation aparece antes de quitar', (tester) async {
      final repository = _FakeCorrespondenceRepository(
        attachments: [
          repo.CorrespondenceAttachment(
            id: 'att-1',
            correspondenceId: 'corr-1',
            originalFilename: 'informe.pdf',
            isActive: true,
            createdByUserId: 'user-1',
            createdAt: DateTime.utc(2026, 1, 15),
          ),
        ],
      );
      final cubit = _buildCubit(repository: repository);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: const CorrespondenceAttachmentsView(),
            ),
          ),
        ),
      );
      await cubit.init();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Quitar adjunto'));
      await tester.pumpAndSettle();

      expect(find.text('Quitar adjunto'), findsWidgets);
      await tester.tap(find.widgetWithText(FilledButton, 'Quitar adjunto'));
      await tester.pumpAndSettle();

      expect(find.text('informe.pdf'), findsNothing);
      await cubit.close();
    });

    testWidgets('mobile 390px renderiza cards responsivas', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = _FakeCorrespondenceRepository(
        attachments: [
          repo.CorrespondenceAttachment(
            id: 'att-1',
            correspondenceId: 'corr-1',
            originalFilename: 'mobile.pdf',
            mimeType: 'application/pdf',
            sizeBytes: 1024,
            isActive: true,
            createdByUserId: 'user-1',
            createdAt: DateTime.utc(2026, 1, 15),
          ),
        ],
      );
      final cubit = _buildCubit(repository: repository);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: const CorrespondenceAttachmentsView(),
            ),
          ),
        ),
      );
      await cubit.init();
      await tester.pumpAndSettle();

      expect(find.text('mobile.pdf'), findsOneWidget);
      expect(find.text('Descargar'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await cubit.close();
    });
  });
}
