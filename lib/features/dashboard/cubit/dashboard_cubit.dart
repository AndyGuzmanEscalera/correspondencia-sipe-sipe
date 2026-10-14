import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repository) : super(const DashboardState());
  final repo.DashboardRepository _repository;
  int _request = 0;
  Future<void> init() => refresh();
  Future<void> refresh() async {
    final request = ++_request;
    emit(state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage.empty()));
    final result = await _repository.load();
    if (isClosed || request != _request) return;
    result.when(
        ok: (data) => emit(DashboardState(
            mineCount: data.mine,
            unitCount: data.unit,
            sentCount: data.sent,
            concludedCount: data.concluded,
            totalCount: data.total,
            canViewUnit: data.canViewUnit,
            activity: data.activity,
            generalStatus: GeneralStatus.success)),
        err: (failure) => emit(state.copyWith(
            generalStatus: GeneralStatus.error,
            dialogMessage: DialogMessage(
                message: FailureGeneric.message(
                    failure: failure,
                    messageResult: 'No se pudo actualizar Inicio'),
                showLoading: false))));
  }
}
