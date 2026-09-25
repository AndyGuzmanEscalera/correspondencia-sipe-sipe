import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/cubit/correspondence_detail_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CorrespondenceLifecycleSection extends StatelessWidget {
  const CorrespondenceLifecycleSection({
    required this.item,
    required this.canManage,
    required this.actionInProgress,
    super.key,
  });

  final CorrespondenceEntity item;
  final bool canManage;
  final bool actionInProgress;

  @override
  Widget build(BuildContext context) {
    if (!canManage) {
      return const SizedBox.shrink();
    }

    if (item.isActiveStatus) {
      return _LifecyclePanel(
        title: 'Cierre de trámite',
        child: FilledButton.icon(
          onPressed: actionInProgress
              ? null
              : () => _confirmConclude(context),
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: const Text('Concluir'),
        ),
      );
    }

    if (item.isConcludedStatus) {
      return _LifecyclePanel(
        title: 'Reapertura',
        child: OutlinedButton.icon(
          onPressed: actionInProgress
              ? null
              : () => _confirmReopen(context),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reabrir'),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _confirmConclude(BuildContext context) async {
    final observationController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Concluir correspondencia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '¿Está seguro de que desea concluir esta correspondencia?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: observationController,
              decoration: const InputDecoration(
                labelText: 'Observación',
                hintText: 'Opcional',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Concluir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      observationController.dispose();
      return;
    }

    final observation = observationController.text.trim();
    observationController.dispose();

    await context.read<CorrespondenceDetailCubit>().conclude(
          observation: observation.isEmpty ? null : observation,
        );
  }

  Future<void> _confirmReopen(BuildContext context) async {
    final observationController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reabrir correspondencia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '¿Está seguro de que desea reabrir esta correspondencia?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: observationController,
              decoration: const InputDecoration(
                labelText: 'Observación',
                hintText: 'Opcional',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reabrir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      observationController.dispose();
      return;
    }

    final observation = observationController.text.trim();
    observationController.dispose();

    await context.read<CorrespondenceDetailCubit>().reopen(
          observation: observation.isEmpty ? null : observation,
        );
  }
}

class _LifecyclePanel extends StatelessWidget {
  const _LifecyclePanel({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: AppDecorations.surfaceCard(elevated: false),
          child: Align(
            alignment: Alignment.centerLeft,
            child: child,
          ),
        ),
      ],
    );
  }
}
