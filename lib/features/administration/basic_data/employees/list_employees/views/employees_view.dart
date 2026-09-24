import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/employees/list_employees/cubit/employees_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/employees/list_employees/views/employees_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmployeesView extends StatelessWidget {
  const EmployeesView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        ListenerPro<EmployeesCubit, EmployeesState>().listen(),
      ],
      child: FullWidgetGeneric(
        onInit: () {
          context.read<EmployeesCubit>().get();
        },
        child: const EmployeesBody(),
      ),
    );
  }
}
