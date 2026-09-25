import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/inbox/cubit/sent_entry_cubit.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCorrespondenceRepository implements repo.CorrespondenceRepository {
  _FakeCorrespondenceRepository({
    this.sentResult,
    this.sentCountResult,
  });

  Result<repo.CorrespondencePage, Failure>? sentResult;
  Result<repo.SentCount, Failure>? sentCountResult;

  int? lastSentPage;
  int? lastSentPageSize;
  String? lastSentSearch;
  int sentCalls = 0;
  int sentCountCalls = 0;

  @override
  Future<Result<repo.CorrespondencePage, Failure>> getSent({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  }) async {
    sentCalls++;
    lastSentPage = page;
    lastSentPageSize = pageSize;
    lastSentSearch = search;
    return sentResult ??
        Ok(
          repo.CorrespondencePage(
            items: const [],
            page: page,
            pageSize: pageSize,
            total: 0,
            totalPages: 0,
          ),
        );
  }

  @override
  Future<Result<repo.SentCount, Failure>> getSentCount() async {
    sentCountCalls++;
    return sentCountResult ?? const Ok(repo.SentCount(total: 0));
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

repo.Correspondence _sampleSentCorrespondence() {
  return repo.Correspondence(
    id: 'corr-sent-1',
    routeNumber: 'HR-2026-000010',
    routeYear: 2026,
    routeSequence: 10,
    correspondenceType: 'EXTERNAL',
    documentTypeCode: 'CARTA',
    documentTypeName: 'Carta',
    subject: 'Enviado',
    priority: 'LOW',
    status: 'ACTIVE',
    registeredAt: DateTime.utc(2026, 1, 15),
    lastSentAt: DateTime.utc(2026, 1, 16, 12, 30),
  );
}

void main() {
  group('SentEntryCubit', () {
    test('init carga sent y count', () async {
      final repository = _FakeCorrespondenceRepository(
        sentResult: Ok(
          repo.CorrespondencePage(
            items: [_sampleSentCorrespondence()],
            page: 1,
            pageSize: 20,
            total: 1,
            totalPages: 1,
          ),
        ),
        sentCountResult: const Ok(repo.SentCount(total: 12)),
      );
      final cubit = SentEntryCubit(repository);

      await cubit.init();

      expect(cubit.state.items.single.routeNumber, 'HR-2026-000010');
      expect(cubit.state.items.single.lastSentAt, isNotNull);
      expect(cubit.state.sentCount, 12);
      expect(cubit.state.generalStatus, GeneralStatus.success);
      await cubit.close();
    });

    test('filter resetea page a 1', () async {
      final repository = _FakeCorrespondenceRepository();
      final cubit = SentEntryCubit(repository);

      await cubit.init();
      await cubit.changePage(2);
      cubit.filter('HR-2026');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(repository.lastSentPage, 1);
      expect(repository.lastSentSearch, 'HR-2026');
      expect(cubit.state.query, 'HR-2026');
      expect(cubit.state.page, 1);
      await cubit.close();
    });

    test('changePage solicita la página seleccionada', () async {
      final repository = _FakeCorrespondenceRepository();
      final cubit = SentEntryCubit(repository);

      await cubit.init();
      await cubit.changePage(3);

      expect(repository.lastSentPage, 3);
      expect(cubit.state.page, 3);
      await cubit.close();
    });

    test('changePageSize reinicia en página 1', () async {
      final repository = _FakeCorrespondenceRepository();
      final cubit = SentEntryCubit(repository);

      await cubit.init();
      await cubit.changePage(2);
      await cubit.changePageSize(50);

      expect(repository.lastSentPage, 1);
      expect(repository.lastSentPageSize, 50);
      expect(cubit.state.pageSize, 50);
      await cubit.close();
    });

    test('refresh conserva query y page', () async {
      final repository = _FakeCorrespondenceRepository();
      final cubit = SentEntryCubit(repository);

      await cubit.init();
      cubit.filter('Solicitud');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await cubit.changePage(2);
      await cubit.refresh();

      expect(repository.lastSentSearch, 'Solicitud');
      expect(repository.lastSentPage, 2);
      expect(cubit.state.query, 'Solicitud');
      expect(cubit.state.page, 2);
      await cubit.close();
    });

    test('repository error deja estado en error', () async {
      final repository = _FakeCorrespondenceRepository(
        sentResult: const Err(ServerFailure('falló sent')),
      );
      final cubit = SentEntryCubit(repository);

      await cubit.init();

      expect(cubit.state.generalStatus, GeneralStatus.error);
      expect(cubit.state.items, isEmpty);
      await cubit.close();
    });

    test('count error no destruye items en refresh', () async {
      final repository = _FakeCorrespondenceRepository(
        sentResult: Ok(
          repo.CorrespondencePage(
            items: [_sampleSentCorrespondence()],
            page: 1,
            pageSize: 20,
            total: 1,
            totalPages: 1,
          ),
        ),
      );
      final cubit = SentEntryCubit(repository);

      await cubit.init();
      repository.sentCountResult = const Err(ServerFailure('falló count'));
      await cubit.refresh();

      expect(cubit.state.items, isNotEmpty);
      expect(cubit.state.sentCount, 0);
      expect(cubit.state.generalStatus, GeneralStatus.success);
      await cubit.close();
    });

    test('lastSentAt se preserva en el mapeo', () async {
      final sentAt = DateTime.utc(2026, 2, 10, 15, 45);
      final repository = _FakeCorrespondenceRepository(
        sentResult: Ok(
          repo.CorrespondencePage(
            items: [
              repo.Correspondence(
                id: 'corr-sent-1',
                routeNumber: 'HR-2026-000010',
                routeYear: 2026,
                routeSequence: 10,
                correspondenceType: 'EXTERNAL',
                documentTypeCode: 'CARTA',
                documentTypeName: 'Carta',
                subject: 'Enviado',
                priority: 'LOW',
                status: 'ACTIVE',
                registeredAt: DateTime.utc(2026, 1, 15),
                lastSentAt: sentAt,
              ),
            ],
            page: 1,
            pageSize: 20,
            total: 1,
            totalPages: 1,
          ),
        ),
      );
      final cubit = SentEntryCubit(repository);

      await cubit.init();

      expect(cubit.state.items.single.lastSentAt, sentAt);
      await cubit.close();
    });
  });
}
