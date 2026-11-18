import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/hierarchies/list_hierarchies/cubit/hierarchies_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/hierarchies/list_hierarchies/views/hierarchies_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HierarchiesView extends StatelessWidget {
  const HierarchiesView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        ListenerPro<HierarchiesCubit, HierarchiesState>().listen(),
      ],
      child: FullWidgetGeneric(
        onInit: () {
          context.read<HierarchiesCubit>().get();
        },
        child: const HierarchiesBody(),
      ),
    );
  }
}
