import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/inbox/cubit/inbox_entry_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/inbox/views/inbox_entry_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InboxEntryView extends StatelessWidget {
  const InboxEntryView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        ListenerPro<InboxEntryCubit, InboxEntryState>().listen(
          showSuccess: false,
        ),
        BlocListener<InboxEntryCubit, InboxEntryState>(
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
          context.read<InboxEntryCubit>().init();
        },
        child: const InboxEntryBody(),
      ),
    );
  }
}
