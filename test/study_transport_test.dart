import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:max_mobile/core/network/api_client.dart';
import 'package:max_mobile/data/max_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  for (final entry in {
    '2026-10-07': '2026-10-07T00:00:00',
    '2026-10-07T16:45:00': '2026-10-07T16:45:00',
  }.entries) {
    test('multipart conserva el día y el contrato de fecha/hora: ${entry.key}', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:18080/api'));
      final api = MaxApi(ApiClient(dio: dio));
      FormData? sent;
      dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
        sent = request.data as FormData;
        handler.resolve(Response(requestOptions: request, statusCode: 201, data: {
          'id': 1, 'pacienteId': 10, 'tipo': 'PDF', 'fecha': entry.value,
        }));
      }));
      final study = await api.uploadStudy(patientId: 10, type: 'PDF', date: entry.key,
        description: 'Documento sintético', fileName: 'synthetic.pdf',
        bytes: Uint8List.fromList('%PDF-1.7\n%%EOF'.codeUnits));
      expect(sent!.fields.singleWhere((field) => field.key == 'fecha').value, entry.value);
      expect(sent!.fields.singleWhere((field) => field.key == 'pacienteId').value, '10');
      expect(study.patientId, 10);
      expect(sent!.files.single.value.contentType.toString(), 'application/pdf');
    });
  }
}
