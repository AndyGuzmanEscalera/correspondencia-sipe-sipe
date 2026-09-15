import 'package:correspondencia_sipe_sipe/core/data/local_store.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/list/cubit/correspondence_list_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/empty_state.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class CorrespondenceListPage extends StatelessWidget {
  const CorrespondenceListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CorrespondenceListCubit()..init(),
      child: const CorrespondenceListView(),
    );
  }
}

class CorrespondenceListView extends StatelessWidget {
  const CorrespondenceListView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        ListenerPro<CorrespondenceListCubit, CorrespondenceListState>().listen(
          onPressedSuccess: () {
            context.read<SideMenuCubit>().refreshBadges();
          },
        ),
      ],
      child: const CorrespondenceListBody(),
    );
  }
}

class CorrespondenceListBody extends StatelessWidget {
  const CorrespondenceListBody({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminContent(
      child: Column(
        children: [
          SectionHeader(
            title: 'Correspondencias',
            subtitle: 'Registro institucional de trámites',
            actions: [
              ElevatedButton.icon(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nueva correspondencia'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SearchField(
            hint: 'Buscar por CITE, asunto o número único',
            onChanged: context.read<CorrespondenceListCubit>().filter,
          ),
          const SizedBox(height: 20),
          DataPanel(
            child: BlocBuilder<CorrespondenceListCubit, CorrespondenceListState>(
              builder: (context, state) {
                if (state.items.isEmpty) {
                  return const EmptyState(
                    title: 'Sin correspondencias',
                    message: 'No se encontraron trámites con ese criterio de búsqueda.',
                    icon: Icons.description_outlined,
                  );
                }

                return SingleChildScrollView(
                  child: DataTable(
                        columns: const [
                          DataColumn(label: Text('N°')),
                          DataColumn(label: Text('CITE')),
                          DataColumn(label: Text('Asunto')),
                          DataColumn(label: Text('Tipo')),
                          DataColumn(label: Text('Prioridad')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Fecha')),
                        ],
                        rows: state.items.map((item) {
                          return DataRow(
                            cells: [
                              DataCell(Text('${item.uniqueNumber}/${item.year}')),
                              DataCell(Text(item.cite)),
                              DataCell(Text(item.subject)),
                              DataCell(Text(item.typeLabel)),
                              DataCell(Text(item.priority)),
                              DataCell(StatusBadge(label: item.statusLabel)),
                              DataCell(Text(DateFormat('dd/MM/yyyy').format(item.registeredAt))),
                            ],
                          );
                        }).toList(),
                      ),
                    );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final subjectController = TextEditingController();
    final senderController = TextEditingController();
    final recipientController = TextEditingController(text: 'Secretaría Municipal');
    final citizenController = TextEditingController();
    final documentController = TextEditingController();
    final phoneController = TextEditingController();
    var type = CorrespondenceTypeCode.ce;
    var priority = 'Media';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nueva correspondencia'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: subjectController,
                    decoration: const InputDecoration(labelText: 'Asunto / referencia'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CorrespondenceTypeCode>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(value: CorrespondenceTypeCode.ce, child: Text('Externa (CE)')),
                      DropdownMenuItem(value: CorrespondenceTypeCode.ci, child: Text('Interna (CI)')),
                    ],
                    onChanged: (value) => type = value ?? CorrespondenceTypeCode.ce,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(labelText: 'Prioridad'),
                    items: const [
                      DropdownMenuItem(value: 'Alta', child: Text('Alta')),
                      DropdownMenuItem(value: 'Media', child: Text('Media')),
                      DropdownMenuItem(value: 'Baja', child: Text('Baja')),
                    ],
                    onChanged: (value) => priority = value ?? 'Media',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: senderController,
                    decoration: const InputDecoration(labelText: 'Remitente'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: recipientController,
                    decoration: const InputDecoration(labelText: 'Destinatario'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: citizenController,
                    decoration: const InputDecoration(labelText: 'Nombre ciudadano (consulta pública)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: documentController,
                    decoration: const InputDecoration(labelText: 'CI ciudadano'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Celular ciudadano'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<CorrespondenceListCubit>().create(
                      CreateCorrespondenceRequest(
                        subject: subjectController.text,
                        type: type,
                        priority: priority,
                        externalSender: senderController.text,
                        externalRecipient: recipientController.text,
                        citizenName: citizenController.text,
                        citizenDocumentId: documentController.text,
                        citizenPhone: phoneController.text,
                      ),
                    );
                Navigator.pop(dialogContext);
              },
              child: const Text('Registrar'),
            ),
          ],
        );
      },
    );
  }
}
