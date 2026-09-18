import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

import '../../application/app_controller.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/max_widgets.dart';
import '../../domain/models.dart';
import '../shared/clinical_history_dialog.dart';
import '../shared/study_viewer.dart';

class ConsultationsScreen extends StatefulWidget {
  const ConsultationsScreen({super.key});

  @override
  State<ConsultationsScreen> createState() => _ConsultationsScreenState();
}

class _ConsultationsScreenState extends State<ConsultationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _nameSearch = TextEditingController();
  final _dniSearch = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nameSearch.dispose();
    _dniSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final patientIds = _matchingPatientIds(controller);
    final appointments =
        controller.appointments
            .where((item) => patientIds.contains(item.patientId))
            .toList()
          ..sort((a, b) => compareDateTimeDescending(a.dateTime, b.dateTime));
    final consultations =
        controller.consultations
            .where((item) => patientIds.contains(item.patientId))
            .toList()
          ..sort((a, b) => compareDateTimeDescending(a.dateTime, b.dateTime));

    return MaxPage(
      title: 'Consultas',
      subtitle: 'Agenda y atenciones clínicas',
      action: IconButton.filled(
        tooltip: _tabs.index == 0 ? 'Nueva cita' : 'Nueva atención',
        onPressed: controller.patients.isEmpty
            ? null
            : () => _tabs.index == 0 ? _openAppointment() : _openConsultation(),
        icon: const Icon(Icons.add),
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabs,
            tabs: const [
              Tab(icon: Icon(Icons.calendar_month_outlined), text: 'Agenda'),
              Tab(
                icon: Icon(Icons.medical_services_outlined),
                text: 'Atenciones',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameSearch,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      MaxValidators.lettersAndSpaces,
                    ),
                    LengthLimitingTextInputFormatter(160),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _dniSearch,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'DNI',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (controller.patients.isEmpty)
            const EmptyState(
              icon: Icons.people_outline,
              title: 'Primero registra un paciente',
              message:
                  'Las citas y atenciones siempre deben pertenecer a un paciente.',
            )
          else if (_tabs.index == 0)
            _appointmentList(controller, appointments)
          else
            _consultationList(controller, consultations),
        ],
      ),
    );
  }

  Set<int> _matchingPatientIds(AppController controller) {
    final name = _nameSearch.text.trim().toLowerCase();
    final dni = _dniSearch.text.trim();
    return controller.patients
        .where(
          (patient) =>
              (name.isEmpty || patient.fullName.toLowerCase().contains(name)) &&
              (dni.isEmpty || patient.dni.contains(dni)),
        )
        .map((patient) => patient.id)
        .toSet();
  }

  Widget _appointmentList(AppController controller, List<Appointment> list) {
    if (list.isEmpty) {
      return const EmptyState(
        icon: Icons.event_busy,
        title: 'Sin citas',
        message: 'No hay citas que coincidan con la búsqueda.',
      );
    }
    return Column(
      children: [
        for (final item in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                child: Row(
                  children: [
                    _StatusIcon(status: item.status),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.patientById(item.patientId)?.fullName ??
                                'Paciente',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(formatDateTime(item.dateTime)),
                          if (item.reason.isNotEmpty)
                            Text(
                              item.reason,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            _statusLabel(item.status),
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _openAppointment(item);
                        if (value == 'attention') {
                          _openConsultation(
                            patientId: item.patientId,
                            appointmentId: item.id,
                          );
                        }
                        if (value == 'history') {
                          final patient = controller.patientById(
                            item.patientId,
                          );
                          if (patient != null) {
                            showClinicalHistory(context, patient);
                          }
                        }
                        if (value == 'delete') _deleteAppointment(item);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Editar'),
                            dense: true,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'attention',
                          child: ListTile(
                            leading: Icon(Icons.medical_services_outlined),
                            title: Text('Atender'),
                            dense: true,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'history',
                          child: ListTile(
                            leading: Icon(Icons.history),
                            title: Text('Historial clínico'),
                            dense: true,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete_outline),
                            title: Text('Eliminar'),
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _consultationList(AppController controller, List<Consultation> list) {
    if (list.isEmpty) {
      return const EmptyState(
        icon: Icons.medical_information_outlined,
        title: 'Sin atenciones',
        message: 'No hay atenciones que coincidan con la búsqueda.',
      );
    }
    return Column(
      children: [
        for (final item in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _showConsultation(item),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        child: Icon(Icons.medical_services_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller
                                      .patientById(item.patientId)
                                      ?.fullName ??
                                  'Paciente',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(formatDateTime(item.dateTime)),
                            Text(
                              item.diagnosis.isEmpty
                                  ? 'Sin diagnóstico'
                                  : item.diagnosis,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'view') _showConsultation(item);
                          if (value == 'history') {
                            final patient = controller.patientById(
                              item.patientId,
                            );
                            if (patient != null) {
                              showClinicalHistory(context, patient);
                            }
                          }
                          if (value == 'edit') {
                            _openConsultation(consultation: item);
                          }
                          if (value == 'delete') _deleteConsultation(item);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'view',
                            child: ListTile(
                              leading: Icon(Icons.visibility_outlined),
                              title: Text('Ver'),
                              dense: true,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'history',
                            child: ListTile(
                              leading: Icon(Icons.history),
                              title: Text('Historial clínico'),
                              dense: true,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Editar'),
                              dense: true,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete_outline),
                              title: Text('Eliminar'),
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _statusLabel(String status) => switch (status) {
    'PROGRAMADA' => 'Programada',
    'REALIZADA' => 'Realizada',
    'CANCELADA' => 'Cancelada',
    'NO_ASISTIO' => 'No asistió',
    _ => status,
  };

  Future<void> _openAppointment([Appointment? appointment]) async {
    await showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (_) => AppointmentFormDialog(appointment: appointment),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openConsultation({
    Consultation? consultation,
    int? patientId,
    int? appointmentId,
  }) async {
    await showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (_) => ConsultationFormDialog(
        consultation: consultation,
        initialPatientId: patientId,
        initialAppointmentId: appointmentId,
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _showConsultation(Consultation consultation) => showDialog<void>(
    context: context,
    useSafeArea: false,
    builder: (_) => _ConsultationDetails(consultation: consultation),
  );

  Future<void> _deleteAppointment(Appointment item) async {
    if (!await confirmAction(
      context,
      title: 'Eliminar cita',
      message:
          'La cita se eliminará. Las consultas existentes se conservarán sin asociación a esta cita.',
    )) {
      return;
    }
    if (!mounted) return;
    final error = await AppScope.of(context).deleteAppointment(item);
    if (mounted) showResult(context, error, success: 'Cita eliminada.');
  }

  Future<void> _deleteConsultation(Consultation item) async {
    if (!await confirmAction(
      context,
      title: 'Eliminar atención',
      message: '¿Deseas eliminar esta atención clínica?',
    )) {
      return;
    }
    if (!mounted) return;
    final error = await AppScope.of(context).deleteConsultation(item);
    if (mounted) showResult(context, error, success: 'Atención eliminada.');
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      'REALIZADA' => (Icons.check_circle_outline, const Color(0xFF18B98B)),
      'CANCELADA' => (
        Icons.cancel_outlined,
        Theme.of(context).colorScheme.error,
      ),
      'NO_ASISTIO' => (Icons.person_off_outlined, const Color(0xFFE38B4B)),
      _ => (Icons.schedule, Theme.of(context).colorScheme.primary),
    };
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: .12),
      foregroundColor: color,
      child: Icon(icon),
    );
  }
}

class AppointmentFormDialog extends StatefulWidget {
  const AppointmentFormDialog({super.key, this.appointment});
  final Appointment? appointment;
  @override
  State<AppointmentFormDialog> createState() => _AppointmentFormDialogState();
}

class _AppointmentFormDialogState extends State<AppointmentFormDialog> {
  final _key = GlobalKey<FormState>();
  late int? _patientId;
  late DateTime _dateTime;
  late String _status;
  late final TextEditingController _reason;
  late final TextEditingController _notes;
  String? _error;

  @override
  void initState() {
    super.initState();
    final item = widget.appointment;
    _patientId = item?.patientId;
    _dateTime =
        DateTime.tryParse(item?.dateTime ?? '')?.toLocal() ??
        DateTime.now().add(const Duration(hours: 1));
    _status = item?.status ?? 'PROGRAMADA';
    _reason = TextEditingController(text: item?.reason ?? '');
    _notes = TextEditingController(text: item?.notes ?? '');
  }

  @override
  void dispose() {
    _reason.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (time != null) {
      setState(
        () => _dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
    }
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_key.currentState!.validate()) return;
    final originallyProgrammed =
        (widget.appointment?.status ?? _status) == 'PROGRAMADA';
    if (originallyProgrammed && !_dateTime.isAfter(DateTime.now())) {
      setState(
        () => _error = 'La fecha de una cita programada debe ser futura.',
      );
      return;
    }
    final old = widget.appointment;
    final item = Appointment(
      id: old?.id ?? 0,
      patientId: _patientId!,
      dateTime: toApiLocalDateTime(_dateTime),
      reason: _reason.text.trim(),
      status: _status,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      version: old?.version,
    );
    final error = await AppScope.of(context).saveAppointment(item);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
      showResult(
        context,
        null,
        success: old == null ? 'Cita programada.' : 'Cita actualizada.',
      );
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return MaxModal(
      title: widget.appointment == null ? 'Nueva cita' : 'Editar cita',
      child: Form(
        key: _key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _patientId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Paciente'),
              items: controller.patients
                  .map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(
                        '${p.fullName} · ${p.dni}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: widget.appointment == null
                  ? (value) => setState(() => _patientId = value)
                  : null,
              validator: (value) =>
                  value == null ? 'Selecciona un paciente.' : null,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha y hora',
                  suffixIcon: Icon(Icons.calendar_month),
                ),
                child: Text(DateFormat('dd/MM/yyyy HH:mm').format(_dateTime)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reason,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(250)],
              decoration: const InputDecoration(labelText: 'Motivo'),
            ),
            const SizedBox(height: 12),
            if (widget.appointment != null) ...[
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: const [
                  DropdownMenuItem(
                    value: 'PROGRAMADA',
                    child: Text('Programada'),
                  ),
                  DropdownMenuItem(
                    value: 'REALIZADA',
                    child: Text('Realizada'),
                  ),
                  DropdownMenuItem(
                    value: 'CANCELADA',
                    child: Text('Cancelada'),
                  ),
                  DropdownMenuItem(
                    value: 'NO_ASISTIO',
                    child: Text('No asistió'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _status = value ?? 'PROGRAMADA'),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _notes,
              textCapitalization: TextCapitalization.sentences,
              minLines: 3,
              maxLines: 6,
              inputFormatters: [LengthLimitingTextInputFormatter(1000)],
              decoration: const InputDecoration(labelText: 'Notas'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: controller.actionLoading ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                controller.actionLoading ? 'Guardando...' : 'Guardar cita',
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: controller.actionLoading
                  ? null
                  : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}

class ConsultationFormDialog extends StatefulWidget {
  const ConsultationFormDialog({
    super.key,
    this.consultation,
    this.initialPatientId,
    this.initialAppointmentId,
  });
  final Consultation? consultation;
  final int? initialPatientId;
  final int? initialAppointmentId;
  @override
  State<ConsultationFormDialog> createState() => _ConsultationFormDialogState();
}

class _ConsultationFormDialogState extends State<ConsultationFormDialog> {
  final _key = GlobalKey<FormState>();
  late int? _patientId;
  late int? _appointmentId;
  late final TextEditingController _anamnesis;
  late final TextEditingController _exam;
  late final TextEditingController _auxiliary;
  late final TextEditingController _diagnosis;
  final _studyDescription = TextEditingController();
  final _idempotencyKey = const Uuid().v4();
  List<StudyUploadDraft> _files = [];
  String _studyType = 'RX';
  Consultation? _persisted;
  bool _pendingUploadOnly = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final item = widget.consultation;
    _patientId = item?.patientId ?? widget.initialPatientId;
    _appointmentId = item?.appointmentId ?? widget.initialAppointmentId;
    _anamnesis = TextEditingController(text: item?.anamnesis ?? '');
    _exam = TextEditingController(text: item?.physicalExam ?? '');
    _auxiliary = TextEditingController(text: item?.auxiliaryExams ?? '');
    _diagnosis = TextEditingController(text: item?.diagnosis ?? '');
    _persisted = item;
  }

  @override
  void dispose() {
    _anamnesis.dispose();
    _exam.dispose();
    _auxiliary.dispose();
    _diagnosis.dispose();
    _studyDescription.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final selected = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    );
    if (selected.isEmpty) return;
    final accepted = <StudyUploadDraft>[];
    for (final file in selected) {
      if (file.name.trim().isEmpty || file.name.length > 250) {
        setState(
          () => _error =
              '${file.name}: el nombre debe tener hasta 250 caracteres.',
        );
        return;
      }
      final length = await file.length();
      if (length == null || length <= 0 || length > AppConfig.maxStudyBytes) {
        setState(
          () => _error =
              '${file.name}: el archivo está vacío, supera 20 MiB o no se pudo verificar.',
        );
        return;
      }
      final bytes = await file.readAsBytes();
      final mime = lookupMimeType(
        file.name,
        headerBytes: bytes.take(16).toList(),
      );
      if (!const {
        'image/jpeg',
        'image/png',
        'image/webp',
        'application/pdf',
      }.contains(mime)) {
        setState(
          () => _error =
              '${file.name}: formato inválido. Usa JPEG, PNG, WebP o PDF.',
        );
        return;
      }
      accepted.add(StudyUploadDraft(fileName: file.name, bytes: bytes));
    }
    setState(() {
      _files = [..._files, ...accepted];
      _error = null;
    });
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_key.currentState!.validate()) return;
    final old = _persisted ?? widget.consultation;
    final item = Consultation(
      id: old?.id ?? 0,
      patientId: _patientId!,
      appointmentId: _appointmentId,
      dateTime: old?.dateTime ?? toApiLocalDateTime(DateTime.now()),
      anamnesis: _anamnesis.text.trim(),
      physicalExam: _exam.text.trim(),
      auxiliaryExams: _auxiliary.text.trim(),
      diagnosis: _diagnosis.text.trim(),
      createdAt: old?.createdAt ?? DateTime.now().toUtc().toIso8601String(),
      updatedAt: DateTime.now().toUtc().toIso8601String(),
      version: old?.version,
    );
    if (_files.isNotEmpty && _studyType.isEmpty) {
      setState(
        () => _error = 'Selecciona el tipo de estudio para los archivos.',
      );
      return;
    }
    final result = await AppScope.of(context).saveConsultation(
      item,
      idempotencyKey: _idempotencyKey,
      files: _files,
      studyType: _studyType,
      studyDescription: _studyDescription.text.trim(),
      skipAttentionSave: _pendingUploadOnly,
    );
    if (!mounted) return;
    _persisted = result.consultation ?? _persisted;
    _files = result.failedFiles;
    _pendingUploadOnly =
        result.consultation != null && result.failedFiles.isNotEmpty;
    if (result.error == null) {
      Navigator.pop(context);
      showResult(
        context,
        null,
        success: old == null ? 'Atención guardada.' : 'Atención actualizada.',
      );
    } else {
      setState(() => _error = result.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final persistedId = (_persisted ?? widget.consultation)?.id;
    final existingStudies = persistedId == null || persistedId <= 0
        ? const <Study>[]
        : controller.studies
              .where((study) => study.consultationId == persistedId)
              .toList();
    final availableAppointments = controller.appointments
        .where(
          (a) =>
              a.patientId == _patientId &&
              (a.status == 'PROGRAMADA' || a.id == _appointmentId),
        )
        .toList();
    if (_appointmentId != null &&
        !availableAppointments.any((a) => a.id == _appointmentId)) {
      _appointmentId = null;
    }
    return MaxModal(
      title: widget.consultation == null ? 'Nueva atención' : 'Editar atención',
      child: Form(
        key: _key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _patientId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Paciente'),
              items: controller.patients
                  .map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(
                        '${p.fullName} · ${p.dni}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: widget.consultation == null
                  ? (value) => setState(() {
                      _patientId = value;
                      _appointmentId = null;
                    })
                  : null,
              validator: (value) =>
                  value == null ? 'Selecciona un paciente.' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _appointmentId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Cita relacionada (opcional)',
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Sin cita relacionada'),
                ),
                ...availableAppointments.map(
                  (a) => DropdownMenuItem<int?>(
                    value: a.id,
                    child: Text(
                      '${formatDateTime(a.dateTime)} · ${a.reason}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _appointmentId = value),
            ),
            const MaxSectionTitle('Evaluación clínica'),
            TextFormField(
              controller: _anamnesis,
              textCapitalization: TextCapitalization.sentences,
              minLines: 3,
              maxLines: 7,
              inputFormatters: [LengthLimitingTextInputFormatter(5000)],
              decoration: const InputDecoration(labelText: 'Anamnesis'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _exam,
              textCapitalization: TextCapitalization.sentences,
              minLines: 3,
              maxLines: 7,
              inputFormatters: [LengthLimitingTextInputFormatter(5000)],
              decoration: const InputDecoration(labelText: 'Examen físico'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _auxiliary,
              textCapitalization: TextCapitalization.sentences,
              minLines: 3,
              maxLines: 7,
              inputFormatters: [LengthLimitingTextInputFormatter(5000)],
              decoration: const InputDecoration(
                labelText: 'Exámenes auxiliares',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _diagnosis,
              textCapitalization: TextCapitalization.sentences,
              minLines: 3,
              maxLines: 7,
              inputFormatters: [LengthLimitingTextInputFormatter(5000)],
              decoration: const InputDecoration(labelText: 'Diagnóstico'),
            ),
            if (existingStudies.isNotEmpty) ...[
              const MaxSectionTitle('Estudios ya asociados'),
              for (final study in existingStudies)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    study.isPdf
                        ? Icons.picture_as_pdf_outlined
                        : Icons.image_outlined,
                  ),
                  title: Text(study.fileName ?? study.type),
                  subtitle: Text(study.description ?? study.type),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => openStudyViewer(context, study),
                ),
            ],
            const MaxSectionTitle('Archivos de la atención'),
            OutlinedButton.icon(
              onPressed: controller.actionLoading ? null : _pickFiles,
              icon: const Icon(Icons.attach_file),
              label: const Text('Adjuntar JPEG, PNG, WebP o PDF'),
            ),
            if (_files.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _studyType,
                decoration: const InputDecoration(labelText: 'Tipo de estudio'),
                items: const [
                  DropdownMenuItem(value: 'RX', child: Text('Rayos X (RX)')),
                  DropdownMenuItem(value: 'RM', child: Text('Resonancia (RM)')),
                  DropdownMenuItem(
                    value: 'TAC',
                    child: Text('Tomografía (TAC)'),
                  ),
                  DropdownMenuItem(
                    value: 'EMG',
                    child: Text('Electromiografía (EMG)'),
                  ),
                  DropdownMenuItem(value: 'PDF', child: Text('Documento PDF')),
                ],
                onChanged: (value) =>
                    setState(() => _studyType = value ?? 'RX'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _studyDescription,
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                decoration: const InputDecoration(
                  labelText: 'Descripción de los archivos',
                ),
              ),
              const SizedBox(height: 8),
              for (var index = 0; index < _files.length; index++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.insert_drive_file_outlined),
                  title: Text(
                    _files[index].fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${(_files[index].bytes.length / 1024 / 1024).toStringAsFixed(2)} MiB',
                  ),
                  trailing: IconButton(
                    tooltip: 'Quitar archivo',
                    onPressed: controller.actionLoading
                        ? null
                        : () => setState(() => _files.removeAt(index)),
                    icon: const Icon(Icons.close),
                  ),
                ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: controller.actionLoading ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                controller.actionLoading ? 'Guardando...' : 'Guardar atención',
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: controller.actionLoading
                  ? null
                  : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsultationDetails extends StatelessWidget {
  const _ConsultationDetails({required this.consultation});
  final Consultation consultation;
  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final consultationStudies = controller.studies
        .where((study) => study.consultationId == consultation.id)
        .toList();
    return MaxModal(
      title: 'Detalle de atención',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            controller.patientById(consultation.patientId)?.fullName ??
                'Paciente',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(formatDateTime(consultation.dateTime)),
          const MaxSectionTitle('Anamnesis'),
          Text(consultation.anamnesis.isEmpty ? '--' : consultation.anamnesis),
          const MaxSectionTitle('Examen físico'),
          Text(
            consultation.physicalExam.isEmpty
                ? '--'
                : consultation.physicalExam,
          ),
          const MaxSectionTitle('Exámenes auxiliares'),
          Text(
            consultation.auxiliaryExams.isEmpty
                ? '--'
                : consultation.auxiliaryExams,
          ),
          const MaxSectionTitle('Diagnóstico'),
          Text(consultation.diagnosis.isEmpty ? '--' : consultation.diagnosis),
          const MaxSectionTitle('Estudios asociados'),
          if (consultationStudies.isEmpty)
            Text(
              'Sin estudios asociados.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final study in consultationStudies)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  study.isPdf
                      ? Icons.picture_as_pdf_outlined
                      : Icons.image_outlined,
                ),
                title: Text(study.fileName ?? study.type),
                subtitle: Text(study.description ?? study.type),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => openStudyViewer(context, study),
              ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              showDialog<void>(
                context: context,
                useSafeArea: false,
                builder: (_) =>
                    ConsultationFormDialog(consultation: consultation),
              );
            },
            child: const Text('Editar atención'),
          ),
        ],
      ),
    );
  }
}
