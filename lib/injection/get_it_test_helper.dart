/// Tiny helper for tests that need a clean GetIt singleton.
///
/// In production code, files import `getIt` from `lib/injection/get_it.dart`.
/// In tests we call `GetItTestHelper.reset()` and register fakes.
library;

import 'package:get_it/get_it.dart';

/// Mirrors `sl` from `lib/injection/get_it.dart` so tests can use the
/// same GetIt singleton without having to depend on production code.
final getItTestHelper = GetIt.instance;
