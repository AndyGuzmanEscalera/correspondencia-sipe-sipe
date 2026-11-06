import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/routes.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/official_logo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  late final _repository = widget.repository ?? PublicTrackingRepository();
  bool _loading = false;
  PublicRouteSheetTracking? _result;
  String? _error;

  @override
  void dispose() {
    _route.dispose();
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
      final result = await _repository.trackRouteSheet(_route.text);
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

  Widget _surface(Widget child, {Color color = Colors.white}) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: UiColors.border)),
        child: child,
      );

  Widget _searchCard() => _surface(Form(
      key: _form,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Icon(Icons.travel_explore_rounded,
            color: UiColors.primary, size: 32),
        const SizedBox(height: 16),
        Text('Consulta de Hoja de Ruta',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        const Text(
            'Consulte el estado de su trámite ingresando el número de Hoja de Ruta.',
            style: TextStyle(color: UiColors.textSecondary, height: 1.5)),
        const SizedBox(height: 24),
        TextFormField(
            controller: _route,
            enabled: !_loading,
            maxLength: 30,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.search,
            onFieldSubmitted: (_) => _consult(),
            decoration: InputDecoration(
                labelText: 'Número de Hoja de Ruta',
                hintText: 'HR-2026-000123',
                counterText: '',
                prefixIcon: const Icon(Icons.description_outlined),
                filled: true,
                fillColor: UiColors.background,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12))),
            validator: (v) => RegExp(r'^HR-\d{4}-\d{6,10}$')
                    .hasMatch((v ?? '').trim().toUpperCase())
                ? null
                : 'Ingrese un número de Hoja de Ruta válido.'),
        const SizedBox(height: 16),
        SizedBox(
            height: 48,
            child: ElevatedButton.icon(
                onPressed: _loading ? null : _consult,
                icon: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search_rounded),
                label: Text(_loading ? 'Consultando…' : 'Consultar'))),
        const SizedBox(height: 16),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.lock_open_outlined,
              size: 15, color: UiColors.textSecondary),
          SizedBox(width: 6),
          Flexible(
              child: Text('No necesita iniciar sesión.',
                  style:
                      TextStyle(color: UiColors.textSecondary, fontSize: 12))),
        ]),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 8),
        TextButton(
            onPressed: () => context.go(Routes.signIn),
            child: const Text('Volver al inicio de sesión')),
      ])));

  Widget _notice(IconData icon, String title, String message,
          {bool error = false}) =>
      _surface(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon,
            size: 36, color: error ? UiColors.warning : UiColors.primary),
        const SizedBox(height: 16),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(message,
            style: const TextStyle(color: UiColors.textSecondary, height: 1.6)),
      ]));

  Widget _fact(String label, String value) => SizedBox(
      width: 230,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: UiColors.textSecondary)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]));

  Widget _tracking(PublicRouteSheetTracking result) {
    final finished = result.statusLabel == 'Concluido';
    final statusColor = finished ? UiColors.primary : UiColors.info;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _surface(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('HOJA DE RUTA',
            style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.4,
                color: UiColors.textSecondary,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(
            spacing: 16,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(result.routeSheetNumber ?? '',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                      color: statusColor.withOpacity(.08),
                      borderRadius: BorderRadius.circular(30)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                        finished
                            ? Icons.check_circle_outline
                            : Icons.schedule_rounded,
                        size: 16,
                        color: statusColor),
                    const SizedBox(width: 6),
                    Text(result.statusLabel ?? '',
                        style: TextStyle(
                            color: statusColor, fontWeight: FontWeight.w700)),
                  ])),
            ]),
        const SizedBox(height: 20),
        Text('Referencia: ${result.reference ?? "—"}',
            style: const TextStyle(fontSize: 15, height: 1.5)),
        const SizedBox(height: 20),
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: UiColors.primarySoft,
                borderRadius: BorderRadius.circular(12)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.account_balance_outlined,
                  color: UiColors.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Actualmente en',
                        style: TextStyle(
                            fontSize: 12, color: UiColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(result.currentUnit ?? 'Sin unidad informada',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, height: 1.4)),
                  ])),
            ])),
        const SizedBox(height: 20),
        Wrap(spacing: 20, runSpacing: 16, children: [
          _fact('Fecha de recepción', _date(result.receivedAt)),
          _fact('Última actualización', _date(result.lastUpdatedAt)),
        ]),
      ])),
      const SizedBox(height: 16),
      _surface(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Seguimiento',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Recorrido institucional del trámite',
            style: TextStyle(color: UiColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 24),
        if (result.movements.isEmpty)
          const Text('Aún no hay movimientos para mostrar.'),
        for (var i = 0; i < result.movements.length; i++)
          _timelineItem(result.movements[i], i == result.movements.length - 1),
      ])),
    ]);
  }

  Widget _timelineItem(PublicRouteSheetMovement movement, bool last) =>
      IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
            width: 30,
            child: Column(children: [
              Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: last ? UiColors.primary : UiColors.primarySoft),
                  child: Icon(
                      last ? Icons.location_on_outlined : Icons.check_rounded,
                      size: 16,
                      color: last ? Colors.white : UiColors.primary)),
              if (!last)
                Expanded(
                    child: Center(
                        child: Container(width: 2, color: UiColors.border))),
            ])),
        const SizedBox(width: 14),
        Expanded(
            child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_date(movement.date),
                          style: const TextStyle(
                              color: UiColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(movement.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      if (movement.unit != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(movement.unit!,
                                style: const TextStyle(
                                    color: UiColors.textSecondary,
                                    height: 1.4))),
                    ]))),
      ]));

  Widget _content() {
    if (_error != null)
      return _notice(Icons.wifi_off_rounded, 'No pudimos conectar', _error!,
          error: true);
    if (_loading)
      return _notice(Icons.hourglass_top_rounded, 'Buscando su trámite',
          'Estamos consultando el estado y los movimientos de su Hoja de Ruta.');
    if (_result case final result?) {
      return result.found
          ? _tracking(result)
          : _notice(Icons.search_off_rounded, 'No encontramos el trámite',
              'No se encontró una Hoja de Ruta con los datos ingresados. Verifique el número de Hoja de Ruta.',
              error: true);
    }
    return _notice(
        Icons.route_outlined,
        'El recorrido de su trámite, en un solo lugar',
        'Ingrese el número que recibió al presentar su documentación. Aquí podrá ver el estado actual, la unidad responsable y los movimientos registrados.');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: UiColors.background,
      body: SafeArea(
          child: SingleChildScrollView(
              child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1160),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 28),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const OfficialLogo(width: 260),
                                const SizedBox(height: 24),
                                const Divider(color: UiColors.border),
                                const SizedBox(height: 24),
                                const Text('SEGUIMIENTO CIUDADANO',
                                    style: TextStyle(
                                        color: UiColors.primary,
                                        fontSize: 11,
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 8),
                                Text('Conozca el estado de su trámite',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: UiColors.textPrimary)),
                                const SizedBox(height: 24),
                                LayoutBuilder(builder: (context, constraints) {
                                  if (constraints.maxWidth < 840)
                                    return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          _searchCard(),
                                          const SizedBox(height: 20),
                                          _content()
                                        ]);
                                  return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                            width: 360, child: _searchCard()),
                                        const SizedBox(width: 24),
                                        Expanded(child: _content())
                                      ]);
                                }),
                                const SizedBox(height: 28),
                                const Text(
                                    'Gobierno Autónomo Municipal de Sipe Sipe',
                                    style: TextStyle(
                                        color: UiColors.textSecondary,
                                        fontSize: 12)),
                              ])))))));
}
