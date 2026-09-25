import 'package:correspondencia_sipe_sipe/core/data/local_store.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/derivation_entity.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InboxRow extends Equatable {
  const InboxRow({
    required this.derivation,
    required this.correspondence,
  });

  final DerivationEntity derivation;
  final CorrespondenceEntity correspondence;

  @override
  List<Object?> get props => [derivation, correspondence];
}

class MockInboxState extends Equatable {
  const MockInboxState({
    this.rows = const [],
    this.inboxType = InboxType.received,
  });

  final List<InboxRow> rows;
  final InboxType inboxType;

  MockInboxState copyWith({
    List<InboxRow>? rows,
    InboxType? inboxType,
  }) {
    return MockInboxState(
      rows: rows ?? this.rows,
      inboxType: inboxType ?? this.inboxType,
    );
  }

  @override
  List<Object?> get props => [rows, inboxType];
}

/// Bandejas mock (Recibidos, Enviados, Observados, Archivados).
class MockInboxCubit extends Cubit<MockInboxState> {
  MockInboxCubit({LocalStore? store, required InboxType inboxType})
      : _store = store ?? LocalStore.instance,
        super(MockInboxState(inboxType: inboxType));

  final LocalStore _store;

  void init() {
    final derivations = _store.derivationsByInbox(state.inboxType);
    final rows = derivations.map((derivation) {
      final correspondence = _store.correspondenceById(derivation.correspondenceId);
      return InboxRow(
        derivation: derivation,
        correspondence: correspondence ??
            CorrespondenceEntity(
              id: derivation.correspondenceId,
              uniqueNumber: 0,
              year: DateTime.now().year,
              cite: 'N/D',
              routeNumber: 'N/D',
              type: CorrespondenceTypeCode.ce,
              priority: 'N/D',
              subject: 'Sin datos',
              senderName: 'N/D',
              currentUnitName: 'N/D',
              currentUserName: 'N/D',
              registeredAt: DateTime.now(),
              status: 'ACTIVE',
              statusLabel: derivation.statusLabel,
              documentTypeCode: 'N/D',
              documentTypeName: 'N/D',
            ),
      );
    }).toList();

    emit(state.copyWith(rows: rows));
  }
}
