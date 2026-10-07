import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:max_mobile/application/app_controller.dart';
import 'package:max_mobile/core/network/api_client.dart';
import 'package:max_mobile/domain/models.dart';
import 'support/fake_api.dart';

void main() {
  group('Patients', () {
    test('nombres y DNI se normalizan sin cambiar identidad o versión', () {
      final patient = Patient.fromJson({'id': 10, 'firstName': ' Ana ', 'lastName': ' Prueba ', 'dni': ' 87654321 ', 'version': 3});
      final json = patient.toJson();
      expect(json['id'], 10);
      expect(json['version'], 3);
      expect(json['firstName'], 'Ana');
      expect(json['dni'], '87654321');
    });
    test('registro inexistente y listado vacío mantienen estado vacío', () {
      final controller = AppController(api: FakeApi());
      expect(controller.patientById(99), isNull);
      expect(controller.patients, isEmpty);
      controller.dispose();
    });
    test('un fallo de persistencia no agrega pacientes ficticios', () async {
      final api = FakeApi()..saveError = const ApiException('Fallo de red', statusCode: 503);
      final controller = AppController(api: api)..user = syntheticUser;
      expect(await controller.savePatient(syntheticPatient), contains('Fallo'));
      expect(controller.patients, isEmpty);
      expect(controller.user, syntheticUser);
      controller.dispose();
    });
    test('bloquea doble envío mientras la operación está pendiente', () async {
      final api = FakeApi()..pendingSave = Completer<Json>();
      final controller = AppController(api: api);
      const newPatient = Patient(id: 0, firstName: 'Ana', lastName: 'Prueba', dni: '87654321');
      final pending = controller.savePatient(newPatient);
      expect(await controller.savePatient(newPatient), contains('operación en curso'));
      expect(api.saves, 1);
      api.pendingSave!.complete({});
      await pending;
      controller.dispose();
    });
    test('descarta pacientes recibidos después del logout', () async {
      final api = FakeApi()..pendingPatients = Completer<List<Patient>>();
      final controller = AppController(api: api)..user = syntheticUser;
      final pending = controller.refreshClinical();
      await controller.logout();
      api.pendingPatients!.complete([syntheticPatient]);
      await pending;
      expect(controller.user, isNull);
      expect(controller.patients, isEmpty);
      controller.dispose();
    });
  });
}
