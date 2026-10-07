import 'package:flutter_test/flutter_test.dart';
import 'package:max_mobile/application/app_controller.dart';
import 'package:max_mobile/core/network/api_client.dart';
import 'package:max_mobile/core/utils/validators.dart';
import 'support/fake_api.dart';

void main() {
  group('IAM', () {
    test('rechaza correo inválido y exige correo al registrarse', () {
      expect(MaxValidators.email('bad', required: true), isNotNull);
      expect(MaxValidators.email('', required: true), isNotNull);
      expect(MaxValidators.email('ana@example.test', required: true), isNull);
    });
    test('credenciales inválidas no crean identidad autenticada', () async {
      final api = FakeApi()..loginError = const ApiException('Credenciales incorrectas', statusCode: 401);
      final controller = AppController(api: api);
      expect(await controller.login('ana@example.test', 'wrong'), contains('incorrectas'));
      expect(controller.isAuthenticated, isFalse);
      expect(controller.actionLoading, isFalse);
      controller.dispose();
    });
    test('login y logout limpian datos e identidad', () async {
      final api = FakeApi()..records = [syntheticPatient];
      final controller = AppController(api: api);
      expect(await controller.login('ana@example.test', 'synthetic'), isNull);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.patients, hasLength(1));
      await controller.logout();
      expect(controller.user, isNull);
      expect(controller.patients, isEmpty);
      expect(controller.studies, isEmpty);
      controller.dispose();
    });
    test('contraseña actual incorrecta conserva la sesión', () async {
      final api = FakeApi()..passwordError = const ApiException('Contraseña actual incorrecta', statusCode: 422);
      final controller = AppController(api: api)..user = syntheticUser;
      expect(await controller.changePassword('wrong', 'Synthetic#123'), isNotNull);
      expect(controller.user, syntheticUser);
      expect((api.client as FakeClient).clearCalls, 0);
      controller.dispose();
    });
  });
}
