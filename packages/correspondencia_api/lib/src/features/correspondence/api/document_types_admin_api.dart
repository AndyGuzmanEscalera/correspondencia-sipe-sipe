import '../../../core/models/active_toggle_request.dart';
import '../../../core/models/paginated_response.dart';
import '../../../core/network/api_method.dart';
import '../../../core/network/endpoints.dart';
import '../models/document_type_admin_response.dart';

class DocumentTypesAdminApi {
  DocumentTypesAdminApi({required ApiMethod mainApi}) : _mainApi = mainApi;

  final ApiMethod _mainApi;

  Future<PaginatedResponse<DocumentTypeAdminResponse>> list({
    int page = 1,
    int pageSize = 50,
    String? search,
    bool? isActive,
  }) async {
    final json = await _mainApi.get(
      Endpoints.adminDocumentTypes,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
        if (isActive != null) 'is_active': isActive,
      },
      operation: 'admin.documentTypes.list',
    );
    return PaginatedResponse.fromJson(
      json,
      DocumentTypeAdminResponse.fromJson,
    );
  }

  Future<DocumentTypeAdminResponse> get(String id) async {
    final json = await _mainApi.get(
      Endpoints.adminDocumentType(id),
      operation: 'admin.documentTypes.get',
    );
    return DocumentTypeAdminResponse.fromJson(json);
  }

  Future<DocumentTypeAdminResponse> create(
    CreateDocumentTypeRequest request,
  ) async {
    final json = await _mainApi.post(
      Endpoints.adminDocumentTypes,
      data: request.toJson(),
      operation: 'admin.documentTypes.create',
    );
    return DocumentTypeAdminResponse.fromJson(json);
  }

  Future<DocumentTypeAdminResponse> update(
    String id,
    UpdateDocumentTypeRequest request,
  ) async {
    final json = await _mainApi.put(
      Endpoints.adminDocumentType(id),
      data: request.toJson(),
      operation: 'admin.documentTypes.update',
    );
    return DocumentTypeAdminResponse.fromJson(json);
  }

  Future<DocumentTypeAdminResponse> setActive(
    String id, {
    required bool isActive,
  }) async {
    final json = await _mainApi.patch(
      Endpoints.adminDocumentTypeActive(id),
      data: ActiveToggleRequest(isActive: isActive).toJson(),
      operation: 'admin.documentTypes.setActive',
    );
    return DocumentTypeAdminResponse.fromJson(json);
  }
}
