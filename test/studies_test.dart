import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:max_mobile/application/app_controller.dart';
import 'package:max_mobile/domain/models.dart';
import 'support/fake_api.dart';

void main() {
  group('Studies', () {
    test('conserva relaciones y metadatos del contrato JSON', () {
      final study = Study.fromJson({'id': '30', 'pacienteId': 10, 'consultaId': 20, 'tipo': 'PDF', 'fecha': '2026-10-07', 'archivoNombre': 'test.pdf', 'archivoTipo': 'application/pdf', 'archivoKey': 'historic/key', 'version': 2});
      expect(study.patientId, 10);
      expect(study.consultationId, 20);
      expect(study.fileKey, 'historic/key');
      expect(study.version, 2);
      expect(study.isPdf, isTrue);
    });
    test('identifica imágenes y PDF histórico por extensión', () {
      expect(const Study(id: 1, patientId: 10, type: 'RX', date: '', fileName: 'image.png', fileType: 'image/png').isPdf, isFalse);
      expect(const Study(id: 2, patientId: 10, type: 'PDF', date: '', fileName: 'old.PDF').isPdf, isTrue);
    });
    test('informa archivos fallidos y reintenta sin duplicar atención', () async {
      final api = FakeApi()..failFiles = {'failed.pdf'};
      final controller = AppController(api: api)..user = syntheticUser;
      const consultation = Consultation(id: 0, patientId: 10, dateTime: '2026-10-07T10:00:00', anamnesis: '', physicalExam: '', auxiliaryExams: '', diagnosis: '');
      final files = [StudyUploadDraft(fileName: 'ok.pdf', bytes: Uint8List.fromList([1])), StudyUploadDraft(fileName: 'failed.pdf', bytes: Uint8List.fromList([2]))];
      final first = await controller.saveConsultation(consultation, idempotencyKey: 'synthetic-id', files: files);
      expect(first.consultation!.id, 20);
      expect(first.failedFiles.map((file) => file.fileName), ['failed.pdf']);
      expect(first.error, contains('failed.pdf'));
      api.failFiles.clear();
      final retried = await controller.saveConsultation(first.consultation!, idempotencyKey: 'synthetic-id', files: first.failedFiles, skipAttentionSave: true);
      expect(retried.error, isNull);
      expect(api.attentionSaves, 1);
      expect(api.uploads, ['ok.pdf', 'failed.pdf', 'failed.pdf']);
      controller.dispose();
    });
  });
}
