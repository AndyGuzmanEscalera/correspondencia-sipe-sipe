import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/routes.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/auth_split_layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class PublicConsultPage extends StatefulWidget {
  const PublicConsultPage({this.repository, super.key});
  final PublicTrackingRepository? repository;
  @override
  State<PublicConsultPage> createState() => _PublicConsultPageState();
}

class _PublicConsultPageState extends State<PublicConsultPage> {
  final _form = GlobalKey<FormState>();
  final _route = TextEditingController();
  final _document = TextEditingController();
  late final _repository = widget.repository ?? PublicTrackingRepository();
  bool _loading = false;
  PublicRouteSheetTracking? _result;
  String? _error;

  @override
  void dispose() {
    _route.dispose();
    _document.dispose();
    super.dispose();
  }

  Future<void> _consult() async {
    if (_loading || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _result = null;
      _error = null;
    });
    try {
      final result =
          await _repository.trackRouteSheet(_route.text, _document.text);
      if (mounted) setState(() => _result = result);
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'No se pudo realizar la consulta. Espere un momento e intente nuevamente.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _date(DateTime? value) => value == null
      ? '—'
      : DateFormat('dd/MM/yyyy HH:mm')
          .format(value.toUtc().subtract(const Duration(hours: 4)));

  @override
  Widget build(BuildContext context) => AuthSplitLayout(
        heroTitle: 'Consulta de Hoja de Ruta',
        heroSubtitle: 'Gobierno Autónomo Municipal de Sipe Sipe',
        heroBullets: const [],
        form: AuthFormCard(
          title: 'Consulta de Hoja de Ruta',
          subtitle:
              'Consulte el estado de su trámite ingresando el número de Hoja de Ruta y el documento registrado al momento de su recepción.',
          child: Form(
              key: _form,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                        controller: _route,
                        enabled: !_loading,
                        maxLength: 30,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                            labelText: 'Número de Hoja de Ruta',
                            hintText: 'HR-2026-000123'),
                        validator: (v) => RegExp(r'^HR-\d{4}-\d{6,10}$')
                                .hasMatch((v ?? '').trim().toUpperCase())
                            ? null
                            : 'Ingrese un número de Hoja de Ruta válido.'),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _document,
                        enabled: !_loading,
                        maxLength: 30,
                        autocorrect: false,
                        enableSuggestions: false,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9.\s-]'))
                        ],
                        decoration: const InputDecoration(
                            labelText: 'C.I. / Documento'),
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? 'El número de documento es obligatorio.'
                            : RegExp(r'^[a-zA-Z0-9.\s-]{4,30}$')
                                    .hasMatch(v!.trim())
                                ? null
                                : 'Ingrese un número de documento válido.',
                        onFieldSubmitted: (_) => _consult()),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: _loading ? null : _consult,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Consultar')),
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(_error!)),
                    if (_result case final result?) ...[
                      const SizedBox(height: 20),
                      if (!result.found)
                        const Text(
                            'No se encontró una Hoja de Ruta con los datos ingresados. Verifique el número de Hoja de Ruta y el documento.')
                      else ...[
                        const Divider(),
                        Text(result.routeSheetNumber ?? '',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(result.statusLabel ?? '',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Text('Referencia: ${result.reference ?? "—"}'),
                        Text('Fecha de recepción: ${_date(result.receivedAt)}'),
                        Text('Actualmente en: ${result.currentUnit ?? "—"}'),
                        Text(
                            'Última actualización: ${_date(result.lastUpdatedAt)}'),
                        const SizedBox(height: 16),
                        Text('Seguimiento',
                            style: Theme.of(context).textTheme.titleMedium),
                        for (final movement in result.movements)
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.circle, size: 12),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text(_date(movement.date),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall),
                                          Text(movement.label),
                                          if (movement.unit != null)
                                            Text(movement.unit!),
                                        ])),
                                  ])),
                      ],
                    ],
                    const SizedBox(height: 16),
                    TextButton(
                        onPressed: () => context.go(Routes.signIn),
                        child: const Text('Volver al inicio de sesión')),
                  ])),
        ),
      );
}
