import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/cubit/correspondence_detail_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_movement_entity.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_cell_type.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_column.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_status_badge.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_dropdown.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/status_badge.dart'
    show DataPanel, StatusBadge;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class CorrespondenceDetailPage extends StatelessWidget {
  const CorrespondenceDetailPage({
    required this.correspondenceId,
    super.key,
  });

  final String correspondenceId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CorrespondenceDetailCubit>(
        param1: correspondenceId,
      )..init(),
      child: const CorrespondenceDetailView(),
    );
  }
}

class CorrespondenceDetailView extends StatelessWidget {
  const CorrespondenceDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        ListenerPro<CorrespondenceDetailCubit, CorrespondenceDetailState>()
            .listen(),
      ],
      child: const CorrespondenceDetailBody(),
    );
  }
}

class CorrespondenceDetailBody extends StatefulWidget {
  const CorrespondenceDetailBody({super.key});

  @override
  State<CorrespondenceDetailBody> createState() =>
      _CorrespondenceDetailBodyState();
}

class _CorrespondenceDetailBodyState extends State<CorrespondenceDetailBody> {
  final _toUnit = ControllerFieldDropdown<String>();
  final _toUser = ControllerFieldDropdown<String>();
  final _instruction = ControllerFieldPro();
  final _observation = ControllerFieldPro();
  final _deriveFormKey = GlobalKey<FormState>();

  static const _noUserOption = FormOption<String>(
    id: 0,
    text: 'Sin usuario específico',
    value: '',
  );

  @override
  void dispose() {
    _toUnit.dispose();
    _toUser.dispose();
    _instruction.dispose();
    _observation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminContent(
      child: BlocBuilder<CorrespondenceDetailCubit, CorrespondenceDetailState>(
        builder: (context, state) {
          final item = state.correspondence;
          if (item == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final unitItems = state.organizationalUnits
              .map(
                (unit) => FormOption<String>(
                  id: unit.id.hashCode,
                  text: unit.name,
                  value: unit.id,
                ),
              )
              .toList();

          final userItems = [
            _noUserOption,
            ...state.unitUsers.map(
              (user) => FormOption<String>(
                id: user.id.hashCode,
                text: user.displayName,
                value: user.id,
              ),
            ),
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Detalle de correspondencia',
                subtitle: item.cite,
                actions: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Volver'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _DetailCard(item: item),
              const SizedBox(height: 24),
              const Text(
                'Movimientos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              DataPanel(
                child: AppDataGrid<CorrespondenceMovementEntity>(
                  items: state.movements,
                  emptyMessage: 'Sin movimientos registrados.',
                  allowSorting: false,
                  columns: _movementColumns(),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Derivar trámite',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              DataPanel(
                child: Form(
                  key: _deriveFormKey,
                  child: Column(
                    children: [
                      if (unitItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'No hay unidades organizacionales activas disponibles.',
                          ),
                        )
                      else
                        AppDropdown<String>(
                          controller: _toUnit,
                          label: 'Unidad destino',
                          items: unitItems,
                          validators: [
                            RequiredValid(error: 'Seleccione una unidad'),
                          ],
                          onChanged: (option) {
                            _toUser.clear();
                            context
                                .read<CorrespondenceDetailCubit>()
                                .loadUsersForUnit(option.value!);
                          },
                        ),
                      if (_toUnit.isExist())
                        AppDropdown<String>(
                          controller: _toUser,
                          label: 'Usuario destino (opcional)',
                          items: userItems,
                          onChanged: (_) {},
                        ),
                      AppTextField(
                        controller: _instruction,
                        label: 'Instrucción',
                      ),
                      AppTextField(
                        controller: _observation,
                        label: 'Observación',
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: unitItems.isEmpty
                              ? null
                              : () => _submitDerive(context),
                          icon: const Icon(Icons.forward_rounded),
                          label: const Text('Derivar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<AppDataGridColumn<CorrespondenceMovementEntity>> _movementColumns() {
    return [
      AppDataGridColumn<CorrespondenceMovementEntity>(
        key: 'sequence',
        label: 'Sec.',
        type: AppDataGridCellType.integer,
        width: 72,
        value: (movement) => movement.sequenceNumber,
        mobilePriority: 5,
      ),
      AppDataGridColumn<CorrespondenceMovementEntity>(
        key: 'type',
        label: 'Tipo',
        value: (movement) => movement.movementTypeLabel,
        mobilePrimary: true,
        mobilePriority: 1,
      ),
      AppDataGridColumn<CorrespondenceMovementEntity>(
        key: 'fromUnit',
        label: 'Desde unidad',
        value: (movement) => movement.fromUnitName,
        mobilePriority: 15,
      ),
      AppDataGridColumn<CorrespondenceMovementEntity>(
        key: 'fromUser',
        label: 'Desde usuario',
        value: (movement) => movement.fromUserName,
        mobilePriority: 20,
      ),
      AppDataGridColumn<CorrespondenceMovementEntity>(
        key: 'toUnit',
        label: 'Hacia unidad',
        value: (movement) => movement.toUnitName,
        mobilePriority: 25,
      ),
      AppDataGridColumn<CorrespondenceMovementEntity>(
        key: 'toUser',
        label: 'Hacia usuario',
        value: (movement) => movement.toUserName,
        mobilePriority: 30,
      ),
      AppDataGridColumn<CorrespondenceMovementEntity>(
        key: 'instruction',
        label: 'Instrucción',
        value: (movement) => movement.instruction,
        mobilePriority: 35,
      ),
      AppDataGridColumn<CorrespondenceMovementEntity>(
        key: 'createdAt',
        label: 'Fecha',
        type: AppDataGridCellType.dateTime,
        width: 150,
        value: (movement) => movement.createdAt,
        mobilePriority: 10,
      ),
      AppDataGridColumn<CorrespondenceMovementEntity>(
        key: 'status',
        label: 'Estado',
        type: AppDataGridCellType.status,
        width: 120,
        sortable: false,
        value: (movement) => movement.isCancelled,
        mobilePriority: 3,
        cellBuilder: (context, movement, value) {
          if (movement.isCancelled) {
            return const AppStatusBadge.inactive('Cancelado');
          }
          return const AppStatusBadge.success('Vigente');
        },
      ),
    ];
  }

  void _submitDerive(BuildContext context) {
    if (!_deriveFormKey.validateForm()) return;

    final unitId = _toUnit.get();
    if (unitId == null || unitId.isEmpty) return;

    final selectedUser = _toUser.isExist() ? _toUser.get() : null;
    context.read<CorrespondenceDetailCubit>().derive(
          DeriveCorrespondenceFormData(
            toUnitId: unitId,
            toUserId: selectedUser != null && selectedUser.isNotEmpty
                ? selectedUser
                : null,
            instruction: _instruction.getValue().trim().isEmpty
                ? null
                : _instruction.getValue().trim(),
            observation: _observation.getValue().trim().isEmpty
                ? null
                : _observation.getValue().trim(),
          ),
        );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.item});

  final CorrespondenceEntity item;

  @override
  Widget build(BuildContext context) {
    return DataPanel(
      child: Wrap(
        spacing: 32,
        runSpacing: 12,
        children: [
          _InfoTile(label: 'HR', value: item.routeNumber),
          if (item.cite.isNotEmpty)
            _InfoTile(label: 'CITE', value: item.cite),
          _InfoTile(label: 'Tipo de documento', value: item.documentTypeName),
          _InfoTile(label: 'Tipo de correspondencia', value: item.typeLabel),
          _InfoTile(label: 'Asunto', value: item.subject),
          if (item.reference != null && item.reference!.isNotEmpty)
            _InfoTile(label: 'Referencia', value: item.reference!),
          _InfoTile(label: 'Prioridad', value: item.priority),
          _InfoTile(
            label: item.type == CorrespondenceTypeCode.ce ? 'Remitente' : 'Origen',
            value: item.originLabel,
          ),
          if (item.originDescription != null &&
              item.originDescription!.isNotEmpty)
            _InfoTile(
              label: 'Descripción del origen',
              value: item.originDescription!,
            ),
          _InfoTile(
            label: 'Responsable actual',
            value: item.currentResponsibleLabel,
          ),
          _InfoTile(label: 'Estado', value: item.statusLabel),
          _InfoTile(
            label: 'Fecha registro',
            value: DateFormat('dd/MM/yyyy').format(item.registeredAt),
          ),
          StatusBadge(label: item.statusLabel),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
