import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class UploadTransport extends Fake implements ApiMethod {
  FormData? body;
  @override
  Future<Map<String, dynamic>> uploadMultipart(String path,
      {required FormData data, String? operation}) async {
    body = data;
    return {'id': 'a', 'correspondence_id': 'd', 'is_active': true,
      'created_by_user_id': 'u', 'created_at': '2026-01-01T00:00:00Z'};
  }
}
void main() {
  test('multipart uses PDF signature even when extension is misleading', () async {
    final transport = UploadTransport();
    final api = CorrespondenceApi(mainApi: transport);
    await api.uploadAttachment(correspondenceId: 'd', filename: 'test.bin',
      bytes: '%PDF-1.4'.codeUnits, mimeType: 'bin');
    expect(transport.body!.files.single.value.contentType.toString(), 'application/pdf');
  });
  test('unknown MIME falls back to octet stream, never raw extension', () async {
    final transport = UploadTransport();
    await CorrespondenceApi(mainApi: transport).uploadAttachment(correspondenceId: 'd',
      filename: 'test.unknown', bytes: [0, 1, 2], mimeType: 'unknown');
    expect(transport.body!.files.single.value.contentType.toString(), 'application/octet-stream');
  });
}
