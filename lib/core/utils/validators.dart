abstract final class MaxValidators {
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp _letters = RegExp(
    r'^[\p{L}]+(?: +[\p{L}]+)*$',
    unicode: true,
  );

  static RegExp get lettersAndSpaces => RegExp(r'[\p{L} ]', unicode: true);

  static RegExp get lettersDigitsAndSpaces =>
      RegExp(r'[\p{L}0-9 ]', unicode: true);
  static final RegExp _password = RegExp(
    r'^(?=.*\p{Lu})(?=.*\d)(?=.*[\p{P}\p{S}])\S{9,120}$',
    unicode: true,
  );

  static String? requiredText(String? value, {String label = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) return '$label es obligatorio.';
    return null;
  }

  static String? name(
    String? value, {
    String label = 'El nombre',
    int max = 80,
  }) {
    final required = requiredText(value, label: label);
    if (required != null) return required;
    final trimmed = value!.trim();
    if (trimmed.length > max) return '$label admite hasta $max caracteres.';
    if (!_letters.hasMatch(trimmed)) {
      return '$label solo admite letras y espacios.';
    }
    return null;
  }

  static String? optionalLetters(
    String? value, {
    String label = 'El campo',
    int max = 120,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (trimmed.length > max) return '$label admite hasta $max caracteres.';
    if (!_letters.hasMatch(trimmed)) {
      return '$label solo admite letras y espacios.';
    }
    return null;
  }

  static String? dni(String? value) {
    final trimmed = value?.trim() ?? '';
    if (!RegExp(r'^\d{8}$').hasMatch(trimmed)) {
      return 'El DNI debe contener exactamente 8 números.';
    }
    return null;
  }

  static String? phone(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (!RegExp(r'^\d{7,15}$').hasMatch(trimmed)) {
      return 'El teléfono debe contener de 7 a 15 números.';
    }
    return null;
  }

  static String? email(String? value, {bool required = false}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return required ? 'El correo es obligatorio.' : null;
    return _email.hasMatch(trimmed) ? null : 'Ingresa un correo válido.';
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'La contraseña es obligatoria.';
    if (!_password.hasMatch(password)) {
      return 'Usa 9 o más caracteres, una mayúscula, un número y un signo.';
    }
    return null;
  }
}
