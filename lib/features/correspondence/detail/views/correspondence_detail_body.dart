import 'package:correspondencia_sipe_sipe/features/correspondence/detail/cubit/correspondence_detail_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/attachments/widgets/correspondence_attachments_section.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/derive_correspondence/views/derive_correspondence_view.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/widgets/correspondence_lifecycle_section.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/widgets/correspondence_detail_header.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/widgets/correspondence_info_section.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/widgets/correspondence_movements_section.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/app_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CorrespondenceDetailBody extends StatelessWidget {
  const CorrespondenceDetailBody({required this.correspondenceId, super.key});
  final String correspondenceId;
  static const contentScrollKey = Key('correspondence-detail-content-scroll');

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 768;
        final gap = compact ? 16.0 : 24.0;
        return Padding(
          padding: EdgeInsets.all(compact ? 16 : 24),
          child:
              BlocBuilder<CorrespondenceDetailCubit, CorrespondenceDetailState>(
            builder: (context, state) {
              final item = state.correspondence;
              if (item == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CorrespondenceDetailHeader(
                      item: item,
                      onBack: () => Navigator.pop(context),
                      onDerive: item.isActiveStatus && item.canDerive
                          ? () => _openDerivation(context)
                          : null,
                    ),
                    SizedBox(height: gap),
                    Expanded(
                        child: SingleChildScrollView(
                      key: contentScrollKey,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CorrespondenceInfoSection(item: item),
                            SizedBox(height: gap),
                            if (compact)
                              CorrespondenceMovementsSection(
                                  movements: state.movements,
                                  expandVertically: false)
                            else
                              SizedBox(
                                height: (112.0 + state.movements.length * 64.0)
                                    .clamp(240.0, 560.0),
                                child: CorrespondenceMovementsSection(
                                    movements: state.movements),
                              ),
                            SizedBox(height: gap),
                            CorrespondenceAttachmentsSection(
                                correspondenceId: correspondenceId,
                                canManage: item.canManageAttachments),
                            if (item.canConclude || item.canReopen) ...[
                              SizedBox(height: gap),
                              CorrespondenceLifecycleSection(
                                  item: item,
                                  canManage: item.canConclude || item.canReopen,
                                  actionInProgress:
                                      state.lifecycleActionInProgress),
                            ],
                            SizedBox(height: gap),
                          ]),
                    )),
                  ]);
            },
          ),
        );
      });

  Future<void> _openDerivation(BuildContext context) async {
    final detail = context.read<CorrespondenceDetailCubit>();
    SideMenuCubit? menu;
    try {
      menu = context.read<SideMenuCubit>();
    } catch (_) {}
    await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          Widget dialog = BlocProvider.value(
              value: detail,
              child: AppFormDialog(
                title: 'Derivar trámite',
                subtitle: detail.state.correspondence?.routeNumber,
                maxWidth: 860,
                customActions: const SizedBox.shrink(),
                child: DeriveCorrespondencePage(
                    correspondenceId: correspondenceId,
                    scrollable: false,
                    onCompleted: () => Navigator.of(dialogContext).pop()),
              ));
          if (menu != null) {
            dialog = BlocProvider.value(value: menu, child: dialog);
          }
          return dialog;
        });
  }
}
