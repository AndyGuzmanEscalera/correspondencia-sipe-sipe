import 'package:dio/dio.dart';

import '../../../core/network/api_method.dart';
import '../../../core/network/endpoints.dart';
import '../models/correspondence_attachment_response.dart';
import '../models/correspondence_inbox_counts_response.dart';
import '../models/correspondence_sent_count_response.dart';
import '../models/correspondence_list_response.dart';
import '../models/correspondence_movement_response.dart';
import '../models/correspondence_response.dart';
import '../models/create_correspondence_request.dart';
import '../models/derive_correspondence_request.dart';
import '../models/document_type_response.dart';
import '../models/employee_option_response.dart';

class CorrespondenceApi {
  CorrespondenceApi({required ApiMethod mainApi}) : _mainApi = mainApi;

  final ApiMethod _mainApi;

  Future<List<DocumentTypeResponse>> listDocumentTypes() async {
    final items = await _mainApi.getList(
      Endpoints.documentTypes,
      operation: 'correspondence.documentTypes',
    );
    return items.map(DocumentTypeResponse.fromJson).toList();
  }

  Future<List<EmployeeOptionResponse>> listEmployees() async {
    final items = await _mainApi.getList(
      Endpoints.employees,
      operation: 'correspondence.employees',
    );
    return items.map(EmployeeOptionResponse.fromJson).toList();
  }

  Future<CorrespondenceListResponse> getInbox({
    required String scope,
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    final json = await _mainApi.get(
      Endpoints.correspondencesInbox,
      queryParameters: {
        'scope': scope,
        'page': page,
        'page_size': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
      },
      operation: 'correspondence.inbox',
    );
    return CorrespondenceListResponse.fromJson(json);
  }

  Future<CorrespondenceInboxCountsResponse> getInboxCounts() async {
    final json = await _mainApi.get(
      Endpoints.correspondencesInboxCounts,
      operation: 'correspondence.inboxCounts',
    );
    return CorrespondenceInboxCountsResponse.fromJson(json);
  }

  Future<CorrespondenceListResponse> getSent({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  }) async {
    final json = await _mainApi.get(
      Endpoints.correspondencesSent,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      },
      operation: 'correspondence.sent',
    );
    return CorrespondenceListResponse.fromJson(json);
  }

  Future<CorrespondenceSentCountResponse> getSentCount() async {
    final json = await _mainApi.get(
      Endpoints.correspondencesSentCount,
      operation: 'correspondence.sentCount',
    );
    return CorrespondenceSentCountResponse.fromJson(json);
  }

  Future<CorrespondenceListResponse> listCorrespondences({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? correspondenceType,
    String? search,
  }) async {
    final json = await _mainApi.get(
      Endpoints.correspondences,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (status != null) 'status': status,
        if (correspondenceType != null) 'correspondence_type': correspondenceType,
        if (search != null && search.isNotEmpty) 'search': search,
      },
      operation: 'correspondence.list',
    );
    return CorrespondenceListResponse.fromJson(json);
  }

  Future<CorrespondenceResponse> getCorrespondence(String id) async {
    final json = await _mainApi.get(
      Endpoints.correspondence(id),
      operation: 'correspondence.detail',
    );
    return CorrespondenceResponse.fromJson(json);
  }

  Future<CorrespondenceResponse> createCorrespondence(
    CreateCorrespondenceRequest request,
  ) async {
    final json = await _mainApi.post(
      Endpoints.correspondences,
      data: request.toJson(),
      operation: 'correspondence.create',
    );
    return CorrespondenceResponse.fromJson(json);
  }

  Future<CorrespondenceResponse> deriveCorrespondence(
    String id,
    DeriveCorrespondenceRequest request,
  ) async {
    final json = await _mainApi.post(
      Endpoints.correspondenceDerive(id),
      data: request.toJson(),
      operation: 'correspondence.derive',
    );
    return CorrespondenceResponse.fromJson(json);
  }

  Future<List<CorrespondenceMovementResponse>> listMovements(String id) async {
    final items = await _mainApi.getList(
      Endpoints.correspondenceMovements(id),
      operation: 'correspondence.movements',
    );
    return items.map(CorrespondenceMovementResponse.fromJson).toList();
  }

  Future<List<CorrespondenceAttachmentResponse>> listAttachments(
    String correspondenceId,
  ) async {
    final items = await _mainApi.getList(
      Endpoints.correspondenceAttachments(correspondenceId),
      operation: 'correspondence.attachments.list',
    );
    return items.map(CorrespondenceAttachmentResponse.fromJson).toList();
  }

  Future<CorrespondenceAttachmentResponse> uploadAttachment({
    required String correspondenceId,
    required String filename,
    required List<int> bytes,
    String? mimeType,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
      ),
    });
    final json = await _mainApi.uploadMultipart(
      Endpoints.correspondenceAttachments(correspondenceId),
      data: formData,
      operation: 'correspondence.attachments.upload',
    );
    return CorrespondenceAttachmentResponse.fromJson(json);
  }

  Future<List<int>> downloadAttachment({
    required String correspondenceId,
    required String attachmentId,
  }) async {
    return _mainApi.downloadBytes(
      path: Endpoints.correspondenceAttachmentDownload(
        correspondenceId,
        attachmentId,
      ),
      operation: 'correspondence.attachments.download',
    );
  }

  Future<CorrespondenceAttachmentResponse> deactivateAttachment({
    required String correspondenceId,
    required String attachmentId,
  }) async {
    final json = await _mainApi.delete(
      Endpoints.correspondenceAttachment(correspondenceId, attachmentId),
      operation: 'correspondence.attachments.deactivate',
    );
    return CorrespondenceAttachmentResponse.fromJson(json);
  }

  Future<List<int>> downloadChainingPdf(String correspondenceId) async {
    return _mainApi.downloadBytes(
      path: Endpoints.correspondenceEncadenamientoPdf(correspondenceId),
      operation: 'correspondence.encadenamientoPdf',
    );
  }
}
