import 'package:correspondencia_sipe_sipe/core/auth/session_header_labels.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/extensions/extension_device.dart';
import 'package:correspondencia_sipe_sipe/core/routes.dart';
import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AdminAppBar extends StatelessWidget {
  const AdminAppBar({
    this.onMenuTap,
    super.key,
  });

  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    final isSmall = context.isSmallScreen;

    return BlocBuilder<SideMenuCubit, SideMenuState>(
      builder: (context, menuState) {
        return BlocBuilder<AppSessionCubit, AppSessionState>(
          builder: (context, sessionState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding(isSmall),
                isSmall ? 10 : 12,
                horizontalPadding(isSmall),
                isSmall ? 10 : 12,
              ),
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
                    child: isSmall
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'GAM SIPE SIPE',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                    ),
                              ),
                              const Text(
                                'Correspondencia municipal',
                                style: TextStyle(
                                  color: UiColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Gobierno Autónomo Municipal de Sipe Sipe',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: UiColors.textPrimary,
                                          letterSpacing: -0.2,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: UiColors.primarySoft,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Correspondencia',
                                      style: TextStyle(
                                        color: UiColors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Panel institucional de gestión y trazabilidad documental',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: UiColors.textSecondary,
                                      fontSize: 12,
                                    ),
                              ),
                            ],
                          ),
                  ),
                  if (!isSmall) ...[
                    _UserChip(sessionState: sessionState, compact: false),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _signOut(context),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Salir'),
                    ),
                  ] else
                    PopupMenuButton<void>(
                      icon: CircleAvatar(
                        radius: 18,
                        backgroundColor: UiColors.primarySoft,
                        child: Text(
                          _initials(sessionState, compact: true),
                          style: const TextStyle(
                            color: UiColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem<void>(
                          enabled: false,
                          child: _MobileUserSummary(sessionState: sessionState),
                        ),
                        PopupMenuItem<void>(
                          onTap: () => _signOut(context),
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

  double horizontalPadding(bool isSmall) => isSmall ? 16.0 : 32.0;

  /// Logout flow. The AppSessionCubit orchestrates: calls repository.logout
  /// (backend clears HttpOnly cookie) and resets local state. Any network
  /// error is swallowed because local state is reset regardless.
  Future<void> _signOut(BuildContext context) async {
    await context.read<AppSessionCubit>().logout();
    if (context.mounted) {
      context.go(Routes.signIn);
    }
  }

  String _initials(AppSessionState s, {required bool compact}) {
    final labels = SessionHeaderLabels.forSession(
      s.userSession,
      compact: compact,
    );
    final name = labels.primaryLine;
    return name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';
  }
}

class _MobileUserSummary extends StatelessWidget {
  const _MobileUserSummary({required this.sessionState});

  final AppSessionState sessionState;

  @override
  Widget build(BuildContext context) {
    final labels = SessionHeaderLabels.forSession(
      sessionState.userSession,
      compact: true,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(labels.primaryLine, style: const TextStyle(fontWeight: FontWeight.w600)),
        if (labels.secondaryLine.isNotEmpty)
          Text(
            labels.secondaryLine,
            style: const TextStyle(color: UiColors.textSecondary, fontSize: 12),
          ),
      ],
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({
    required this.sessionState,
    required this.compact,
  });

  final AppSessionState sessionState;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final labels = SessionHeaderLabels.forSession(
      sessionState.userSession,
      compact: compact,
    );

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
              labels.primaryLine.isNotEmpty
                  ? labels.primaryLine.substring(0, 1).toUpperCase()
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
                labels.primaryLine,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              if (labels.secondaryLine.isNotEmpty)
                Text(
                  labels.secondaryLine,
                  style: const TextStyle(color: UiColors.textSecondary, fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
