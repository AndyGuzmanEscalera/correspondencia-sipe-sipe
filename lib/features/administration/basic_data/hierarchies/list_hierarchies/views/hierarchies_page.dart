import 'package:correspondencia_sipe_sipe/features/administration/basic_data/hierarchies/list_hierarchies/cubit/hierarchies_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/hierarchies/list_hierarchies/views/hierarchies_view.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HierarchiesPage extends StatelessWidget {
  const HierarchiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HierarchiesCubit>(),
      child: const HierarchiesView(),
    );
  }
}
