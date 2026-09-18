import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mime/mime.dart';

import '../core/network/api_client.dart';
import '../domain/models.dart';

class MaxApi {
  MaxApi(this.client);
  final ApiClient client;

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      client.mapError(error);
    }
  }

  Json _json(dynamic data) => Map<String, dynamic>.from(data as Map);
  List<Json> _list(dynamic data) =>
      (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  Future<void> csrf() => _call(() async {
    await client.dio.get<void>('/auth/csrf');
  });

  Future<MaxUser> login(String email, String password) => _call(() async {
    await csrf();
    final response = await client.dio.post(
      '/auth/login',
      data: {'email': email.trim(), 'password': password},
    );
    final data = _json(response.data);
    return MaxUser.fromJson(_json(data['user']));
  });

  Future<MaxUser> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) => _call(() async {
    await csrf();
    final response = await client.dio.post(
      '/auth/register',
      data: {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim(),
        'password': password,
      },
    );
    final data = _json(response.data);
    return MaxUser.fromJson(_json(data['user']));
  });

  Future<MaxUser> me() => _call(() async {
    final response = await client.dio.get('/auth/me');
    return MaxUser.fromJson(_json(response.data));
  });

  Future<void> logout() async {
    try {
      await csrf();
      await client.dio.post<void>('/auth/logout');
    } catch (_) {
      // La sesión local siempre se elimina, aunque el servidor no responda.
    } finally {
      await client.clearSession();
    }
  }

  Future<MaxUser> updateProfile(Json payload) => _call(() async {
    final response = await client.dio.put('/auth/me/profile', data: payload);
    return MaxUser.fromJson(_json(response.data));
  });

  Future<void> changePassword(String currentPassword, String newPassword) =>
      _call(() async {
        await client.dio.put<void>(
          '/auth/me/password',
          data: {
            'currentPassword': currentPassword,
            'newPassword': newPassword,
          },
        );
      });

  Future<List<Patient>> patients() => _call(() async {
    final response = await client.dio.get('/pacientes');
    return _list(response.data).map(Patient.fromJson).toList();
  });

  Future<Json> createPatientWithHistory(
    Patient patient,
    String idempotencyKey,
  ) => _call(() async {
    final response = await client.dio.post(
      '/pacientes/con-historial',
      data: patient.toJson(),
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    return _json(response.data);
  });

  Future<Patient> updatePatient(Patient patient) => _call(() async {
    final response = await client.dio.put(
      '/pacientes/${patient.id}',
      data: patient.toJson(),
    );
    return Patient.fromJson(_json(response.data));
  });

  Future<void> deletePatient(int id) => _call(() async {
    await client.dio.delete<void>('/pacientes/$id');
  });

  Future<List<Appointment>> appointments() => _call(() async {
    final response = await client.dio.get('/citas');
    return _list(response.data).map(Appointment.fromJson).toList();
  });

  Future<Appointment> saveAppointment(Appointment appointment) =>
      _call(() async {
        final response = appointment.id > 0
            ? await client.dio.put(
                '/citas/${appointment.id}',
                data: appointment.toJson(),
              )
            : await client.dio.post('/citas', data: appointment.toJson());
        return Appointment.fromJson(_json(response.data));
      });

  Future<void> deleteAppointment(int id) => _call(() async {
    await client.dio.delete<void>('/citas/$id');
  });

  Future<List<Consultation>> consultations() => _call(() async {
    final response = await client.dio.get('/consultas');
    return _list(response.data).map(Consultation.fromJson).toList();
  });

  Future<Json> saveAttention(
    Consultation consultation,
    String idempotencyKey,
  ) => _call(() async {
    final path = consultation.id > 0
        ? '/consultas/${consultation.id}/atencion'
        : '/consultas/atencion';
    final options = Options(headers: {'Idempotency-Key': idempotencyKey});
    final response = consultation.id > 0
        ? await client.dio.put(
            path,
            data: consultation.toJson(),
            options: options,
          )
        : await client.dio.post(
            path,
            data: consultation.toJson(),
            options: options,
          );
    return _json(response.data);
  });

  Future<void> deleteConsultation(int id) => _call(() async {
    await client.dio.delete<void>('/consultas/$id');
  });

  Future<List<Study>> studies() => _call(() async {
    final response = await client.dio.get('/estudios');
    return _list(response.data).map(Study.fromJson).toList();
  });

  Future<Study> uploadStudy({
    required int patientId,
    int? consultationId,
    required String type,
    required String date,
    required String description,
    required String fileName,
    required Uint8List bytes,
  }) => _call(() async {
    final detectedMime = lookupMimeType(
      fileName,
      headerBytes: bytes.take(16).toList(),
    );
    if (detectedMime == null) {
      throw const ApiException('No se pudo identificar el tipo del archivo.');
    }
    final form = FormData.fromMap({
      'pacienteId': patientId,
      'consultaId': ?consultationId,
      'tipo': type,
      'descripcion': description,
      'fecha': date,
      'file': MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: DioMediaType.parse(detectedMime),
      ),
    });
    final response = await client.dio.post(
      '/estudios',
      data: form,
      options: Options(
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
      ),
    );
    return Study.fromJson(_json(response.data));
  });

  Future<void> deleteStudy(int id) => _call(() async {
    await client.dio.delete<void>('/estudios/$id');
  });

  Future<Uri> studyAccessUrl(int id) => _call(() async {
    final response = await client.dio.get('/estudios/$id/access-url');
    final data = _json(response.data);
    return Uri.parse('${data['url'] ?? data['accessUrl'] ?? ''}');
  });

  Future<List<AdminProfile>> adminProfiles() => _call(() async {
    final response = await client.dio.get('/admin/profiles');
    return _list(response.data).map(AdminProfile.fromJson).toList();
  });

  Future<ProfileLimit> profileLimit() => _call(() async {
    final response = await client.dio.get('/admin/profiles/limit');
    return ProfileLimit.fromJson(_json(response.data));
  });

  Future<ProfileLimit> updateProfileLimit(int maxProfiles) => _call(() async {
    final response = await client.dio.put(
      '/admin/profiles/limit',
      data: {'maxProfiles': maxProfiles},
    );
    return ProfileLimit.fromJson(_json(response.data));
  });

  Future<MaxUser> impersonate(int userId) => _call(() async {
    final response = await client.dio.post(
      '/admin/profiles/$userId/impersonate',
    );
    final data = _json(response.data);
    return MaxUser.fromJson(_json(data['user']));
  });

  Future<void> deleteProfile(int userId) => _call(() async {
    await client.dio.delete<void>('/admin/profiles/$userId');
  });

  static String avatarDataUrl(Uint8List bytes, String mimeType) =>
      'data:$mimeType;base64,${base64Encode(bytes)}';
}
