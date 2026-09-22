/// HTTP layer: Dio, ApiMethod, endpoints, auth interceptors, and feature APIs.
///
/// All HTTP access in the app goes through this package's [ApiMethod].
/// The auth feature ([AuthenticationApi]) uses two Dio instances to avoid
/// the refresh-token recursion loop:
///   * `mainDio` — carries Authorization Bearer + the refresh interceptor.
///   * `refreshDio` — no Authorization, no refresh interceptor; used only for
///     login / refresh / logout so a 401 there cannot trigger another refresh.
library correspondencia_api;

export 'src/core/network/network.dart';
export 'src/core/network/api_client.dart';
export 'src/core/network/api_config.dart';
export 'src/core/network/api_interceptor.dart';
export 'src/core/network/api_logger.dart';
export 'src/core/network/api_method.dart';
export 'src/core/network/auth_interceptor.dart';
export 'src/core/network/auth_refresh_coordinator.dart';
export 'src/core/network/auth_refresh_interceptor.dart';
export 'src/core/network/auth_token_store.dart';
export 'src/core/models/active_toggle_request.dart';
export 'src/core/models/paginated_response.dart';
export 'src/core/network/endpoints.dart';
export 'src/features/authentication/api/auth_api.dart';
export 'src/features/authentication/api/auth_remote.dart';
export 'src/features/authentication/authentication.dart';
export 'src/features/authentication/models/auth_response.dart';
export 'src/features/authentication/models/user_response.dart';
export 'src/features/correspondence/correspondence.dart';
export 'src/features/identity/identity.dart';
export 'src/features/organization/organization.dart';
