import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/cubit/correspondence_detail_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/cubit/correspondence_document_actions_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/views/correspondence_detail_body.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void _refreshSideMenuBadgesIfAvailable(BuildContext context) {
  try {
    context.read<SideMenuCubit>().refreshBadges();
  } catch (_) {}
}

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
          ListenerPro<CorrespondenceDetailCubit, CorrespondenceDetailState>()
              .event(
            onSuccess: (_) => _refreshSideMenuBadgesIfAvailable(context),
          ),
          ListenerPro<CorrespondenceDocumentActionsCubit,
                  CorrespondenceDocumentActionsState>()
              .listen(showLoading: false),
        ],
        child: CorrespondenceDetailBody(correspondenceId: correspondenceId),
      ),
    );
  }
}
