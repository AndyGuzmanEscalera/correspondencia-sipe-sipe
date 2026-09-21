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
              padding: EdgeInsets.fromLTRB(horizontalPadding(isSmall), 16, horizontalPadding(isSmall), 16),
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
                          _initials(sessionState),
                          style: const TextStyle(
                            color: UiColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem<void>(
                          enabled: false,
                          child: Text(_displayName(sessionState)),
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

  String _initials(AppSessionState s) {
    final name = _displayName(s);
    return name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';
  }

  String _displayName(AppSessionState s) {
    final session = s.userSession;
    if (session == null) return '';
    return session.username;
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.sessionState});

  final AppSessionState sessionState;

  @override
  Widget build(BuildContext context) {
    final session = sessionState.userSession;
    final displayName = session?.username ?? '';
    final username = session?.username ?? '';

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
              displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U',
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
                displayName.isNotEmpty ? displayName : 'Funcionario',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Text(
                username.isEmpty ? 'Funcionario' : username,
                style: const TextStyle(color: UiColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
