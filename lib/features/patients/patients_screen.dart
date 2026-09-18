import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../application/app_controller.dart';
import '../../core/theme/max_theme.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/max_widgets.dart';
import '../../domain/models.dart';
import '../shared/clinical_history_dialog.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final _nameSearch = TextEditingController();
  final _dniSearch = TextEditingController();

  @override
  void dispose() {
    _nameSearch.dispose();
    _dniSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final name = _nameSearch.text.trim().toLowerCase();
    final dni = _dniSearch.text.trim();
    final filtered = controller.patients.where((patient) {
      return (name.isEmpty || patient.fullName.toLowerCase().contains(name)) &&
          (dni.isEmpty || patient.dni.contains(dni));
    }).toList()..sort((a, b) => a.fullName.compareTo(b.fullName));

    return MaxPage(
      title: 'Pacientes',
      subtitle: '${controller.patients.length} registrados',
      action: IconButton.filled(
        tooltip: 'Nuevo paciente',
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_alt_1),
      ),
      child: Column(
        children: [
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
                    hintText: 'Buscar por nombre',
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
                    hintText: 'Buscar por DNI',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            const EmptyState(
              icon: Icons.person_search,
              title: 'Sin resultados',
              message: 'No se encontraron pacientes con esos criterios.',
            )
          else
            for (final patient in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _showPatient(patient),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: MaxColors.paleBlue,
                            foregroundColor: MaxColors.blue,
                            child: Text(
                              patient.firstName.isEmpty
                                  ? 'P'
                                  : patient.firstName[0].toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patient.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'DNI ${patient.dni} · Riesgo ${patient.risk}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (patient.diagnosis?.isNotEmpty == true)
                                  Text(
                                    patient.diagnosis!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'view') _showPatient(patient);
                              if (value == 'history') {
                                showClinicalHistory(context, patient);
                              }
                              if (value == 'edit') _openForm(patient);
                              if (value == 'delete') _delete(patient);
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
      ),
    );
  }

  Future<void> _openForm([Patient? patient]) async {
    await showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (_) => PatientFormDialog(patient: patient),
    );
    if (mounted) setState(() {});
  }

  Future<void> _showPatient(Patient patient) => showDialog<void>(
    context: context,
    useSafeArea: false,
    builder: (_) => _PatientDetails(patient: patient),
  );

  Future<void> _delete(Patient patient) async {
    final confirm = await confirmAction(
      context,
      title: 'Eliminar paciente',
      message:
          'Se eliminará a ${patient.fullName} y sus datos relacionados según las reglas actuales del sistema. ¿Deseas continuar?',
    );
    if (!confirm || !mounted) return;
    final error = await AppScope.of(context).deletePatient(patient);
    if (mounted) showResult(context, error, success: 'Paciente eliminado.');
  }
}

class PatientFormDialog extends StatefulWidget {
  const PatientFormDialog({super.key, this.patient});
  final Patient? patient;

  @override
  State<PatientFormDialog> createState() => _PatientFormDialogState();
}

class _PatientFormDialogState extends State<PatientFormDialog> {
  final _key = GlobalKey<FormState>();
  final _idempotencyKey = const Uuid().v4();
  late final Map<String, TextEditingController> fields;
  String? _sex;
  String _risk = 'Bajo';
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    fields = {
      'firstName': TextEditingController(text: p?.firstName ?? ''),
      'lastName': TextEditingController(text: p?.lastName ?? ''),
      'dni': TextEditingController(text: p?.dni ?? ''),
      'birthDate': TextEditingController(text: p?.birthDate ?? ''),
      'phone': TextEditingController(text: p?.phone ?? ''),
      'email': TextEditingController(text: p?.email ?? ''),
      'address': TextEditingController(text: p?.address ?? ''),
      'occupation': TextEditingController(text: p?.occupation ?? ''),
      'allergies': TextEditingController(text: p?.allergies ?? ''),
      'diagnosis': TextEditingController(text: p?.diagnosis ?? ''),
      'history': TextEditingController(text: p?.history ?? ''),
      'notes': TextEditingController(text: p?.notes ?? ''),
    };
    _sex = p?.sex;
    _risk = p?.risk ?? 'Bajo';
  }

  @override
  void dispose() {
    for (final controller in fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final current =
        DateTime.tryParse(fields['birthDate']!.text) ?? DateTime(now.year - 30);
    final value = await showDatePicker(
      context: context,
      initialDate: current.isAfter(now) ? now : current,
      firstDate: DateTime(now.year - 120),
      lastDate: now,
    );
    if (value != null) {
      setState(
        () =>
            fields['birthDate']!.text = DateFormat('yyyy-MM-dd').format(value),
      );
    }
  }

  int? get _age {
    final birth = DateTime.tryParse(fields['birthDate']!.text);
    if (birth == null) return null;
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_key.currentState!.validate()) return;
    if (_sex == null) {
      setState(() => _error = 'Selecciona el sexo del paciente.');
      return;
    }
    final old = widget.patient;
    final patient = Patient(
      id: old?.id ?? 0,
      firstName: fields['firstName']!.text.trim().replaceAll(
        RegExp(r' +'),
        ' ',
      ),
      lastName: fields['lastName']!.text.trim().replaceAll(RegExp(r' +'), ' '),
      dni: fields['dni']!.text,
      birthDate: fields['birthDate']!.text,
      sex: _sex,
      phone: _nullable('phone'),
      email: _nullable('email')?.toLowerCase(),
      address: _nullable('address'),
      occupation: _nullable('occupation')?.replaceAll(RegExp(r' +'), ' '),
      allergies: _nullable('allergies'),
      diagnosis: _nullable('diagnosis'),
      history: _nullable('history'),
      notes: _nullable('notes'),
      lastConsultation:
          old?.lastConsultation ??
          (old == null ? DateTime.now().toUtc().toIso8601String() : null),
      nextConsultation: old?.nextConsultation,
      risk: _risk,
      active: old?.active ?? true,
      version: old?.version,
    );
    final error = await AppScope.of(
      context,
    ).savePatient(patient, idempotencyKey: _idempotencyKey);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
      showResult(
        context,
        null,
        success: old == null
            ? 'Paciente e historial inicial guardados.'
            : 'Paciente actualizado.',
      );
    } else {
      setState(() => _error = error);
    }
  }

  String? _nullable(String field) {
    final value = fields[field]!.text.trim();
    return value.isEmpty ? null : value;
  }

  @override
  Widget build(BuildContext context) {
    final busy = AppScope.of(context).actionLoading;
    final letterFormatters = <TextInputFormatter>[
      FilteringTextInputFormatter.allow(MaxValidators.lettersAndSpaces),
    ];
    return MaxModal(
      title: widget.patient == null ? 'Nuevo paciente' : 'Editar paciente',
      child: Form(
        key: _key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const MaxSectionTitle('Información personal'),
            TextFormField(
              controller: fields['firstName'],
              textCapitalization: TextCapitalization.words,
              inputFormatters: [
                ...letterFormatters,
                LengthLimitingTextInputFormatter(80),
              ],
              decoration: const InputDecoration(labelText: 'Nombres'),
              validator: (v) => MaxValidators.name(v, label: 'Los nombres'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: fields['lastName'],
              textCapitalization: TextCapitalization.words,
              inputFormatters: [
                ...letterFormatters,
                LengthLimitingTextInputFormatter(80),
              ],
              decoration: const InputDecoration(labelText: 'Apellidos'),
              validator: (v) => MaxValidators.name(v, label: 'Los apellidos'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: fields['dni'],
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              decoration: const InputDecoration(labelText: 'DNI'),
              validator: MaxValidators.dni,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: fields['birthDate'],
              readOnly: true,
              onTap: _pickBirthDate,
              decoration: InputDecoration(
                labelText: 'Fecha de nacimiento',
                suffixIcon: const Icon(Icons.calendar_month),
                helperText: _age == null ? null : 'Edad: $_age años',
              ),
              validator: (value) => MaxValidators.requiredText(
                value,
                label: 'La fecha de nacimiento',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _sex,
              decoration: const InputDecoration(labelText: 'Sexo'),
              items: const [
                DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
                DropdownMenuItem(value: 'Femenino', child: Text('Femenino')),
              ],
              onChanged: (value) => setState(() => _sex = value),
              validator: (value) =>
                  value == null ? 'Selecciona el sexo.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: fields['phone'],
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(15),
              ],
              decoration: const InputDecoration(labelText: 'Teléfono'),
              validator: MaxValidators.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: fields['email'],
              keyboardType: TextInputType.emailAddress,
              inputFormatters: [LengthLimitingTextInputFormatter(120)],
              decoration: const InputDecoration(labelText: 'Correo'),
              validator: MaxValidators.email,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: fields['address'],
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(250)],
              decoration: const InputDecoration(labelText: 'Dirección'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: fields['occupation'],
              textCapitalization: TextCapitalization.words,
              inputFormatters: [
                ...letterFormatters,
                LengthLimitingTextInputFormatter(120),
              ],
              decoration: const InputDecoration(labelText: 'Ocupación'),
              validator: (v) =>
                  MaxValidators.optionalLetters(v, label: 'La ocupación'),
            ),
            const MaxSectionTitle('Información médica'),
            TextFormField(
              controller: fields['allergies'],
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              inputFormatters: [LengthLimitingTextInputFormatter(500)],
              decoration: const InputDecoration(labelText: 'Alergias'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: fields['diagnosis'],
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              inputFormatters: [LengthLimitingTextInputFormatter(500)],
              decoration: const InputDecoration(
                labelText: 'Diagnóstico principal',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: fields['history'],
              textCapitalization: TextCapitalization.sentences,
              minLines: 3,
              maxLines: 6,
              inputFormatters: [LengthLimitingTextInputFormatter(5000)],
              decoration: const InputDecoration(
                labelText: 'Antecedentes médicos',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: fields['notes'],
              textCapitalization: TextCapitalization.sentences,
              minLines: 3,
              maxLines: 6,
              inputFormatters: [LengthLimitingTextInputFormatter(5000)],
              decoration: const InputDecoration(
                labelText: 'Nota inicial del caso',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _risk,
              decoration: const InputDecoration(labelText: 'Riesgo'),
              items: const [
                DropdownMenuItem(value: 'Bajo', child: Text('Bajo')),
                DropdownMenuItem(value: 'Moderado', child: Text('Moderado')),
                DropdownMenuItem(value: 'Severo', child: Text('Severo')),
              ],
              onChanged: (value) => setState(() => _risk = value ?? 'Bajo'),
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
              onPressed: busy ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(busy ? 'Guardando...' : 'Guardar'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: busy ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientDetails extends StatelessWidget {
  const _PatientDetails({required this.patient});
  final Patient patient;

  @override
  Widget build(BuildContext context) => MaxModal(
    title: 'Ficha del paciente',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: CircleAvatar(
            radius: 34,
            child: Text(
              patient.firstName.isEmpty
                  ? 'P'
                  : patient.firstName[0].toUpperCase(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          patient.fullName,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text('DNI ${patient.dni}', textAlign: TextAlign.center),
        const MaxSectionTitle('Información personal'),
        _Detail(
          label: 'Nacimiento',
          value:
              '${formatDate(patient.birthDate)}${_age(patient.birthDate) != null ? ' · ${_age(patient.birthDate)} años' : ''}',
        ),
        _Detail(label: 'Sexo', value: patient.sex),
        _Detail(label: 'Teléfono', value: patient.phone),
        _Detail(label: 'Correo', value: patient.email),
        _Detail(label: 'Dirección', value: patient.address),
        _Detail(label: 'Ocupación', value: patient.occupation),
        const MaxSectionTitle('Información médica'),
        _Detail(label: 'Riesgo', value: patient.risk),
        _Detail(label: 'Alergias', value: patient.allergies),
        _Detail(label: 'Diagnóstico', value: patient.diagnosis),
        _Detail(label: 'Antecedentes', value: patient.history),
        _Detail(label: 'Notas', value: patient.notes),
        _Detail(
          label: 'Última consulta',
          value: formatDateTime(patient.lastConsultation),
        ),
        _Detail(
          label: 'Próxima consulta',
          value: formatDateTime(patient.nextConsultation),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () => showClinicalHistory(context, patient),
          icon: const Icon(Icons.history),
          label: const Text('Ver historial clínico'),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            showDialog<void>(
              context: context,
              useSafeArea: false,
              builder: (_) => PatientFormDialog(patient: patient),
            );
          },
          child: const Text('Editar paciente'),
        ),
      ],
    ),
  );

  static int? _age(String? value) {
    final birth = DateTime.tryParse(value ?? '');
    if (birth == null) return null;
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, this.value});
  final String label;
  final String? value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 125,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value == null || value!.isEmpty ? '--' : value!,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
