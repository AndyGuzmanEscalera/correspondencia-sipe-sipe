import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/empty_state.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PermissionGuard extends StatelessWidget {
  const PermissionGuard({
    required this.permission,
    required this.child,
    super.key,
  });

  final String permission;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSessionCubit>().state.userSession;
    if (!hasPermission(session, permission)) {
      return const AdminContent(
        child: EmptyState(
          title: 'Acceso restringido',
          message: 'No tiene permisos para acceder a esta sección.',
          icon: Icons.lock_outline,
        ),
      );
    }
    return child;
  }
}
