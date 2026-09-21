/// Route paths del módulo de correspondencia.
class Routes {
  Routes._();

  /// Arranque real: Splash valida sesión vía cookie refresh.
  static const initial = '/';

  /// Alias de arranque (compatibilidad con rutas existentes).
  static const bootstrap = '/correspondencia';

  /// Consulta pública de trámites (ciudadanos).
  static const publicConsult = '/consulta-publica';

  /// Login de funcionarios.
  static const signIn = '/correspondencia/login';

  /// Panel administrativo autenticado.
  static const home = '/correspondencia/home';
}
