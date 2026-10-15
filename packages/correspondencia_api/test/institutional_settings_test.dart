import 'dart:convert';
import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  RequestOptions? request;
  Object body = {
    'mayor_employee_id': 'employee-a',
    'mayor': {
      'employee_id': 'employee-a',
      'employee_name': 'Autoridad',
      'position_name': 'Cargo',
      'unit_name': 'Unidad',
      'document_number': '123'
    }
  };
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    request = options;
    return ResponseBody.fromString(jsonEncode(body), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType]
    });
  }
}

void main() {
  test('settings serializa referencia y datos institucionales', () async {
    final adapter = _Adapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = adapter;
    final api = SystemSettingsAdminApi(mainApi: ApiMethod(dio: dio));
    final result =
        await api.updateInstitutionalSettings(mayorEmployeeId: 'employee-a');
    expect(adapter.request!.data, {'mayor_employee_id': 'employee-a'});
    expect(result.mayor!.documentNumber, '123');
    expect(
        InstitutionalSettingsResponse.fromJson(result.toJson()).mayor!.unitName,
        'Unidad');
    await api.updateInstitutionalSettings(mayorEmployeeId: null);
    expect(adapter.request!.data, {'mayor_employee_id': null});
    await api.updateInstitutionalSettings(
        mayorEmployeeId: 'employee-a', mayorDisplayName: 'Texto institucional');
    expect(adapter.request!.data, {
      'mayor_employee_id': 'employee-a',
      'mayor_display_name': 'Texto institucional'
    });
    await api.updateInstitutionalSettings(
        mayorEmployeeId: 'employee-a', mayorDisplayName: '');
    expect(adapter.request!.data,
        {'mayor_employee_id': 'employee-a', 'mayor_display_name': ''});
    await api.updateDocumentAuthorityName("Fredy Patzi Barrios");
    expect(
        adapter.request!.data, {"mayor_display_name": "Fredy Patzi Barrios"});
    dio.close();
  });
  test('correo se deserializa y puede enviarse o limpiarse sin afectar omision',
      () async {
    final adapter = _Adapter()
      ..body = {'institutional_email': 'contacto@sipesipe.gob.bo'};
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = adapter;
    final api = SystemSettingsAdminApi(mainApi: ApiMethod(dio: dio));
    final loaded = await api.getInstitutionalSettings();
    expect(loaded.institutionalEmail, 'contacto@sipesipe.gob.bo');
    expect(
        InstitutionalSettingsResponse.fromJson(loaded.toJson())
            .institutionalEmail,
        loaded.institutionalEmail);
    for (final email in ['nuevo@sipesipe.gob.bo', '']) {
      await api.updateInstitutionalSettings(
          mayorEmployeeId: null, institutionalEmail: email);
      expect(adapter.request!.data['institutional_email'], email);
    }
    expect(
        InstitutionalSettingsResponse.fromJson({}).institutionalEmail, isNull);
    dio.close();
  });
  test('catálogo de autoridad usa endpoint de settings', () async {
    final adapter = _Adapter()
      ..body = [
        {
          'employee_id': 'employee-a',
          'employee_name': 'Autoridad',
          'position_name': 'Cargo',
          'unit_name': 'Unidad'
        }
      ];
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = adapter;
    final result = await SystemSettingsAdminApi(mainApi: ApiMethod(dio: dio))
        .getAuthorityEmployees();
    expect(adapter.request!.path, '/admin/system-settings/authority-employees');
    expect(result.single.employeeId, 'employee-a');
    dio.close();
  });
}
