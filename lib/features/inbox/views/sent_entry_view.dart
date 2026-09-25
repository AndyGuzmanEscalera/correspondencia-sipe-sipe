import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/inbox/cubit/sent_entry_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/inbox/views/sent_entry_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SentEntryView extends StatelessWidget {
  const SentEntryView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        ListenerPro<SentEntryCubit, SentEntryState>().listen(
          showSuccess: false,
        ),
        BlocListener<SentEntryCubit, SentEntryState>(
          listenWhen: (previous, current) =>
              previous.generalStatus != current.generalStatus &&
              current.generalStatus == GeneralStatus.success,
          listener: (context, _) {
            final permissions = context
                    .read<AppSessionCubit>()
                    .state
                    .userSession
                    ?.permissions ??
                [];
            context.read<SideMenuCubit>().refreshBadges(permissions: permissions);
          },
        ),
      ],
      child: FullWidgetGeneric(
        onInit: () {
          context.read<SentEntryCubit>().init();
        },
        child: const SentEntryBody(),
      ),
    );
  }
}
