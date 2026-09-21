import 'dart:async';

import 'package:correspondencia_sipe_sipe/core/data/local_store.dart';
import 'package:correspondencia_sipe_sipe/injection/injection.dart';
import 'package:flutter/widgets.dart';
import 'package:url_strategy/url_strategy.dart';

/// Bootstrap entry point.
///
/// Mirrors the Capturador / Inventarios pattern:
///   1. Initialize Flutter bindings.
///   2. Inject GetIt dependencies (DI).
///   3. Seed legacy demo data so other features that still depend on
///      [LocalStore] keep working while we migrate them feature by
///      feature.
///   4. Run the root widget.
///
/// Note: we intentionally do NOT register Firebase / Isar / hardware
/// helpers / HttpOverrides / insecure certificate callbacks here. This
/// project does not need them.
Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();

  await injectDependencies();

  // Temporary: keep the legacy demo data seeder alive while other
  // features (public_consult, correspondence, inbox, employees,
  // dashboard, reports) still read from LocalStore. Remove this when
  // the last mock-backed feature is migrated to the real backend.
  LocalStore.instance.seed();

  runApp(await builder());
}
