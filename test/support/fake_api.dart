import 'dart:async';
import 'dart:typed_data';
import 'package:max_mobile/core/network/api_client.dart';
import 'package:max_mobile/data/max_api.dart';
import 'package:max_mobile/domain/models.dart';

const syntheticUser = MaxUser(id: 7, name: 'Ana Test', email: 'ana@example.test', role: 'MEDICO');
const syntheticPatient = Patient(id: 10, firstName: 'Ana', lastName: 'Paciente', dni: '87654321', version: 0);
class FakeClient extends ApiClient {
  int clearCalls = 0;
  @override
  Future<void> clearSession() async { clearCalls++; }
}
class FakeApi extends MaxApi {
  FakeApi() : super(FakeClient());
  ApiException? loginError;
  ApiException? saveError;
  ApiException? passwordError;
  Completer<List<Patient>>? pendingPatients;
  Completer<Json>? pendingSave;
  List<Patient> records = [];
  int saves = 0;
  int attentionSaves = 0;
  List<String> uploads = [];
  Set<String> failFiles = {};
  @override Future<void> csrf() async {}
  @override Future<MaxUser> me() async => syntheticUser;
  @override Future<MaxUser> login(String email, String password) async {
    if (loginError != null) throw loginError!;
    return syntheticUser;
  }
  @override Future<void> logout() async { await client.clearSession(); }
  @override Future<List<Patient>> patients() async => pendingPatients == null ? records : pendingPatients!.future;
  @override Future<List<Appointment>> appointments() async => [];
  @override Future<List<Consultation>> consultations() async => [];
  @override Future<List<Study>> studies() async => [];
  @override Future<Json> createPatientWithHistory(Patient patient, String idempotencyKey) async {
    saves++;
    if (saveError != null) throw saveError!;
    if (pendingSave != null) return pendingSave!.future;
    return {};
  }
  @override Future<Patient> updatePatient(Patient patient) async {
    saves++;
    if (saveError != null) throw saveError!;
    return patient;
  }
  @override Future<void> changePassword(String currentPassword, String newPassword) async {
    if (passwordError != null) throw passwordError!;
  }
  @override Future<Json> saveAttention(Consultation consultation, String idempotencyKey) async {
    attentionSaves++;
    return {'consulta': {'id': 20, 'pacienteId': 10, 'fechaHora': '2026-10-07T10:00:00', 'anamnesis': '', 'examenFisico': '', 'examenesAuxiliares': '', 'diagnostico': '', 'version': 0}};
  }
  @override Future<Study> uploadStudy({required int patientId, int? consultationId, required String type, required String date, required String description, required String fileName, required Uint8List bytes}) async {
    uploads.add(fileName);
    if (failFiles.contains(fileName)) throw const ApiException('Fallo sintético');
    return Study(id: 30, patientId: patientId, consultationId: consultationId, type: type, date: date, fileName: fileName);
  }
}
