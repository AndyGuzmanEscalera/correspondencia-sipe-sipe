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
          'Usuario: Este campo es obligatorio.\nContraseña: El texto es demasiado corto.');
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
