typedef Json = Map<String, dynamic>;

int _asInt(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;
int? _asNullableInt(dynamic value) => value == null ? null : _asInt(value);
String? _asNullableString(dynamic value) => value == null ? null : '$value';

class MaxUser {
  const MaxUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.lastLogin,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final String? lastLogin;

  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  factory MaxUser.fromJson(Json json) => MaxUser(
    id: _asInt(json['id'] ?? json['userId']),
    name: '${json['name'] ?? ''}',
    email: '${json['email'] ?? ''}',
    role: '${json['role'] ?? 'USER'}',
    firstName: _asNullableString(json['firstName']),
    lastName: _asNullableString(json['lastName']),
    avatarUrl: _asNullableString(json['avatarUrl']),
    lastLogin: _asNullableString(json['lastLogin']),
  );
}

class Patient {
  const Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dni,
    this.name = '',
    this.birthDate,
    this.sex,
    this.phone,
    this.email,
    this.address,
    this.occupation,
    this.allergies,
    this.diagnosis,
    this.history,
    this.notes,
    this.lastConsultation,
    this.nextConsultation,
    this.risk = 'Bajo',
    this.active = true,
    this.version,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String name;
  final String dni;
  final String? birthDate;
  final String? sex;
  final String? phone;
  final String? email;
  final String? address;
  final String? occupation;
  final String? allergies;
  final String? diagnosis;
  final String? history;
  final String? notes;
  final String? lastConsultation;
  final String? nextConsultation;
  final String risk;
  final bool active;
  final int? version;

  String get fullName =>
      name.trim().isNotEmpty ? name : '$firstName $lastName'.trim();

  factory Patient.fromJson(Json json) => Patient(
    id: _asInt(json['id']),
    firstName: '${json['firstName'] ?? ''}',
    lastName: '${json['lastName'] ?? ''}',
    name: '${json['name'] ?? ''}',
    dni: '${json['dni'] ?? ''}',
    birthDate: _asNullableString(json['birthDate']),
    sex: _asNullableString(json['sex']),
    phone: _asNullableString(json['phone']),
    email: _asNullableString(json['email']),
    address: _asNullableString(json['address']),
    occupation: _asNullableString(json['occupation']),
    allergies: _asNullableString(json['allergies']),
    diagnosis: _asNullableString(json['diagnosis']),
    history: _asNullableString(json['history']),
    notes: _asNullableString(json['notes']),
    lastConsultation: _asNullableString(json['ultimaConsulta']),
    nextConsultation: _asNullableString(json['proximaConsulta']),
    risk: '${json['riesgo'] ?? 'Bajo'}',
    active: json['activo'] != false,
    version: _asNullableInt(json['version']),
  );

  Json toJson() => {
    if (id > 0) 'id': id,
    'firstName': firstName.trim(),
    'lastName': lastName.trim(),
    'name': '$firstName $lastName'.trim(),
    'dni': dni.trim(),
    'birthDate': birthDate,
    'sex': sex,
    'phone': phone,
    'email': email,
    'address': address,
    'occupation': occupation,
    'allergies': allergies,
    'diagnosis': diagnosis,
    'history': history,
    'notes': notes,
    'ultimaConsulta': lastConsultation,
    'proximaConsulta': nextConsultation,
    'riesgo': risk,
    'activo': active,
    if (version != null) 'version': version,
  };
}

class Appointment {
  const Appointment({
    required this.id,
    required this.patientId,
    required this.dateTime,
    required this.reason,
    this.status = 'PROGRAMADA',
    this.notes,
    this.version,
  });

  final int id;
  final int patientId;
  final String dateTime;
  final String reason;
  final String status;
  final String? notes;
  final int? version;

  factory Appointment.fromJson(Json json) => Appointment(
    id: _asInt(json['id']),
    patientId: _asInt(json['pacienteId']),
    dateTime: '${json['fechaHora'] ?? ''}',
    reason: '${json['motivo'] ?? ''}',
    status: '${json['estado'] ?? 'PROGRAMADA'}',
    notes: _asNullableString(json['notas']),
    version: _asNullableInt(json['version']),
  );

  Json toJson() => {
    if (id > 0) 'id': id,
    'pacienteId': patientId,
    'fechaHora': dateTime,
    'motivo': reason,
    'estado': status,
    'notas': notes,
    if (version != null) 'version': version,
  };
}

class Consultation {
  const Consultation({
    required this.id,
    required this.patientId,
    required this.dateTime,
    required this.anamnesis,
    required this.physicalExam,
    required this.auxiliaryExams,
    required this.diagnosis,
    this.appointmentId,
    this.createdAt,
    this.updatedAt,
    this.version,
  });

  final int id;
  final int patientId;
  final int? appointmentId;
  final String dateTime;
  final String anamnesis;
  final String physicalExam;
  final String auxiliaryExams;
  final String diagnosis;
  final String? createdAt;
  final String? updatedAt;
  final int? version;

  factory Consultation.fromJson(Json json) => Consultation(
    id: _asInt(json['id']),
    patientId: _asInt(json['pacienteId']),
    appointmentId: _asNullableInt(json['citaId']),
    dateTime: '${json['fechaHora'] ?? ''}',
    anamnesis: '${json['anamnesis'] ?? ''}',
    physicalExam: '${json['examenFisico'] ?? ''}',
    auxiliaryExams: '${json['examenesAuxiliares'] ?? ''}',
    diagnosis: '${json['diagnostico'] ?? ''}',
    createdAt: _asNullableString(json['createdAt']),
    updatedAt: _asNullableString(json['updatedAt']),
    version: _asNullableInt(json['version']),
  );

  Json toJson() => {
    if (id > 0) 'id': id,
    'pacienteId': patientId,
    'citaId': appointmentId,
    'fechaHora': dateTime,
    'anamnesis': anamnesis,
    'examenFisico': physicalExam,
    'examenesAuxiliares': auxiliaryExams,
    'diagnostico': diagnosis,
    if (createdAt != null) 'createdAt': createdAt,
    if (updatedAt != null) 'updatedAt': updatedAt,
    if (version != null) 'version': version,
  };
}

class Study {
  const Study({
    required this.id,
    required this.patientId,
    required this.type,
    required this.date,
    this.consultationId,
    this.description,
    this.fileName,
    this.fileType,
    this.fileUrl,
    this.fileKey,
    this.createdAt,
    this.updatedAt,
    this.version,
  });

  final int id;
  final int patientId;
  final int? consultationId;
  final String type;
  final String? description;
  final String date;
  final String? fileName;
  final String? fileType;
  final String? fileUrl;
  final String? fileKey;
  final String? createdAt;
  final String? updatedAt;
  final int? version;

  bool get isPdf =>
      (fileType ?? '').toLowerCase().contains('pdf') ||
      (fileName ?? '').toLowerCase().endsWith('.pdf');

  factory Study.fromJson(Json json) => Study(
    id: _asInt(json['id']),
    patientId: _asInt(json['pacienteId']),
    consultationId: _asNullableInt(json['consultaId']),
    type: '${json['tipo'] ?? ''}',
    description: _asNullableString(json['descripcion']),
    date: '${json['fecha'] ?? ''}',
    fileName: _asNullableString(json['archivoNombre']),
    fileType: _asNullableString(json['archivoTipo']),
    fileUrl: _asNullableString(json['archivoUrl']),
    fileKey: _asNullableString(json['archivoKey']),
    createdAt: _asNullableString(json['createdAt']),
    updatedAt: _asNullableString(json['updatedAt']),
    version: _asNullableInt(json['version']),
  );
}

class AdminProfile {
  const AdminProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });
  final int id;
  final int userId;
  final String name;
  final String email;
  final String role;
  final String? createdAt;

  factory AdminProfile.fromJson(Json json) => AdminProfile(
    id: _asInt(json['id']),
    userId: _asInt(json['userId'] ?? json['id']),
    name: '${json['name'] ?? ''}',
    email: '${json['email'] ?? ''}',
    role: '${json['role'] ?? 'USER'}',
    createdAt: _asNullableString(json['createdAt']),
  );
}

class ProfileLimit {
  const ProfileLimit({required this.maxProfiles, required this.usedProfiles});
  final int maxProfiles;
  final int usedProfiles;
  factory ProfileLimit.fromJson(Json json) => ProfileLimit(
    maxProfiles: _asInt(json['maxProfiles']),
    usedProfiles: _asInt(json['usedProfiles']),
  );
}
