import 'package:correspondencia_sipe_sipe/features/administration/basic_data/units/list_units/cubit/units_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/units/list_units/views/units_view.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UnitsPage extends StatelessWidget {
  const UnitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<UnitsCubit>(),
      child: const UnitsView(),
    );
  }
}
