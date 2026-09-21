import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/core/routes.dart';
import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/public_consult/cubit/public_consult_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/public_consult/helpers/public_consult_form_inherited.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/auth_split_layout.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_dropdown.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class PublicConsultPage extends StatelessWidget {
  const PublicConsultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PublicConsultCubit(),
      child: PublicConsultFormInherited(
        child: Builder(
          builder: (context) {
            final inherited = PublicConsultFormInherited.of(context);
            return FullWidgetGeneric(
              onDispose: inherited.dispose,
              child: const PublicConsultView(),
            );
          },
        ),
      ),
    );
  }
}

class PublicConsultView extends StatelessWidget {
  const PublicConsultView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        ListenerPro<PublicConsultCubit, PublicConsultState>().listen(),
      ],
      child: const PublicConsultBody(),
    );
  }
}

class PublicConsultBody extends StatelessWidget {
  const PublicConsultBody({super.key});

  static const _years = [2026, 2025, 2024, 2023];

  @override
  Widget build(BuildContext context) {
    final inherited = PublicConsultFormInherited.of(context);
    final cubit = context.read<PublicConsultCubit>();

    return AuthSplitLayout(
      heroTitle: 'Consulta el estado\nde tu trámite',
      heroSubtitle:
          'Plataforma digital de correspondencia del Gobierno Autónomo Municipal de Sipe Sipe.',
      heroBullets: const [
        'Seguimiento transparente para ciudadanos',
        'Información clara y segura',
        'Disponible las 24 horas',
      ],
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthFormCard(
            title: 'Consulta de trámite',
            subtitle:
                'Ingresa los datos de tu correspondencia para ver su estado.',
            child: Form(
              key: inherited.formKey,
              child: Column(
                children: [
                  AppDropdown<int>(
                    controller: inherited.year,
                    label: 'Gestión',
                    items: _years
                        .map(
                          (year) => FormOption<int>(
                            id: year,
                            text: '$year',
                            value: year,
                          ),
                        )
                        .toList(),
                    onChanged: (option) => cubit.changeYear(option.value),
                  ),
                  AppTextField(
                    controller: inherited.fullName,
                    label: 'Nombre completo',
                    validators: [RequiredValid(error: 'Campo requerido')],
                  ),
                  AppTextField(
                    controller: inherited.documentId,
                    label: 'Cédula de identidad',
                    validators: [RequiredValid(error: 'Campo requerido')],
                  ),
                  AppTextField(
                    controller: inherited.phone,
                    label: 'Celular',
                    inputType: TextInputType.phone,
                    validators: [RequiredValid(error: 'Campo requerido')],
                  ),
                  AppTextField(
                    controller: inherited.uniqueNumber,
                    label: 'Número único de correspondencia',
                    inputType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validators: [
                      RequiredValid(error: 'Campo requerido'),
                      NumericValid(error: 'Ingrese un número único válido'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _submit(context, inherited, cubit),
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Consultar trámite'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go(Routes.signIn),
                    child: const Text('Acceso para funcionarios'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          BlocBuilder<PublicConsultCubit, PublicConsultState>(
            builder: (context, state) {
              final result = state.result;
              if (result == null) return const SizedBox.shrink();
              return Container(
                decoration: AppDecorations.surfaceCard(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Resultado encontrado',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        StatusBadge(label: result.statusLabel),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _InfoRow(label: 'CITE', value: result.cite),
                    _InfoRow(label: 'Asunto', value: result.subject),
                    _InfoRow(label: 'Tipo', value: result.typeLabel),
                    _InfoRow(label: 'Prioridad', value: result.priority),
                    _InfoRow(
                      label: 'Fecha registro',
                      value:
                          DateFormat('dd/MM/yyyy').format(result.registeredAt),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _submit(
    BuildContext context,
    PublicConsultFormInherited inherited,
    PublicConsultCubit cubit,
  ) {
    if (!inherited.formKey.validateForm()) return;

    final year = inherited.year.get();
    if (year == null) return;

    cubit.consult(
      year: year,
      fullName: inherited.fullName.getValue(),
      documentId: inherited.documentId.getValue(),
      phone: inherited.phone.getValue(),
      uniqueNumberText: inherited.uniqueNumber.getValue(),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: UiColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
