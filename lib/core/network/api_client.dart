import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});
  final String message;
  final int? statusCode;
  final String? code;
  bool get isUnauthorized => statusCode == 401;
  bool get isConflict => statusCode == 409;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({Dio? dio, FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage(),
      dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 40),
            ),
          ) {
    final parsedBaseUrl = Uri.tryParse(this.dio.options.baseUrl);
    final origin = parsedBaseUrl == null || parsedBaseUrl.host.isEmpty
        ? 'default'
        : parsedBaseUrl.origin;
    _cookieScope = base64Url.encode(utf8.encode(origin)).replaceAll('=', '');
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  final Dio dio;
  final FlutterSecureStorage _storage;
  late final String _cookieScope;
  static const _sessionKeys = ['__Host-max_session', 'max_local_session'];
  static const _csrfKey = 'XSRF-TOKEN';
  static const _cookieRevisionKey = 'max.cookieRevision';
  int _cookieRevision = 0;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.extra[_cookieRevisionKey] = _cookieRevision;
    final cookies = <String>[];
    for (final name in [..._sessionKeys, _csrfKey]) {
      final value = await _storage.read(key: _cookieStorageKey(name));
      if (value != null && value.isNotEmpty) cookies.add('$name=$value');
    }
    if (cookies.isNotEmpty) {
      options.headers[HttpHeaders.cookieHeader] = cookies.join('; ');
    }
    if ({
      'POST',
      'PUT',
      'PATCH',
      'DELETE',
    }.contains(options.method.toUpperCase())) {
      final csrf = await _storage.read(key: _cookieStorageKey(_csrfKey));
      if (csrf != null && csrf.isNotEmpty) {
        options.headers['X-XSRF-TOKEN'] = Uri.decodeComponent(csrf);
      }
    }
    handler.next(options);
  }

  Future<void> _onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    if (_belongsToCurrentSession(response.requestOptions)) {
      await _captureCookies(response.headers.map['set-cookie'] ?? const []);
    }
    handler.next(response);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.response != null &&
        _belongsToCurrentSession(error.requestOptions)) {
      await _captureCookies(
        error.response!.headers.map['set-cookie'] ?? const [],
      );
    }
    final data = error.response?.data;
    var message = 'No se pudo completar la operación.';
    String? code;
    if (data is Map) {
      message = '${data['message'] ?? data['error'] ?? message}';
      code = data['code']?.toString();
      final details = data['details'];
      if (message.toLowerCase().contains('validation failed') &&
          details is List &&
          details.isNotEmpty) {
        message = _validationMessage('${details.first}');
      }
    } else if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      message =
          'No se pudo conectar con el servidor. Verifica que el backend esté activo.';
    } else if (error.type == DioExceptionType.receiveTimeout) {
      message = 'El servidor tardó demasiado en responder.';
    }
    message = _friendlyMessage(message, error.response?.statusCode);
    handler.reject(
      DioException(
        requestOptions: error.requestOptions,
        response: error.response,
        type: error.type,
        error: ApiException(
          message,
          statusCode: error.response?.statusCode,
          code: code,
        ),
      ),
    );
  }

  bool _belongsToCurrentSession(RequestOptions options) =>
      options.extra[_cookieRevisionKey] == _cookieRevision;

  String _cookieStorageKey(String name) => 'cookie.$_cookieScope.$name';

  String _friendlyMessage(String message, int? statusCode) {
    final normalized = message.toLowerCase();
    if (normalized.contains('invalid credentials')) {
      return 'Credenciales incorrectas.';
    }
    if (normalized.contains('invalid current password')) {
      return 'La contraseña actual es incorrecta.';
    }
    if (normalized.contains('current password is required')) {
      return 'Ingresa tu contraseña actual para cambiar el correo.';
    }
    if (normalized.contains('email already registered')) {
      return 'Ese correo ya está registrado.';
    }
    if (normalized.contains('dni') &&
        (normalized.contains('already') || normalized.contains('duplicate'))) {
      return 'Ya existe un paciente registrado con ese DNI.';
    }
    if (normalized.contains('invalid avatar')) {
      return 'El avatar debe ser una imagen JPEG o PNG válida.';
    }
    if (normalized.contains('unsupported file type')) {
      return 'El tipo de archivo no está permitido.';
    }
    if (normalized.contains('file extension does not match') ||
        normalized.contains('file content does not match')) {
      return 'La extensión y el contenido real del archivo no coinciden.';
    }
    if (normalized.contains('invalid file payload')) {
      return 'El archivo está vacío, dañado o no se pudo leer.';
    }
    if (normalized.contains('cannot modify admin') ||
        normalized.contains('admin profile is fixed')) {
      return 'El perfil administrador no se puede modificar desde esta opción.';
    }
    if (statusCode == 409) {
      return 'Los datos cambiaron en otra sesión. Revisa la información y vuelve a intentarlo.';
    }
    if (statusCode == 413) {
      return 'El archivo supera el tamaño permitido.';
    }
    if (statusCode == 429) {
      return 'Demasiados intentos. Espera unos minutos antes de continuar.';
    }
    if (statusCode == 401) {
      return 'Tu sesión venció o fue revocada. Inicia sesión nuevamente.';
    }
    if (statusCode == 403) {
      return 'No tienes permiso para realizar esta operación.';
    }
    if (statusCode == 404) {
      return 'El registro solicitado ya no existe o no está disponible.';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'El servidor no pudo completar la operación. Intenta nuevamente.';
    }
    return message;
  }

  String _validationMessage(String detail) {
    final separator = detail.indexOf(':');
    final field = separator < 0 ? '' : detail.substring(0, separator).trim();
    final rule = separator < 0
        ? detail.trim()
        : detail.substring(separator + 1).trim();
    const labels = {
      'firstName': 'nombres',
      'lastName': 'apellidos',
      'dni': 'DNI',
      'birthDate': 'fecha de nacimiento',
      'sex': 'sexo',
      'phone': 'teléfono',
      'email': 'correo',
      'address': 'dirección',
      'occupation': 'ocupación',
      'password': 'contraseña',
      'currentPassword': 'contraseña actual',
      'newPassword': 'nueva contraseña',
      'fechaHora': 'fecha y hora',
      'pacienteId': 'paciente',
      'tipo': 'tipo de estudio',
      'fecha': 'fecha',
      'maxProfiles': 'límite de perfiles',
    };
    final label = labels[field] ?? (field.isEmpty ? 'los datos' : field);
    final normalized = rule.toLowerCase();
    if (normalized.contains('must not be blank') ||
        normalized.contains('must not be null')) {
      return 'El campo $label es obligatorio.';
    }
    if (normalized.contains('well-formed email')) {
      return 'Ingresa un correo válido.';
    }
    if (normalized.contains('must match')) {
      return 'El campo $label tiene un formato inválido.';
    }
    if (normalized.contains('size must be between')) {
      return 'La longitud del campo $label no es válida.';
    }
    return 'Revisa el campo $label.';
  }

  Future<void> _captureCookies(List<String> values) async {
    for (final header in values) {
      try {
        final cookie = Cookie.fromSetCookieValue(header);
        if (![..._sessionKeys, _csrfKey].contains(cookie.name)) continue;
        if (cookie.value.isEmpty ||
            (cookie.maxAge != null && cookie.maxAge! <= 0)) {
          await _storage.delete(key: _cookieStorageKey(cookie.name));
        } else {
          await _storage.write(
            key: _cookieStorageKey(cookie.name),
            value: cookie.value,
          );
        }
      } on FormatException {
        // Las cookies que no pertenecen a la sesión no forman parte del estado local.
      }
    }
  }

  Future<void> clearSession() async {
    _cookieRevision++;
    for (final name in [..._sessionKeys, _csrfKey]) {
      await _storage.delete(key: _cookieStorageKey(name));
      await _storage.delete(key: 'cookie.$name');
    }
  }

  Never mapError(Object error) {
    if (error is DioException && error.error is ApiException) {
      throw error.error! as ApiException;
    }
    if (error is ApiException) throw error;
    throw const ApiException('Ocurrió un error inesperado.');
  }
}
