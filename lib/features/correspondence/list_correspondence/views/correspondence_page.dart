import 'package:correspondencia_sipe_sipe/features/correspondence/list_correspondence/cubit/correspondence_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/list_correspondence/views/correspondence_view.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CorrespondencePage extends StatelessWidget {
  const CorrespondencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CorrespondenceCubit>(),
      child: const CorrespondenceView(),
    );
  }
}
