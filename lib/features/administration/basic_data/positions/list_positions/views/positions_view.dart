import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/list_positions/cubit/positions_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/list_positions/views/positions_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PositionsView extends StatelessWidget {
  const PositionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        ListenerPro<PositionsCubit, PositionsState>().listen(),
      ],
      child: FullWidgetGeneric(
        onInit: () {
          context.read<PositionsCubit>().get();
        },
        child: const PositionsBody(),
      ),
    );
  }
}
