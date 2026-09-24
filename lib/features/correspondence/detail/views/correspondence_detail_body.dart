import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/cubit/correspondence_detail_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/attachments/widgets/correspondence_attachments_section.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/widgets/correspondence_derive_section.dart';
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

  static const _mobileScrollMaxWidth = 767.0;

  /// Scroll principal del detalle en mobile; usado en tests responsive.
  static const mobileScrollKey = Key('correspondence-detail-mobile-scroll');

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useMobileScroll = constraints.maxWidth <= _mobileScrollMaxWidth;
        final padding = useMobileScroll ? 16.0 : 32.0;
        final sectionGap = useMobileScroll ? 16.0 : 24.0;

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

              if (useMobileScroll) {
                return _MobileDetailScrollLayout(
                  correspondenceId: correspondenceId,
                  item: item,
                  movements: state.movements,
                  sectionGap: sectionGap,
                );
              }

              return _DesktopDetailLayout(
                correspondenceId: correspondenceId,
                item: item,
                movements: state.movements,
                sectionGap: sectionGap,
              );
            },
          ),
        );
      },
    );
  }
}

class _DesktopDetailLayout extends StatelessWidget {
  const _DesktopDetailLayout({
    required this.correspondenceId,
    required this.item,
    required this.movements,
    required this.sectionGap,
  });

  final String correspondenceId;
  final CorrespondenceEntity item;
  final List<CorrespondenceMovementEntity> movements;
  final double sectionGap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CorrespondenceDetailHeader(
          item: item,
          onBack: () => Navigator.pop(context),
        ),
        SizedBox(height: sectionGap - 4),
        CorrespondenceInfoSection(item: item, expandInParent: true),
        SizedBox(height: sectionGap),
        CorrespondenceAttachmentsSection(
          correspondenceId: correspondenceId,
        ),
        SizedBox(height: sectionGap),
        Expanded(
          child: CorrespondenceMovementsSection(
            movements: movements,
            expandVertically: true,
          ),
        ),
        SizedBox(height: sectionGap),
        Expanded(
          child: CorrespondenceDeriveSection(
            correspondenceId: correspondenceId,
            expandVertically: true,
          ),
        ),
      ],
    );
  }
}

class _MobileDetailScrollLayout extends StatelessWidget {
  const _MobileDetailScrollLayout({
    required this.correspondenceId,
    required this.item,
    required this.movements,
    required this.sectionGap,
  });

  final String correspondenceId;
  final CorrespondenceEntity item;
  final List<CorrespondenceMovementEntity> movements;
  final double sectionGap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: CorrespondenceDetailBody.mobileScrollKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CorrespondenceDetailHeader(
            item: item,
            onBack: () => Navigator.pop(context),
          ),
          SizedBox(height: sectionGap - 4),
          CorrespondenceInfoSection(item: item, expandInParent: false),
          SizedBox(height: sectionGap),
          CorrespondenceAttachmentsSection(
            correspondenceId: correspondenceId,
          ),
          SizedBox(height: sectionGap),
          CorrespondenceMovementsSection(
            movements: movements,
            expandVertically: false,
          ),
          SizedBox(height: sectionGap),
          CorrespondenceDeriveSection(
            correspondenceId: correspondenceId,
            expandVertically: false,
          ),
        ],
      ),
    );
  }
}
