import 'package:correspondencia_sipe_sipe/core/helpers/extensions/extension_device.dart';
import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminAppBar extends StatelessWidget {
  const AdminAppBar({
    this.onMenuTap,
    super.key,
  });

  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    final isSmall = context.isSmallScreen;
    final horizontalPadding = isSmall ? 16.0 : 32.0;

    return BlocBuilder<SideMenuCubit, SideMenuState>(
      builder: (context, menuState) {
        return BlocBuilder<AppSessionCubit, AppSessionState>(
          builder: (context, sessionState) {
            return Container(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 16),
              decoration: const BoxDecoration(
                color: UiColors.surface,
                border: Border(bottom: BorderSide(color: UiColors.borderLight)),
              ),
              child: Row(
                children: [
                  if (onMenuTap != null) ...[
                    IconButton(
                      onPressed: onMenuTap,
                      icon: const Icon(Icons.menu_rounded),
                      tooltip: 'Menú',
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          menuState.selected.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gobierno Autónomo Municipal de Sipe Sipe',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: UiColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (!isSmall) ...[
                    _UserChip(sessionState: sessionState),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.read<AppSessionCubit>().signOut(),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Salir'),
                    ),
                  ] else
                    PopupMenuButton<void>(
                      icon: CircleAvatar(
                        radius: 18,
                        backgroundColor: UiColors.primarySoft,
                        child: Text(
                          sessionState.employeeName.isNotEmpty
                              ? sessionState.employeeName.substring(0, 1)
                              : 'U',
                          style: const TextStyle(
                            color: UiColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem<void>(
                          enabled: false,
                          child: Text(sessionState.employeeName),
                        ),
                        PopupMenuItem<void>(
                          onTap: () => context.read<AppSessionCubit>().signOut(),
                          child: const Row(
                            children: [
                              Icon(Icons.logout_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Cerrar sesión'),
                            ],
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
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.sessionState});

  final AppSessionState sessionState;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: UiColors.background,
        borderRadius: AppDecorations.borderRadiusMd,
        border: Border.all(color: UiColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: UiColors.primarySoft,
            child: Text(
              sessionState.employeeName.isNotEmpty
                  ? sessionState.employeeName.substring(0, 1)
                  : 'U',
              style: const TextStyle(
                color: UiColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sessionState.employeeName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Text(
                sessionState.userName.isEmpty ? 'Funcionario' : sessionState.userName,
                style: const TextStyle(color: UiColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
