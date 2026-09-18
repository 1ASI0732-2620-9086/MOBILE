import 'package:flutter_test/flutter_test.dart';
import 'package:max_mobile/domain/models.dart';

void main() {
  test('paciente conserva contrato JSON del backend', () {
    final patient = Patient.fromJson({
      'id': 7,
      'firstName': 'Ana',
      'lastName': 'Pérez',
      'name': 'Ana Pérez',
      'dni': '12345678',
      'birthDate': '1990-01-02',
      'sex': 'Femenino',
      'riesgo': 'Moderado',
      'activo': true,
      'version': 3,
    });

    expect(patient.fullName, 'Ana Pérez');
    expect(patient.toJson()['riesgo'], 'Moderado');
    expect(patient.toJson()['version'], 3);
  });

  test('perfil administrativo usa id como userId compatible', () {
    final profile = AdminProfile.fromJson({
      'id': 12,
      'name': 'Usuario',
      'email': 'usuario@max.pe',
      'role': 'USER',
    });
    expect(profile.userId, 12);
  });
}
