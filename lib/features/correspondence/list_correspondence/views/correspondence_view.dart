import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/list_correspondence/cubit/correspondence_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/list_correspondence/views/correspondence_body.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CorrespondenceView extends StatelessWidget {
  const CorrespondenceView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        ListenerPro<CorrespondenceCubit, CorrespondenceState>().listen(
          onPressedSuccess: () {
            context.read<SideMenuCubit>().refreshBadges();
          },
        ),
      ],
      child: FullWidgetGeneric(
        onInit: () {
          context.read<CorrespondenceCubit>().get();
        },
        child: const CorrespondenceBody(),
      ),
    );
  }
}
