import 'package:correspondencia_sipe_sipe/core/data/local_store.dart';
import 'package:correspondencia_sipe_sipe/features/employees/domain/entities/employee_entity.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmployeesListState extends Equatable {
  const EmployeesListState({this.items = const [], this.query = ''});

  final List<EmployeeEntity> items;
  final String query;

  EmployeesListState copyWith({
    List<EmployeeEntity>? items,
    String? query,
  }) {
    return EmployeesListState(
      items: items ?? this.items,
      query: query ?? this.query,
    );
  }

  @override
  List<Object?> get props => [items, query];
}

class EmployeesListCubit extends Cubit<EmployeesListState> {
  EmployeesListCubit({LocalStore? store})
      : _store = store ?? LocalStore.instance,
        super(const EmployeesListState());

  final LocalStore _store;

  void init() {
    emit(state.copyWith(items: List.of(_store.employees)));
  }

  void filter(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      emit(state.copyWith(items: List.of(_store.employees), query: ''));
      return;
    }

    final filtered = _store.employees.where((item) {
      return item.fullName.toLowerCase().contains(normalized) ||
          item.unitName.toLowerCase().contains(normalized) ||
          item.positionName.toLowerCase().contains(normalized);
    }).toList();

    emit(state.copyWith(items: filtered, query: query));
  }
}
