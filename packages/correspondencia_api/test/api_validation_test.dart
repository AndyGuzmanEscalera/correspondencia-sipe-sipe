import 'dart:convert';
import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:dio/dio.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.body);
  final int status;
  final Object body;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(RequestOptions options,
          Stream<List<int>>? requestStream, Future<void>? cancelFuture) async =>
      ResponseBody.fromString(jsonEncode(body), status, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      });
}

void main() {
  final cases = [
    (
      'initial_password',
      'string_too_short',
      {'min_length': 8},
      'Contraseña inicial: Debe tener al menos 8 caracteres.'
    ),
    (
      'new_password',
      'string_too_long',
      {'max_length': 255},
      'Nueva contraseña: Debe tener como máximo 255 caracteres.'
    ),
    (
      'username',
      'string_too_long',
      {'max_length': 50},
      'Usuario: Debe tener como máximo 50 caracteres.'
    ),
    (
      'name',
      'string_too_short',
      {'min_length': 1},
      'Nombre: Debe tener al menos 1 carácter.'
    ),
    (
      'page_count',
      'greater_than',
      {'gt': 0},
      'Número de hojas: Debe ser mayor que 0.'
    ),
    (
      'email',
      'value_error',
      {},
      'Correo: Ingrese un correo electrónico válido.'
    ),
    (
      'role_ids',
      'too_short',
      {'min_length': 1},
      'Roles: Seleccione al menos 1 opción.'
    ),
  ];
  for (final (field, type, context, expected) in cases) {
    test('mensaje de $field incluye su regla sin exponer input', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
        ..httpClientAdapter = _Adapter(422, {
          'detail': [
            {
              'loc': ['body', field],
              'type': type,
              'ctx': context,
              'input': 'PRIVATE_INPUT',
              'msg': 'PRIVATE_MESSAGE',
            }
          ]
        });
      final result =
          await handleExceptions(() => ApiMethod(dio: dio).post('/validation'));
      expect(result.failureOrNull()?.message, expected);
      dio.close();
    });
  }
  test('500 HTTP con CORS se interpreta como ServerFailure', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = _Adapter(500, {'detail': 'PRIVATE_TRACE'});
    final result =
        await handleExceptions(() => ApiMethod(dio: dio).patch('/test-error'));
    expect(result.failureOrNull(), isA<ServerFailure>());
    expect(result.failureOrNull(), isNot(isA<NetworkFailure>()));
    expect(result.failureOrNull()!.message,
        'Error del servidor. Intente nuevamente.');
    dio.close();
  });

  for (final acceptStatus in [true, false]) {
    test(
        '422 atraviesa API, Result y FailureGeneric (validateStatus=$acceptStatus)',
        () async {
      final dio = Dio(BaseOptions(
          baseUrl: 'http://localhost',
          validateStatus: acceptStatus ? (_) => true : null))
        ..httpClientAdapter = _Adapter(422, {
          'detail': [
            {
              'loc': ['body', 'username'],
              'type': 'missing',
              'msg': 'Field required',
              'input': 'SECRET_INPUT'
            },
            {
              'loc': ['body', 'password'],
              'type': 'string_too_short',
              'msg': 'INTERNAL_TRACE',
              'ctx': {'min_length': 12}
            },
          ]
        });
      final result =
          await handleExceptions(() => ApiMethod(dio: dio).post('/auth/login'));
      final failure = result.failureOrNull();
      expect(failure, isA<ValidationFailure>());
      expect(FailureGeneric.message(failure: failure!),
          'Usuario: Este campo es obligatorio.\nContraseña: Debe tener al menos 12 caracteres.');
      dio.close();
    });
  }
  test('422 de dominio conserva mensaje útil', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = _Adapter(
          422, {'detail': 'Seleccione un funcionario destino específico.'});
    final result = await handleExceptions(
        () => ApiMethod(dio: dio).get('/institutional-mayor'));
    expect(result.failureOrNull()?.message,
        'Seleccione un funcionario destino específico.');
    dio.close();
  });
  test('respuesta cruda y errores técnicos no se muestran al usuario',
      () async {
    for (final status in [422, 500]) {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
        ..httpClientAdapter = _Adapter(status, 'TRACEBACK SQL password=secret');
      final result =
          await handleExceptions(() => ApiMethod(dio: dio).get('/admin/users'));
      expect(FailureGeneric.message(failure: result.failureOrNull()!),
          isNot(contains('secret')));
      dio.close();
    }
  });
}
