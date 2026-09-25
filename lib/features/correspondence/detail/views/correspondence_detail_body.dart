import 'dart:math' as math;

import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/cubit/correspondence_detail_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/attachments/widgets/correspondence_attachments_section.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/widgets/correspondence_derive_section.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/widgets/correspondence_lifecycle_section.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/widgets/correspondence_detail_header.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/widgets/correspondence_info_section.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/widgets/correspondence_movements_section.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_movement_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Composición vertical del detalle.
///
/// Futuros módulos (Adjuntos, Documentos generados) se insertan como widgets
/// hermanos entre info y movimientos, o bajo tabs cuando el volumen lo exija.
class CorrespondenceDetailBody extends StatelessWidget {
  const CorrespondenceDetailBody({
    required this.correspondenceId,
    super.key,
  });

  final String correspondenceId;

  static const _compactMaxWidth = 767.0;

  /// Scroll del bloque superior (info y movimientos en mobile).
  static const contentScrollKey = Key('correspondence-detail-content-scroll');

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth <= _compactMaxWidth;
        final isShort = constraints.maxHeight <= 820;
        final padding = isCompact
            ? 16.0
            : (isShort ? 18.0 : 32.0);
        final sectionGap = isCompact
            ? 16.0
            : (isShort ? 12.0 : 24.0);

        return Container(
          color: UiColors.background,
          padding:
              EdgeInsets.fromLTRB(padding, padding - 4, padding, padding),
          child: BlocBuilder<CorrespondenceDetailCubit,
              CorrespondenceDetailState>(
            builder: (context, state) {
              final item = state.correspondence;
              if (item == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if (isCompact) {
                return _CompactDetailLayout(
                  correspondenceId: correspondenceId,
                  item: item,
                  movements: state.movements,
                  sectionGap: sectionGap,
                  canManageLifecycle: state.canManageLifecycle,
                  lifecycleActionInProgress: state.lifecycleActionInProgress,
                );
              }

              return _WideDetailLayout(
                correspondenceId: correspondenceId,
                item: item,
                movements: state.movements,
                sectionGap: sectionGap,
                isShort: isShort,
                canManageLifecycle: state.canManageLifecycle,
                lifecycleActionInProgress: state.lifecycleActionInProgress,
              );
            },
          ),
        );
      },
    );
  }
}

class _CompactDetailLayout extends StatelessWidget {
  const _CompactDetailLayout({
    required this.correspondenceId,
    required this.item,
    required this.movements,
    required this.sectionGap,
    required this.canManageLifecycle,
    required this.lifecycleActionInProgress,
  });

  final String correspondenceId;
  final CorrespondenceEntity item;
  final List<CorrespondenceMovementEntity> movements;
  final double sectionGap;
  final bool canManageLifecycle;
  final bool lifecycleActionInProgress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CorrespondenceDetailHeader(
          item: item,
          onBack: () => Navigator.pop(context),
        ),
        SizedBox(height: sectionGap - 4),
        Expanded(
          child: SingleChildScrollView(
            key: CorrespondenceDetailBody.contentScrollKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                CorrespondenceInfoSection(item: item),
                SizedBox(height: sectionGap),
                CorrespondenceMovementsSection(
                  movements: movements,
                  expandVertically: false,
                ),
                SizedBox(height: sectionGap),
                CorrespondenceLifecycleSection(
                  item: item,
                  canManage: canManageLifecycle,
                  actionInProgress: lifecycleActionInProgress,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: sectionGap),
        CorrespondenceAttachmentsSection(
          correspondenceId: correspondenceId,
        ),
        if (item.isActiveStatus) ...[
          SizedBox(height: sectionGap),
          CorrespondenceDeriveSection(
            correspondenceId: correspondenceId,
            expandVertically: false,
          ),
        ],
      ],
    );
  }
}

class _WideDetailLayout extends StatelessWidget {
  const _WideDetailLayout({
    required this.correspondenceId,
    required this.item,
    required this.movements,
    required this.sectionGap,
    required this.canManageLifecycle,
    required this.lifecycleActionInProgress,
    this.isShort = false,
  });

  final String correspondenceId;
  final CorrespondenceEntity item;
  final List<CorrespondenceMovementEntity> movements;
  final double sectionGap;
  final bool canManageLifecycle;
  final bool lifecycleActionInProgress;
  final bool isShort;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CorrespondenceDetailHeader(
          item: item,
          onBack: () => Navigator.pop(context),
        ),
        SizedBox(height: sectionGap - 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: isShort ? 96 : 180,
                  ),
                  child: SingleChildScrollView(
                    key: CorrespondenceDetailBody.contentScrollKey,
                    child: CorrespondenceInfoSection(
                      item: item,
                      expandInParent: false,
                    ),
                  ),
                ),
              ),
              SizedBox(height: sectionGap),
              Expanded(
                child: CorrespondenceMovementsSection(
                  movements: movements,
                  expandVertically: true,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: sectionGap),
        _WideFooterActions(
          correspondenceId: correspondenceId,
          item: item,
          sectionGap: sectionGap,
          canManageLifecycle: canManageLifecycle,
          lifecycleActionInProgress: lifecycleActionInProgress,
        ),
      ],
    );
  }
}

class _WideFooterActions extends StatelessWidget {
  const _WideFooterActions({
    required this.correspondenceId,
    required this.item,
    required this.sectionGap,
    required this.canManageLifecycle,
    required this.lifecycleActionInProgress,
  });

  final String correspondenceId;
  final CorrespondenceEntity item;
  final double sectionGap;
  final bool canManageLifecycle;
  final bool lifecycleActionInProgress;

  @override
  Widget build(BuildContext context) {
    final sections = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CorrespondenceAttachmentsSection(
          correspondenceId: correspondenceId,
        ),
        SizedBox(height: sectionGap),
        CorrespondenceLifecycleSection(
          item: item,
          canManage: canManageLifecycle,
          actionInProgress: lifecycleActionInProgress,
        ),
        if (item.isActiveStatus) ...[
          SizedBox(height: sectionGap),
          CorrespondenceDeriveSection(
            correspondenceId: correspondenceId,
            expandVertically: false,
          ),
        ],
      ],
    );

    final maxFooterHeight = math.min(220.0, MediaQuery.sizeOf(context).height * 0.28);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxFooterHeight),
      child: SingleChildScrollView(
        child: sections,
      ),
    );
  }
}
