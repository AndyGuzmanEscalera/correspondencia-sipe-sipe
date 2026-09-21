/// All FastAPI paths used by the app live here.
///
/// Backend endpoints (see backend/app/modules/auth/router.py):
class Endpoints {
  const Endpoints._();

  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';
}
