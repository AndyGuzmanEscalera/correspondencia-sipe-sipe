import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:failures/failures.dart';

import '../entities/correspondence.dart';
import '../entities/correspondence_attachment.dart';
import '../entities/correspondence_movement.dart';
import '../entities/create_correspondence_input.dart';
import '../entities/document_type.dart';
import '../entities/employee_option.dart';
import '../mappers/correspondence_mapper.dart';

class CorrespondenceRepository {
  CorrespondenceRepository({required CorrespondenceApi correspondenceApi})
      : _correspondenceApi = correspondenceApi;

  final CorrespondenceApi _correspondenceApi;

  Future<Result<List<DocumentType>, Failure>> listDocumentTypes() {
    return handleExceptions<List<DocumentType>>(
      () async {
        final items = await _correspondenceApi.listDocumentTypes();
        return items.map((item) => item.toEntity()).toList();
      },
      feature: 'correspondence',
      operation: 'listDocumentTypes',
    );
  }

  Future<Result<List<EmployeeOption>, Failure>> listEmployees() {
    return handleExceptions<List<EmployeeOption>>(
      () async {
        final items = await _correspondenceApi.listEmployees();
        return items.map((item) => item.toEntity()).toList();
      },
      feature: 'correspondence',
      operation: 'listEmployees',
    );
  }

  Future<Result<CorrespondencePage, Failure>> listCorrespondences({
    int page = 1,
    int pageSize = 50,
    String? status,
    String? correspondenceType,
    String? search,
  }) {
    return handleExceptions<CorrespondencePage>(
      () async {
        final response = await _correspondenceApi.listCorrespondences(
          page: page,
          pageSize: pageSize,
          status: status,
          correspondenceType: correspondenceType,
          search: search,
        );
        return response.toEntity();
      },
      feature: 'correspondence',
      operation: 'listCorrespondences',
    );
  }

  Future<Result<Correspondence, Failure>> getCorrespondence(String id) {
    return handleExceptions<Correspondence>(
      () async => (await _correspondenceApi.getCorrespondence(id)).toEntity(),
      feature: 'correspondence',
      operation: 'getCorrespondence',
    );
  }

  Future<Result<Correspondence, Failure>> createCorrespondence(
    CreateCorrespondenceInput input,
  ) {
    return handleExceptions<Correspondence>(
      () async =>
          (await _correspondenceApi.createCorrespondence(input.toRequest()))
              .toEntity(),
      feature: 'correspondence',
      operation: 'createCorrespondence',
    );
  }

  Future<Result<Correspondence, Failure>> deriveCorrespondence(
    String id,
    DeriveCorrespondenceInput input,
  ) {
    return handleExceptions<Correspondence>(
      () async => (await _correspondenceApi.deriveCorrespondence(
            id,
            input.toRequest(),
          ))
          .toEntity(),
      feature: 'correspondence',
      operation: 'deriveCorrespondence',
    );
  }

  Future<Result<List<CorrespondenceMovement>, Failure>> listMovements(
    String id,
  ) {
    return handleExceptions<List<CorrespondenceMovement>>(
      () async {
        final items = await _correspondenceApi.listMovements(id);
        return items.map((item) => item.toEntity()).toList();
      },
      feature: 'correspondence',
      operation: 'listMovements',
    );
  }

  Future<Result<List<CorrespondenceAttachment>, Failure>> listAttachments(
    String correspondenceId,
  ) {
    return handleExceptions<List<CorrespondenceAttachment>>(
      () async {
        final items = await _correspondenceApi.listAttachments(correspondenceId);
        return items.map((item) => item.toEntity()).toList();
      },
      feature: 'correspondence',
      operation: 'listAttachments',
    );
  }

  Future<Result<CorrespondenceAttachment, Failure>> uploadAttachment({
    required String correspondenceId,
    required UploadAttachmentInput input,
  }) {
    return handleExceptions<CorrespondenceAttachment>(
      () async => (await _correspondenceApi.uploadAttachment(
            correspondenceId: correspondenceId,
            filename: input.filename,
            bytes: input.bytes,
            mimeType: input.mimeType,
          ))
          .toEntity(),
      feature: 'correspondence',
      operation: 'uploadAttachment',
    );
  }

  Future<Result<List<int>, Failure>> downloadAttachment({
    required String correspondenceId,
    required String attachmentId,
  }) {
    return handleExceptions<List<int>>(
      () async => _correspondenceApi.downloadAttachment(
        correspondenceId: correspondenceId,
        attachmentId: attachmentId,
      ),
      feature: 'correspondence',
      operation: 'downloadAttachment',
    );
  }

  Future<Result<CorrespondenceAttachment, Failure>> deactivateAttachment({
    required String correspondenceId,
    required String attachmentId,
  }) {
    return handleExceptions<CorrespondenceAttachment>(
      () async => (await _correspondenceApi.deactivateAttachment(
            correspondenceId: correspondenceId,
            attachmentId: attachmentId,
          ))
          .toEntity(),
      feature: 'correspondence',
      operation: 'deactivateAttachment',
    );
  }

  Future<Result<List<int>, Failure>> downloadChainingPdf(String correspondenceId) {
    return handleExceptions<List<int>>(
      () async => _correspondenceApi.downloadChainingPdf(correspondenceId),
      feature: 'correspondence',
      operation: 'downloadChainingPdf',
    );
  }
}
