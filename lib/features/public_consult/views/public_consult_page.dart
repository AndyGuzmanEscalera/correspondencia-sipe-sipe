import 'package:correspondencia_sipe_sipe/core/routes.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/auth_split_layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// La consulta pública requiere un backend con una política de divulgación.
/// No se solicitan datos personales ni se consulta el almacén de demostración.
class PublicConsultPage extends StatelessWidget {
  const PublicConsultPage({super.key});
  @override
  Widget build(BuildContext context) => AuthSplitLayout(
        heroTitle: 'Consulta de trámite',
        heroSubtitle: 'Gobierno Autónomo Municipal de Sipe Sipe',
        heroBullets: const [],
        form: AuthFormCard(
          title: 'Consulta pública no disponible',
          subtitle:
              'El seguimiento ciudadano en línea todavía no está habilitado. Solicite información a la unidad donde registró su trámite.',
          child: TextButton(
            onPressed: () => context.go(Routes.signIn),
            child: const Text('Acceso para funcionarios'),
          ),
        ),
      );
}
