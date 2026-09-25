import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repository) : super(const DashboardState());

  final repo.CorrespondenceRepository _repository;

  int? _lastMineCount;
  int? _lastUnitCount;
  int? _lastSentCount;

  Future<void> init() async {
    await refresh();
  }

  Future<void> refresh() async {
    final isInitialLoad =
        _lastMineCount == null && _lastUnitCount == null && _lastSentCount == null;

    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: DialogMessage(
          message: 'Actualizando panel...',
          showLoading: isInitialLoad,
        ),
      ),
    );

    await Future.wait([
      _loadInboxCounts(),
      _loadSentCount(),
    ]);

    emit(
      state.copyWith(
        generalStatus: GeneralStatus.success,
        dialogMessage: const DialogMessage(
          message: 'Panel actualizado',
          showSuccess: false,
        ),
      ),
    );
  }

  Future<void> _loadInboxCounts() async {
    final result = await _repository.getInboxCounts();
    result.when(
      ok: (counts) {
        _lastMineCount = counts.mine;
        _lastUnitCount = counts.unit;
        emit(
          state.copyWith(
            mineCount: counts.mine,
            unitCount: counts.unit,
          ),
        );
      },
      err: (_) {
        emit(
          state.copyWith(
            mineCount: _lastMineCount,
            unitCount: _lastUnitCount,
          ),
        );
      },
    );
  }

  Future<void> _loadSentCount() async {
    final result = await _repository.getSentCount();
    result.when(
      ok: (count) {
        _lastSentCount = count.total;
        emit(state.copyWith(sentCount: count.total));
      },
      err: (_) {
        emit(state.copyWith(sentCount: _lastSentCount));
      },
    );
  }
}
