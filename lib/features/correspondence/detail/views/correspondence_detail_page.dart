import 'package:correspondencia_sipe_sipe/features/correspondence/detail/cubit/correspondence_detail_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/views/correspondence_detail_view.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CorrespondenceDetailPage extends StatelessWidget {
  const CorrespondenceDetailPage({
    required this.correspondenceId,
    super.key,
  });

  final String correspondenceId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CorrespondenceDetailCubit>(
        param1: correspondenceId,
      )..init(),
      child: CorrespondenceDetailView(correspondenceId: correspondenceId),
    );
  }
}
