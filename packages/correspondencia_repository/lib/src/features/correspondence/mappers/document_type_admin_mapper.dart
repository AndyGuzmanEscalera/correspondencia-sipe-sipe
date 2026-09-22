import 'package:correspondencia_api/correspondencia_api.dart';

import '../entities/document_type_admin.dart';

extension DocumentTypeAdminResponseMapper on DocumentTypeAdminResponse {
  DocumentTypeAdmin toEntity() => DocumentTypeAdmin(
        id: id,
        code: code,
        name: name,
        isActive: isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension DocumentTypeInputMapper on DocumentTypeInput {
  CreateDocumentTypeRequest toCreateRequest() => CreateDocumentTypeRequest(
        code: code,
        name: name,
      );
}

extension DocumentTypeUpdateInputMapper on DocumentTypeUpdateInput {
  UpdateDocumentTypeRequest toUpdateRequest() => UpdateDocumentTypeRequest(
        name: name,
      );
}
