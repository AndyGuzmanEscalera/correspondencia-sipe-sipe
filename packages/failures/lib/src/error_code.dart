/// Stable error codes for logging and support (Capturador-style).
enum ErrorCode {
  unauthorized('ERR_UNAUTHORIZED'),
  forbidden('ERR_FORBIDDEN'),
  notFound('ERR_NOT_FOUND'),
  validation('ERR_VALIDATION'),
  timeout('ERR_TIMEOUT'),
  network('ERR_NETWORK'),
  server('ERR_SERVER'),
  request('ERR_REQUEST'),
  format('ERR_FORMAT'),
  unexpected('ERR_UNEXPECTED');

  const ErrorCode(this.code);
  final String code;
}
