import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';

import '../../application/app_controller.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/max_widgets.dart';
import '../../domain/models.dart';
import '../shared/study_viewer.dart';

class StudiesScreen extends StatefulWidget {
  const StudiesScreen({super.key});

  @override
  State<StudiesScreen> createState() => _StudiesScreenState();
}

class _StudiesScreenState extends State<StudiesScreen> {
  final _search = TextEditingController();
  final _date = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    _date.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final term = _search.text.trim().toLowerCase();
    final date = _date.text;
    final filtered = controller.studies.where((study) {
      final patient = controller.patientById(study.patientId);
      final text =
          '${patient?.fullName ?? ''} ${patient?.dni ?? ''} ${study.type} ${study.description ?? ''}'
              .toLowerCase();
      return (term.isEmpty || text.contains(term)) &&
          (date.isEmpty || study.date.startsWith(date));
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
    return MaxPage(
      title: 'Estudios',
      subtitle: '${controller.studies.length} archivos clínicos',
      action: IconButton.filled(
        tooltip: 'Nuevo estudio',
        onPressed: controller.patients.isEmpty ? null : _openUpload,
        icon: const Icon(Icons.upload_file),
      ),
      child: Column(
        children: [
          TextField(
            controller: _search,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                MaxValidators.lettersDigitsAndSpaces,
              ),
              LengthLimitingTextInputFormatter(160),
            ],
            decoration: const InputDecoration(
              labelText: 'Buscar estudio',
              hintText: 'Paciente, DNI, tipo o descripción',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _date,
            readOnly: true,
            onTap: _pickFilterDate,
            decoration: InputDecoration(
              labelText: 'Fecha',
              hintText: 'Todas las fechas',
              prefixIcon: const Icon(Icons.calendar_month),
              suffixIcon: _date.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => setState(_date.clear),
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          if (controller.patients.isEmpty)
            const EmptyState(
              icon: Icons.people_outline,
              title: 'Primero registra un paciente',
              message: 'Todo estudio debe estar asociado con un paciente.',
            )
          else if (filtered.isEmpty)
            const EmptyState(
              icon: Icons.image_search_outlined,
              title: 'Sin estudios',
              message: 'No se encontraron archivos con esos criterios.',
            )
          else
            for (final study in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => openStudyViewer(context, study),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            child: Icon(
                              study.isPdf
                                  ? Icons.picture_as_pdf_outlined
                                  : Icons.image_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  controller
                                          .patientById(study.patientId)
                                          ?.fullName ??
                                      'Paciente',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${study.type} · ${formatDate(study.date)}',
                                ),
                                if (study.description?.isNotEmpty == true)
                                  Text(
                                    study.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                Text(
                                  study.fileName ?? 'Archivo',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'open') {
                                openStudyViewer(context, study);
                              }
                              if (value == 'delete') _delete(study);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'open',
                                child: ListTile(
                                  leading: Icon(Icons.open_in_new),
                                  title: Text('Abrir'),
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

  Future<void> _pickFilterDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (value != null) {
      setState(() => _date.text = DateFormat('yyyy-MM-dd').format(value));
    }
  }

  Future<void> _openUpload() async {
    await showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (_) => const StudyUploadDialog(),
    );
    if (mounted) setState(() {});
  }

  Future<void> _delete(Study study) async {
    if (!await confirmAction(
      context,
      title: 'Eliminar estudio',
      message:
          'Se eliminará el registro y el archivo asociado. ¿Deseas continuar?',
    )) {
      return;
    }
    if (!mounted) return;
    final error = await AppScope.of(context).deleteStudy(study);
    if (mounted) showResult(context, error, success: 'Estudio eliminado.');
  }
}

class StudyUploadDialog extends StatefulWidget {
  const StudyUploadDialog({super.key});
  @override
  State<StudyUploadDialog> createState() => _StudyUploadDialogState();
}

class _StudyUploadDialogState extends State<StudyUploadDialog> {
  final _key = GlobalKey<FormState>();
  final _description = TextEditingController();
  int? _patientId;
  int? _consultationId;
  String _type = 'RX';
  DateTime _date = DateTime.now();
  Uint8List? _bytes;
  String? _fileName;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    );
    if (file == null) return;
    if (file.name.trim().isEmpty || file.name.length > 250) {
      setState(
        () => _error = 'El nombre del archivo debe tener hasta 250 caracteres.',
      );
      return;
    }
    final length = await file.length();
    if (length == null || length <= 0) {
      setState(() => _error = 'El archivo está vacío o no se pudo verificar.');
      return;
    }
    if (length > AppConfig.maxStudyBytes) {
      setState(() => _error = 'El archivo supera el máximo de 20 MiB.');
      return;
    }
    final bytes = await file.readAsBytes();
    final mime = lookupMimeType(
      file.name,
      headerBytes: bytes.take(16).toList(),
    );
    const allowed = {
      'image/jpeg',
      'image/png',
      'image/webp',
      'application/pdf',
    };
    if (!allowed.contains(mime)) {
      setState(() => _error = 'Selecciona un JPEG, PNG, WebP o PDF válido.');
      return;
    }
    setState(() {
      _bytes = bytes;
      _fileName = file.name;
      _error = null;
      if (mime == 'application/pdf') _type = 'PDF';
    });
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (value != null) setState(() => _date = value);
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_key.currentState!.validate()) return;
    if (_bytes == null || _fileName == null) {
      setState(() => _error = 'Selecciona un archivo clínico.');
      return;
    }
    final error = await AppScope.of(context).uploadStudy(
      patientId: _patientId!,
      consultationId: _consultationId,
      type: _type,
      date: DateFormat('yyyy-MM-dd').format(_date),
      description: _description.text.trim(),
      fileName: _fileName!,
      bytes: _bytes!,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
      showResult(context, null, success: 'Estudio cargado.');
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final consultations =
        controller.consultations
            .where((c) => c.patientId == _patientId)
            .toList()
          ..sort((a, b) => compareDateTimeDescending(a.dateTime, b.dateTime));
    if (_consultationId != null &&
        !consultations.any((c) => c.id == _consultationId)) {
      _consultationId = null;
    }
    return MaxModal(
      title: 'Nuevo estudio',
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
              onChanged: (value) => setState(() {
                _patientId = value;
                _consultationId = null;
              }),
              validator: (value) =>
                  value == null ? 'Selecciona un paciente.' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _consultationId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Consulta relacionada (opcional)',
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Sin consulta relacionada'),
                ),
                ...consultations.map(
                  (c) => DropdownMenuItem<int?>(
                    value: c.id,
                    child: Text(
                      '${formatDateTime(c.dateTime)} · ${c.diagnosis}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _consultationId = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tipo de estudio'),
              items: const [
                DropdownMenuItem(value: 'RX', child: Text('Rayos X (RX)')),
                DropdownMenuItem(value: 'RM', child: Text('Resonancia (RM)')),
                DropdownMenuItem(value: 'TAC', child: Text('Tomografía (TAC)')),
                DropdownMenuItem(
                  value: 'EMG',
                  child: Text('Electromiografía (EMG)'),
                ),
                DropdownMenuItem(value: 'PDF', child: Text('Documento PDF')),
              ],
              onChanged: (value) => setState(() => _type = value ?? 'RX'),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha',
                  suffixIcon: Icon(Icons.calendar_month),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_date)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              minLines: 2,
              maxLines: 5,
              inputFormatters: [LengthLimitingTextInputFormatter(1000)],
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: Text(_fileName ?? 'Seleccionar JPEG, PNG, WebP o PDF'),
            ),
            if (_fileName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${(_bytes!.length / 1024 / 1024).toStringAsFixed(2)} MiB · Máximo 20 MiB',
                  textAlign: TextAlign.center,
                ),
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
              icon: const Icon(Icons.cloud_upload_outlined),
              label: Text(
                controller.actionLoading ? 'Cargando...' : 'Cargar estudio',
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
