import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/network/api_client.dart';
import '../data/max_api.dart';
import '../domain/models.dart';

enum AppLoadState { pending, loading, ready, error }

class StudyUploadDraft {
  const StudyUploadDraft({required this.fileName, required this.bytes});
  final String fileName;
  final Uint8List bytes;
}

class ConsultationSaveResult {
  const ConsultationSaveResult({
    this.error,
    this.consultation,
    this.failedFiles = const [],
  });
  final String? error;
  final Consultation? consultation;
  final List<StudyUploadDraft> failedFiles;
}

class AppController extends ChangeNotifier {
  AppController({MaxApi? api}) : api = api ?? MaxApi(ApiClient());

  final MaxApi api;
  final _uuid = const Uuid();
  late SharedPreferences _preferences;
  int _sessionRevision = 0;
  static const _sessionChangedMessage =
      'La sesión cambió durante la operación. Revisa el usuario actual.';

  AppLoadState state = AppLoadState.pending;
  MaxUser? user;
  String? errorMessage;
  bool actionLoading = false;
  bool darkMode = false;
  bool largeText = false;
  bool notificationsEnabled = true;
  String language = 'es';

  List<Patient> patients = [];
  List<Appointment> appointments = [];
  List<Consultation> consultations = [];
  List<Study> studies = [];
  List<AdminProfile> adminProfiles = [];
  ProfileLimit? profileLimit;

  bool get isAuthenticated => user != null;

  Future<void> initialize() async {
    final revision = ++_sessionRevision;
    state = AppLoadState.loading;
    notifyListeners();
    _preferences = await SharedPreferences.getInstance();
    darkMode = _preferences.getBool('darkMode') ?? false;
    largeText = _preferences.getBool('largeText') ?? false;
    notificationsEnabled = _preferences.getBool('notificationsEnabled') ?? true;
    language = _preferences.getString('language') ?? 'es';
    try {
      await api.csrf();
      final restored = await api.me();
      if (revision != _sessionRevision) return;
      await _loadClinicalForRevision(revision);
      if (revision != _sessionRevision) return;
      user = restored;
      state = AppLoadState.ready;
    } on ApiException catch (error) {
      if (revision != _sessionRevision) return;
      if (error.isUnauthorized) {
        await api.client.clearSession();
        user = null;
        state = AppLoadState.ready;
      } else {
        state = AppLoadState.error;
        errorMessage = error.message;
      }
    } finally {
      notifyListeners();
    }
  }

  Future<String?> login(String email, String password) async {
    return _sessionAction(() async {
      final authenticated = await api.login(email, password);
      await _activateUser(authenticated);
    });
  }

  Future<String?> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    return _sessionAction(() async {
      final authenticated = await api.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );
      await _activateUser(authenticated);
    });
  }

  Future<void> _activateUser(MaxUser nextUser) async {
    final revision = ++_sessionRevision;
    _clearClinical();
    user = null;
    try {
      await api.csrf();
      await _loadClinicalForRevision(revision);
      if (revision != _sessionRevision) return;
      user = nextUser;
    } catch (_) {
      if (revision == _sessionRevision) {
        ++_sessionRevision;
        await api.logout();
        user = null;
        _clearClinical();
      }
      rethrow;
    }
  }

  Future<String?> _sessionAction(Future<void> Function() action) async {
    if (actionLoading) return 'Hay una operación en curso.';
    actionLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      state = AppLoadState.ready;
      return null;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return error.message;
    } finally {
      actionLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    actionLoading = true;
    notifyListeners();
    ++_sessionRevision;
    await api.logout();
    user = null;
    adminProfiles = [];
    profileLimit = null;
    _clearClinical();
    actionLoading = false;
    state = AppLoadState.ready;
    notifyListeners();
  }

  void _clearClinical() {
    patients = [];
    appointments = [];
    consultations = [];
    studies = [];
  }

  Future<void> _loadClinicalForRevision(int revision) async {
    final results = await Future.wait([
      api.patients(),
      api.appointments(),
      api.consultations(),
      api.studies(),
    ]);
    if (revision != _sessionRevision) return;
    patients = results[0] as List<Patient>;
    appointments = results[1] as List<Appointment>;
    consultations = results[2] as List<Consultation>;
    studies = results[3] as List<Study>;
  }

  Future<String?> refreshClinical() => _execute((revision) async {
    await _loadClinicalForRevision(revision);
  });

  Future<String?> savePatient(Patient patient, {String? idempotencyKey}) =>
      _execute((revision) async {
        if (patient.id > 0) {
          await api.updatePatient(patient);
        } else {
          await api.createPatientWithHistory(
            patient,
            idempotencyKey ?? _uuid.v4(),
          );
        }
        await _loadClinicalForRevision(revision);
      });

  Future<String?> deletePatient(Patient patient) => _execute((revision) async {
    await api.deletePatient(patient.id);
    await _loadClinicalForRevision(revision);
  });

  Future<String?> saveAppointment(Appointment appointment) =>
      _execute((revision) async {
        await api.saveAppointment(appointment);
        await _loadClinicalForRevision(revision);
      });

  Future<String?> deleteAppointment(Appointment appointment) =>
      _execute((revision) async {
        await api.deleteAppointment(appointment.id);
        await _loadClinicalForRevision(revision);
      });

  Future<ConsultationSaveResult> saveConsultation(
    Consultation consultation, {
    required String idempotencyKey,
    List<StudyUploadDraft> files = const [],
    String? studyType,
    String studyDescription = '',
    bool skipAttentionSave = false,
  }) async {
    if (actionLoading) {
      return const ConsultationSaveResult(error: 'Hay una operación en curso.');
    }
    actionLoading = true;
    errorMessage = null;
    final revision = _sessionRevision;
    notifyListeners();
    try {
      var persisted = consultation;
      if (!skipAttentionSave) {
        final result = await api.saveAttention(consultation, idempotencyKey);
        if (revision != _sessionRevision) {
          return ConsultationSaveResult(
            error: _sessionChangedMessage,
            failedFiles: files,
          );
        }
        final persistedJson = result['consulta'];
        if (persistedJson is! Map) {
          throw const ApiException(
            'El servidor no devolvió la atención guardada.',
          );
        }
        persisted = Consultation.fromJson(
          Map<String, dynamic>.from(persistedJson),
        );
      }
      if (persisted.id <= 0) {
        throw const ApiException(
          'No se pudo identificar la atención para asociar sus archivos.',
        );
      }
      final failed = <StudyUploadDraft>[];
      for (final file in files) {
        if (revision != _sessionRevision) {
          return ConsultationSaveResult(
            error: _sessionChangedMessage,
            consultation: persisted,
            failedFiles: files,
          );
        }
        try {
          await api.uploadStudy(
            patientId: persisted.patientId,
            consultationId: persisted.id,
            type: studyType ?? 'PDF',
            date: persisted.dateTime.length >= 10
                ? persisted.dateTime.substring(0, 10)
                : DateTime.now().toIso8601String().substring(0, 10),
            description: studyDescription,
            fileName: file.fileName,
            bytes: file.bytes,
          );
        } on ApiException {
          failed.add(file);
        }
      }
      await _loadClinicalForRevision(revision);
      if (revision != _sessionRevision) {
        return ConsultationSaveResult(
          error: _sessionChangedMessage,
          consultation: persisted,
          failedFiles: failed,
        );
      }
      if (failed.isNotEmpty) {
        final failedNames = failed.map((file) => file.fileName).join(', ');
        final message =
            'La atención se guardó, pero no se pudieron cargar: $failedNames. Reintenta para cargar solo esos archivos.';
        errorMessage = message;
        return ConsultationSaveResult(
          error: message,
          consultation: persisted,
          failedFiles: failed,
        );
      }
      return ConsultationSaveResult(consultation: persisted);
    } on ApiException catch (error) {
      if (revision != _sessionRevision) {
        return ConsultationSaveResult(
          error: _sessionChangedMessage,
          failedFiles: files,
        );
      }
      errorMessage = error.message;
      if (error.isUnauthorized) {
        ++_sessionRevision;
        await api.client.clearSession();
        user = null;
        _clearClinical();
      }
      return ConsultationSaveResult(
        error: error.message,
        consultation: consultation.id > 0 ? consultation : null,
        failedFiles: files,
      );
    } finally {
      actionLoading = false;
      notifyListeners();
    }
  }

  Future<String?> deleteConsultation(Consultation consultation) =>
      _execute((revision) async {
        await api.deleteConsultation(consultation.id);
        await _loadClinicalForRevision(revision);
      });

  Future<String?> uploadStudy({
    required int patientId,
    int? consultationId,
    required String type,
    required String date,
    required String description,
    required String fileName,
    required Uint8List bytes,
  }) => _execute((revision) async {
    await api.uploadStudy(
      patientId: patientId,
      consultationId: consultationId,
      type: type,
      date: date,
      description: description,
      fileName: fileName,
      bytes: bytes,
    );
    await _loadClinicalForRevision(revision);
  });

  Future<String?> deleteStudy(Study study) => _execute((revision) async {
    await api.deleteStudy(study.id);
    await _loadClinicalForRevision(revision);
  });

  Future<Uri> studyAccessUrl(Study study) async {
    final revision = _sessionRevision;
    try {
      final uri = await api.studyAccessUrl(study.id);
      if (revision != _sessionRevision) {
        throw const ApiException(_sessionChangedMessage);
      }
      return uri;
    } on ApiException catch (error) {
      if (revision == _sessionRevision && error.isUnauthorized) {
        ++_sessionRevision;
        await api.client.clearSession();
        user = null;
        _clearClinical();
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<String?> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    String? avatarUrl,
    String? currentPassword,
  }) => _execute((revision) async {
    final updated = await api.updateProfile({
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'email': email.trim(),
      'avatarUrl': avatarUrl,
      if (currentPassword != null && currentPassword.isNotEmpty)
        'currentPassword': currentPassword,
    });
    if (revision == _sessionRevision) user = updated;
  });

  Future<String?> changePassword(String currentPassword, String newPassword) =>
      _execute((revision) async {
        await api.changePassword(currentPassword, newPassword);
        if (revision != _sessionRevision) return;
        await api.csrf();
        final refreshed = await api.me();
        if (revision == _sessionRevision) user = refreshed;
      });

  Future<String?> loadAdmin() => _execute((revision) async {
    final results = await Future.wait([
      api.adminProfiles(),
      api.profileLimit(),
    ]);
    if (revision == _sessionRevision) {
      adminProfiles = results[0] as List<AdminProfile>;
      profileLimit = results[1] as ProfileLimit;
    }
  }, handleUnauthorized: true);

  Future<String?> updateLimit(int maxProfiles) => _execute((revision) async {
    final updated = await api.updateProfileLimit(maxProfiles);
    if (revision == _sessionRevision) profileLimit = updated;
  });

  Future<String?> impersonate(AdminProfile profile) => _execute((_) async {
    final nextUser = await api.impersonate(profile.userId);
    await _activateUser(nextUser);
    adminProfiles = [];
    profileLimit = null;
  }, changesSession: true);

  Future<String?> deleteAdminProfile(AdminProfile profile) =>
      _execute((revision) async {
        await api.deleteProfile(profile.userId);
        final results = await Future.wait([
          api.adminProfiles(),
          api.profileLimit(),
        ]);
        if (revision == _sessionRevision) {
          adminProfiles = results[0] as List<AdminProfile>;
          profileLimit = results[1] as ProfileLimit;
        }
      });

  Future<String?> _execute(
    Future<void> Function(int revision) action, {
    bool handleUnauthorized = true,
    bool changesSession = false,
  }) async {
    if (actionLoading) return 'Hay una operación en curso.';
    actionLoading = true;
    errorMessage = null;
    final revision = _sessionRevision;
    notifyListeners();
    try {
      await action(revision);
      if (!changesSession && revision != _sessionRevision) {
        return _sessionChangedMessage;
      }
      return null;
    } on ApiException catch (error) {
      if (!changesSession && revision != _sessionRevision) {
        return _sessionChangedMessage;
      }
      errorMessage = error.message;
      if (handleUnauthorized && error.isUnauthorized) {
        ++_sessionRevision;
        await api.client.clearSession();
        user = null;
        _clearClinical();
      }
      return error.message;
    } finally {
      actionLoading = false;
      notifyListeners();
    }
  }

  Patient? patientById(int id) {
    for (final patient in patients) {
      if (patient.id == id) return patient;
    }
    return null;
  }

  Future<void> setDarkMode(bool value) async {
    darkMode = value;
    await _preferences.setBool('darkMode', value);
    notifyListeners();
  }

  Future<void> setLargeText(bool value) async {
    largeText = value;
    await _preferences.setBool('largeText', value);
    notifyListeners();
  }

  Future<void> setNotifications(bool value) async {
    notificationsEnabled = value;
    await _preferences.setBool('notificationsEnabled', value);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    language = value;
    await _preferences.setString('language', value);
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope no está disponible.');
    return scope!.notifier!;
  }
}
