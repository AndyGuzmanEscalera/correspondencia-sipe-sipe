import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/cubit/correspondence_detail_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/views/correspondence_detail_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CorrespondenceDetailView extends StatelessWidget {
  const CorrespondenceDetailView({
    required this.correspondenceId,
    super.key,
  });

  final String correspondenceId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UiColors.background,
      body: MultiBlocListener(
        listeners: [
          ListenerPro<CorrespondenceDetailCubit, CorrespondenceDetailState>()
              .listen(),
        ],
        child: CorrespondenceDetailBody(correspondenceId: correspondenceId),
      ),
    );
  }
}
