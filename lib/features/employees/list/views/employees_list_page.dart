import 'package:correspondencia_sipe_sipe/features/employees/list/cubit/employees_list_cubit.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmployeesListPage extends StatelessWidget {
  const EmployeesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EmployeesListCubit()..init(),
      child: const EmployeesListView(),
    );
  }
}

class EmployeesListView extends StatelessWidget {
  const EmployeesListView({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmployeesListBody();
  }
}

class EmployeesListBody extends StatelessWidget {
  const EmployeesListBody({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminContent(
      child: Column(
        children: [
          const SectionHeader(
            title: 'Funcionarios',
            subtitle: 'Personal institucional vinculado al sistema',
          ),
          const SizedBox(height: 20),
          SearchField(
            hint: 'Buscar funcionario, cargo o unidad',
            onChanged: context.read<EmployeesListCubit>().filter,
          ),
          const SizedBox(height: 20),
          DataPanel(
            child: BlocBuilder<EmployeesListCubit, EmployeesListState>(
              builder: (context, state) {
                return SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('NOMBRE')),
                      DataColumn(label: Text('CARGO')),
                      DataColumn(label: Text('UNIDAD')),
                      DataColumn(label: Text('CI')),
                      DataColumn(label: Text('ESTADO')),
                    ],
                    rows: state.items.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              item.fullName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataCell(Text(item.positionName)),
                          DataCell(Text(item.unitName)),
                          DataCell(Text(item.documentId)),
                          DataCell(
                            StatusBadge(
                              label: item.isActive ? 'Activo' : 'Inactivo',
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
