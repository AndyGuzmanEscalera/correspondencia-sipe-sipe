import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/units/list_units/cubit/units_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/units/list_units/views/units_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UnitsView extends StatelessWidget {
  const UnitsView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        ListenerPro<UnitsCubit, UnitsState>().listen(),
      ],
      child: FullWidgetGeneric(
        onInit: () {
          context.read<UnitsCubit>().get();
        },
        child: const UnitsBody(),
      ),
    );
  }
}
