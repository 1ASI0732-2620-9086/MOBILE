import 'package:flutter_test/flutter_test.dart';
import 'package:max_mobile/core/utils/validators.dart';

void main() {
  group('validaciones de paciente', () {
    test('DNI acepta exactamente ocho dígitos', () {
      expect(MaxValidators.dni('12345678'), isNull);
      expect(MaxValidators.dni('1234A678'), isNotNull);
      expect(MaxValidators.dni('123'), isNotNull);
    });

    test('nombres no aceptan números ni signos arbitrarios', () {
      expect(MaxValidators.name('María José'), isNull);
      expect(MaxValidators.name("D'Angelo"), isNotNull);
      expect(MaxValidators.name('Oscar123'), isNotNull);
      expect(MaxValidators.name('Oscar@'), isNotNull);
    });

    test('teléfono acepta entre siete y quince dígitos', () {
      expect(MaxValidators.phone('987654321'), isNull);
      expect(MaxValidators.phone('123'), isNotNull);
      expect(MaxValidators.phone('+51987654321'), isNotNull);
    });
  });

  group('seguridad de contraseña', () {
    test('exige longitud, mayúscula, número y signo', () {
      expect(MaxValidators.password('MaxLocal#2026'), isNull);
      expect(MaxValidators.password('maxlocal#2026'), isNotNull);
      expect(MaxValidators.password('MaxLocal2026'), isNotNull);
      expect(MaxValidators.password('Max#1'), isNotNull);
      expect(MaxValidators.password('ÁrbolSeguro#1'), isNull);
      expect(MaxValidators.password('Abcdefgé1'), isNotNull);
    });
  });
}
