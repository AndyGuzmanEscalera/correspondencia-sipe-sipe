import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/public_consult/cubit/public_consult_cubit.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/auth_split_layout.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class PublicConsultPage extends StatelessWidget {
  const PublicConsultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PublicConsultCubit(),
      child: const PublicConsultView(),
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

class PublicConsultBody extends StatefulWidget {
  const PublicConsultBody({super.key});

  @override
  State<PublicConsultBody> createState() => _PublicConsultBodyState();
}

class _PublicConsultBodyState extends State<PublicConsultBody> {
  final _nameController = TextEditingController();
  final _documentController = TextEditingController();
  final _phoneController = TextEditingController();
  final _numberController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _documentController.dispose();
    _phoneController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    return _nameController.text.trim().isNotEmpty &&
        _documentController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _numberController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
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
            subtitle: 'Ingresa los datos de tu correspondencia para ver su estado.',
            child: Column(
              children: [
                BlocBuilder<PublicConsultCubit, PublicConsultState>(
                  builder: (context, state) {
                    return DropdownButtonFormField<int>(
                      value: state.year,
                      decoration: const InputDecoration(labelText: 'Gestión'),
                      items: const [2026, 2025, 2024, 2023]
                          .map(
                            (year) => DropdownMenuItem(
                              value: year,
                              child: Text('$year'),
                            ),
                          )
                          .toList(),
                      onChanged: context.read<PublicConsultCubit>().changeYear,
                    );
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre completo'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _documentController,
                  decoration: const InputDecoration(labelText: 'Cédula de identidad'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Celular'),
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _numberController,
                  decoration: const InputDecoration(labelText: 'Número único de correspondencia'),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _canSubmit
                        ? () => context.read<PublicConsultCubit>().consult(
                              fullName: _nameController.text,
                              documentId: _documentController.text,
                              phone: _phoneController.text,
                              uniqueNumberText: _numberController.text,
                            )
                        : null,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Consultar trámite'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.read<AppSessionCubit>().showSignIn(),
                  child: const Text('Acceso para funcionarios'),
                ),
              ],
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                      value: DateFormat('dd/MM/yyyy').format(result.registeredAt),
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
