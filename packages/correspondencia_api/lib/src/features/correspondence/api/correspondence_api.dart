import '../../../core/network/api_method.dart';
import '../../../core/network/endpoints.dart';
import '../models/correspondence_list_response.dart';
import '../models/correspondence_movement_response.dart';
import '../models/correspondence_response.dart';
import '../models/create_correspondence_request.dart';
import '../models/derive_correspondence_request.dart';
import '../models/document_type_response.dart';
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
}
