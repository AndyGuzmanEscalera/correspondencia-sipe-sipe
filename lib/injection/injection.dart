import 'injection_bloc.dart';
import 'injection_repository.dart';

/// Entry point for GetIt DI. Called from `bootstrap.dart`.
///
/// Order:
///   1. registerCore + registerApis + registerRepositories (in [injection_repository.dart])
///   2. registerCubits (in [injection_bloc.dart])
///
/// Splitting the file in two keeps the registration lists manageable
/// as the project grows.
Future<void> injectDependencies() async {
  await registerRepositories();
  registerCubits();
}
