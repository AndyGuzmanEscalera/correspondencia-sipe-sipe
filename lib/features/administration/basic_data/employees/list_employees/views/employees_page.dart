import 'package:correspondencia_sipe_sipe/features/administration/basic_data/employees/list_employees/cubit/employees_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/employees/list_employees/views/employees_view.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmployeesPage extends StatelessWidget {
  const EmployeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EmployeesCubit>(),
      child: const EmployeesView(),
    );
  }
}
