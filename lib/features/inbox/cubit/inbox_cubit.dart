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

class InboxState extends Equatable {
  const InboxState({
    this.rows = const [],
    this.inboxType = InboxType.inbox,
  });

  final List<InboxRow> rows;
  final InboxType inboxType;

  InboxState copyWith({
    List<InboxRow>? rows,
    InboxType? inboxType,
  }) {
    return InboxState(
      rows: rows ?? this.rows,
      inboxType: inboxType ?? this.inboxType,
    );
  }

  @override
  List<Object?> get props => [rows, inboxType];
}

class InboxCubit extends Cubit<InboxState> {
  InboxCubit({LocalStore? store, required InboxType inboxType})
      : _store = store ?? LocalStore.instance,
        super(InboxState(inboxType: inboxType));

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
              type: CorrespondenceTypeCode.ce,
              priority: 'N/D',
              subject: 'Sin datos',
              externalSender: 'N/D',
              externalRecipient: 'N/D',
              registeredAt: DateTime.now(),
              statusLabel: derivation.statusLabel,
              citizenName: 'N/D',
              citizenDocumentId: 'N/D',
              citizenPhone: 'N/D',
            ),
      );
    }).toList();

    emit(state.copyWith(rows: rows));
  }
}
