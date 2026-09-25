import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:dio/dio.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

CorrespondenceApi _apiWithHandler(
  Future<Response<dynamic>> Function(RequestOptions options) handler,
) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, requestHandler) async {
        try {
          final response = await handler(options);
          requestHandler.resolve(response);
        } catch (error) {
          requestHandler.reject(
            DioException(
              requestOptions: options,
              error: error,
            ),
          );
        }
      },
    ),
  );
  return CorrespondenceApi(mainApi: ApiMethod(dio: dio));
}

void main() {
  group('CorrespondenceRepository', () {
    test('listDocumentTypes maps to entities', () async {
      final repo = CorrespondenceRepository(
        correspondenceApi: _apiWithHandler(
          (options) async => Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: [
              {
                'id': 'dt-1',
                'code': 'CARTA',
                'name': 'Carta',
              },
            ],
          ),
        ),
      );

      final result = await repo.listDocumentTypes();

      expect(result.isOk, isTrue);
      expect(result.valueOrNull()?.single.code, 'CARTA');
    });

    test('listCorrespondences maps page', () async {
      final repo = CorrespondenceRepository(
        correspondenceApi: _apiWithHandler(
          (options) async => Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'items': [
                {
                  'id': 'corr-1',
                  'route_number': 'HR-2026-000001',
                  'route_year': 2026,
                  'route_sequence': 1,
                  'correspondence_type': 'EXTERNAL',
                  'document_type_code': 'CARTA',
                  'document_type_name': 'Carta',
                  'subject': 'Prueba',
                  'priority': 'HIGH',
                  'status': 'ACTIVE',
                  'registered_at': '2026-01-15T00:00:00Z',
                },
              ],
              'page': 1,
              'page_size': 20,
              'total': 1,
              'total_pages': 1,
            },
          ),
        ),
      );

      final result = await repo.listCorrespondences();

      expect(result.isOk, isTrue);
      expect(result.valueOrNull()?.items.single.routeNumber, 'HR-2026-000001');
    });

    test('createCorrespondence maps EXTERNAL request body', () async {
      Map<String, dynamic>? capturedBody;
      final repo = CorrespondenceRepository(
        correspondenceApi: _apiWithHandler(
          (options) async {
            if (options.method == 'POST' &&
                options.path.endsWith('/correspondences')) {
              capturedBody = options.data as Map<String, dynamic>?;
              return Response<dynamic>(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'id': 'corr-1',
                  'route_number': 'HR-2026-000001',
                  'route_year': 2026,
                  'route_sequence': 1,
                  'correspondence_type': 'EXTERNAL',
                  'document_type_code': 'CARTA',
                  'document_type_name': 'Carta',
                  'subject': 'Prueba',
                  'priority': 'HIGH',
                  'status': 'ACTIVE',
                  'registered_at': '2026-01-15T00:00:00Z',
                  'created_by_user_id': 'user-1',
                  'created_by_username': 'test',
                },
              );
            }
            return Response<dynamic>(
              requestOptions: options,
              statusCode: 404,
            );
          },
        ),
      );

      final result = await repo.createCorrespondence(
        const CreateCorrespondenceInput(
          correspondenceType: 'EXTERNAL',
          documentTypeId: 'dt-1',
          subject: 'Prueba externa',
          priority: 'HIGH',
          senderName: 'Ciudadano',
          senderDocument: '1234567',
          senderContact: '70000000',
          originDescription: 'Ventanilla',
          initialToUnitId: 'unit-2',
          initialToUserId: 'user-2',
          initialInstruction: 'Atender',
        ),
      );

      expect(result.isOk, isTrue);
      expect(capturedBody?['correspondence_type'], 'EXTERNAL');
      expect(capturedBody?['sender_name'], 'Ciudadano');
      expect(capturedBody?['initial_to_unit_id'], 'unit-2');
      expect(capturedBody?['initial_to_user_id'], 'user-2');
      expect(capturedBody?['initial_instruction'], 'Atender');
    });

    test('createCorrespondence maps INTERNAL request body', () async {
      Map<String, dynamic>? capturedBody;
      final repo = CorrespondenceRepository(
        correspondenceApi: _apiWithHandler(
          (options) async {
            if (options.method == 'POST' &&
                options.path.endsWith('/correspondences')) {
              capturedBody = options.data as Map<String, dynamic>?;
              return Response<dynamic>(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'id': 'corr-2',
                  'route_number': 'HR-2026-000002',
                  'route_year': 2026,
                  'route_sequence': 2,
                  'correspondence_type': 'INTERNAL',
                  'document_type_code': 'MEMO',
                  'document_type_name': 'Memorándum',
                  'subject': 'Interno',
                  'priority': 'MEDIUM',
                  'status': 'ACTIVE',
                  'registered_at': '2026-01-15T00:00:00Z',
                  'origin_unit_id': 'unit-1',
                  'origin_user_id': 'user-1',
                  'created_by_user_id': 'user-1',
                  'created_by_username': 'test',
                },
              );
            }
            return Response<dynamic>(
              requestOptions: options,
              statusCode: 404,
            );
          },
        ),
      );

      final result = await repo.createCorrespondence(
        const CreateCorrespondenceInput(
          correspondenceType: 'INTERNAL',
          documentTypeId: 'dt-2',
          subject: 'Interno',
          priority: 'MEDIUM',
          initialToUnitId: 'unit-2',
        ),
      );

      expect(result.isOk, isTrue);
      expect(capturedBody?['correspondence_type'], 'INTERNAL');
      expect(capturedBody?.containsKey('sender_name'), isFalse);
      expect(capturedBody?['initial_to_unit_id'], 'unit-2');
      expect(capturedBody?.containsKey('initial_to_user_id'), isFalse);
    });

    test('listCorrespondences network error returns Err', () async {
      final repo = CorrespondenceRepository(
        correspondenceApi: _apiWithHandler(
          (options) async => throw const NetworkException('Sin conexión'),
        ),
      );

      final result = await repo.listCorrespondences();

      expect(result.isErr, isTrue);
      expect(result.failureOrNull(), isA<NetworkFailure>());
    });

    test('getInbox maps scope mine to query param', () async {
      String? capturedScope;
      final repo = CorrespondenceRepository(
        correspondenceApi: _apiWithHandler(
          (options) async {
            capturedScope = options.queryParameters['scope'] as String?;
            return Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'items': [],
                'page': 1,
                'page_size': 20,
                'total': 0,
                'total_pages': 0,
              },
            );
          },
        ),
      );

      final result = await repo.getInbox(scope: InboxScope.mine);

      expect(result.isOk, isTrue);
      expect(capturedScope, 'mine');
    });

    test('getInboxUnit maps scope unit to query param', () async {
      String? capturedScope;
      final repo = CorrespondenceRepository(
        correspondenceApi: _apiWithHandler(
          (options) async {
            capturedScope = options.queryParameters['scope'] as String?;
            return Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'items': [],
                'page': 1,
                'page_size': 20,
                'total': 0,
                'total_pages': 0,
              },
            );
          },
        ),
      );

      final result = await repo.getInbox(scope: InboxScope.unit);

      expect(result.isOk, isTrue);
      expect(capturedScope, 'unit');
    });

    test('getInboxCounts maps response', () async {
      final repo = CorrespondenceRepository(
        correspondenceApi: _apiWithHandler(
          (options) async => Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'mine': 4,
              'unit': 12,
            },
          ),
        ),
      );

      final result = await repo.getInboxCounts();

      expect(result.isOk, isTrue);
      expect(result.valueOrNull()?.mine, 4);
      expect(result.valueOrNull()?.unit, 12);
    });
  });
}
