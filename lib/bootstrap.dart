import 'dart:async';

import 'package:correspondencia_sipe_sipe/injection/injection.dart';
import 'package:flutter/widgets.dart';
import 'package:url_strategy/url_strategy.dart';

/// Bootstrap entry point.
///
/// Mirrors the Capturador / Inventarios pattern:
///   1. Initialize Flutter bindings.
///   2. Inject GetIt dependencies (DI).
///   3. Run the root widget using the injected repositories.
///
/// Note: we intentionally do NOT register Firebase / Isar / hardware
/// helpers / HttpOverrides / insecure certificate callbacks here. This
/// project does not need them.
Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();

  await injectDependencies();

  runApp(await builder());
}
