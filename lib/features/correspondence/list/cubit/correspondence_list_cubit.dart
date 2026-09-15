import 'package:correspondencia_sipe_sipe/core/data/local_store.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'correspondence_list_state.dart';

class CorrespondenceListCubit extends Cubit<CorrespondenceListState> {
  CorrespondenceListCubit({LocalStore? store})
      : _store = store ?? LocalStore.instance,
        super(const CorrespondenceListState());

  final LocalStore _store;

  void init() {
    emit(state.copyWith(items: List.of(_store.correspondences)));
  }

  void filter(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      emit(state.copyWith(items: List.of(_store.correspondences), query: ''));
      return;
    }

    final filtered = _store.correspondences.where((item) {
      return item.cite.toLowerCase().contains(normalized) ||
          item.subject.toLowerCase().contains(normalized) ||
          item.uniqueNumber.toString().contains(normalized);
    }).toList();

    emit(state.copyWith(items: filtered, query: query));
  }

  Future<void> create(CreateCorrespondenceRequest request) async {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(message: 'Registrando correspondencia...'),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 400));

    _store.createCorrespondence(request);
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.success,
        items: List.of(_store.correspondences),
        dialogMessage: const DialogMessage(
          title: 'Registro exitoso',
          message: 'La correspondencia fue registrada correctamente.',
        ),
      ),
    );
    emit(state.copyWith(generalStatus: GeneralStatus.initial));
  }
}
