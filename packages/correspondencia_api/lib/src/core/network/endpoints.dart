/// All FastAPI paths used by the app live here.
///
/// Backend endpoints (see backend/app/modules/auth/router.py):
class Endpoints {
  const Endpoints._();

  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';

  static const String documentTypes = '/document-types';
  static const String employees = '/employees';
  static const String correspondences = '/correspondences';
  static const String correspondencesInbox = '/correspondences/inbox';
  static const String correspondencesInboxCounts = '/correspondences/inbox/counts';
  static const String correspondencesSent = '/correspondences/sent';
  static const String correspondencesSentCount = '/correspondences/sent/count';
  static String correspondence(String id) => '/correspondences/$id';
  static String correspondenceDerive(String id) => '/correspondences/$id/derive';
  static String correspondenceConclude(String id) =>
      '/correspondences/$id/conclude';
  static String correspondenceReopen(String id) => '/correspondences/$id/reopen';
  static String correspondenceMovements(String id) =>
      '/correspondences/$id/movements';
  static String correspondenceEncadenamientoPdf(String id) =>
      '/correspondences/$id/encadenamiento.pdf';
  static String correspondenceAttachments(String id) =>
      '/correspondences/$id/attachments';
  static String correspondenceAttachment(String correspondenceId, String attachmentId) =>
      '/correspondences/$correspondenceId/attachments/$attachmentId';
  static String correspondenceAttachmentDownload(
    String correspondenceId,
    String attachmentId,
  ) =>
      '/correspondences/$correspondenceId/attachments/$attachmentId/download';

  static const String organizationalUnits = '/organizational-units';
  static String organizationalUnitUsers(String unitId) =>
      '/organizational-units/$unitId/users';

  static const String adminOrganizationalUnits = '/admin/organizational-units';
  static String adminOrganizationalUnit(String id) =>
      '/admin/organizational-units/$id';
  static String adminOrganizationalUnitActive(String id) =>
      '/admin/organizational-units/$id/active';

  static const String adminPositions = '/admin/positions';
  static String adminPosition(String id) => '/admin/positions/$id';
  static String adminPositionActive(String id) => '/admin/positions/$id/active';

  static const String adminEmployees = '/admin/employees';
  static String adminEmployee(String id) => '/admin/employees/$id';
  static String adminEmployeeActive(String id) => '/admin/employees/$id/active';

  static const String adminUsers = '/admin/users';
  static String adminUser(String id) => '/admin/users/$id';
  static String adminUserActive(String id) => '/admin/users/$id/active';

  static const String adminRoles = '/admin/roles';

  static const String adminDocumentTypes = '/admin/document-types';
  static String adminDocumentType(String id) => '/admin/document-types/$id';
  static String adminDocumentTypeActive(String id) =>
      '/admin/document-types/$id/active';
}
