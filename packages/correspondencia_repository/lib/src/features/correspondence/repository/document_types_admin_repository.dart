import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:failures/failures.dart';

import '../../../core/entities/admin_page.dart';
import '../entities/document_type_admin.dart';
import '../mappers/document_type_admin_mapper.dart';

class DocumentTypesAdminRepository {
  DocumentTypesAdminRepository({required DocumentTypesAdminApi api}) : _api = api;

  final DocumentTypesAdminApi _api;

  Future<Result<AdminPage<DocumentTypeAdmin>, Failure>> list({
    int page = 1,
    int pageSize = 50,
    String? search,
    bool? isActive,
  }) {
    return handleExceptions<AdminPage<DocumentTypeAdmin>>(
      () async {
        final response = await _api.list(
          page: page,
          pageSize: pageSize,
          search: search,
          isActive: isActive,
        );
        return AdminPage(
          items: response.items.map((item) => item.toEntity()).toList(),
          page: response.page,
          pageSize: response.pageSize,
          total: response.total,
          totalPages: response.totalPages,
        );
      },
      feature: 'correspondence',
      operation: 'listDocumentTypesAdmin',
    );
  }

  Future<Result<DocumentTypeAdmin, Failure>> create(DocumentTypeInput input) {
    return handleExceptions<DocumentTypeAdmin>(
      () async => (await _api.create(input.toCreateRequest())).toEntity(),
      feature: 'correspondence',
      operation: 'createDocumentTypeAdmin',
    );
  }

  Future<Result<DocumentTypeAdmin, Failure>> update(
    String id,
    DocumentTypeUpdateInput input,
  ) {
    return handleExceptions<DocumentTypeAdmin>(
      () async => (await _api.update(id, input.toUpdateRequest())).toEntity(),
      feature: 'correspondence',
      operation: 'updateDocumentTypeAdmin',
    );
  }

  Future<Result<DocumentTypeAdmin, Failure>> setActive(
    String id, {
    required bool isActive,
  }) {
    return handleExceptions<DocumentTypeAdmin>(
      () async => (await _api.setActive(id, isActive: isActive)).toEntity(),
      feature: 'correspondence',
      operation: 'setDocumentTypeActive',
    );
  }
}
