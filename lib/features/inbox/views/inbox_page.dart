import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/inbox/cubit/inbox_cubit.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/empty_state.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({required this.inboxType, super.key});

  final InboxType inboxType;

  String get _title {
    return switch (inboxType) {
      InboxType.inbox => 'Bandeja de entrada',
      InboxType.received => 'Recibidos',
      InboxType.sent => 'Enviados',
      InboxType.observed => 'Observados',
      InboxType.archived => 'Archivados',
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InboxCubit(inboxType: inboxType)..init(),
      child: InboxView(title: _title),
    );
  }
}

class InboxView extends StatelessWidget {
  const InboxView({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return InboxBody(title: title);
  }
}

class InboxBody extends StatelessWidget {
  const InboxBody({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AdminContent(
      child: Column(
        children: [
          SectionHeader(
            title: title,
            subtitle: 'Seguimiento de movimientos en hoja de ruta',
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: AppDecorations.surfaceCard(elevated: false),
              child: BlocBuilder<InboxCubit, InboxState>(
                builder: (context, state) {
                  if (state.rows.isEmpty) {
                    return const EmptyState(
                      title: 'Bandeja vacía',
                      message: 'No hay trámites pendientes en esta bandeja.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: state.rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final row = state.rows[index];
                      final correspondence = row.correspondence;
                      final derivation = row.derivation;

                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: UiColors.background,
                          borderRadius: AppDecorations.borderRadiusMd,
                          border: Border.all(color: UiColors.borderLight),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: UiColors.primarySoft,
                                borderRadius: AppDecorations.borderRadiusSm,
                              ),
                              child: const Icon(
                                Icons.mail_outline_rounded,
                                color: UiColors.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    correspondence.subject,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'N° ${correspondence.uniqueNumber}/${correspondence.year} · ${correspondence.cite}',
                                    style: const TextStyle(
                                      color: UiColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _RouteLine(
                                    label: 'Ruta',
                                    value:
                                        '${derivation.originUnitName} → ${derivation.destinationUnitName}',
                                  ),
                                  const SizedBox(height: 6),
                                  _RouteLine(
                                    label: 'Destinatario',
                                    value: derivation.recipientName,
                                  ),
                                  const SizedBox(height: 6),
                                  _RouteLine(
                                    label: 'Instrucción',
                                    value: derivation.instruction,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                StatusBadge(label: derivation.statusLabel),
                                const SizedBox(height: 10),
                                Text(
                                  DateFormat('dd/MM/yyyy HH:mm').format(derivation.sentAt),
                                  style: const TextStyle(
                                    color: UiColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              color: UiColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}
