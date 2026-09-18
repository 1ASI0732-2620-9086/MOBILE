import 'package:flutter/material.dart';

import '../../application/app_controller.dart';
import '../../core/widgets/max_widgets.dart';
import '../../domain/models.dart';
import 'study_viewer.dart';

Future<void> showClinicalHistory(BuildContext context, Patient patient) {
  return showDialog<void>(
    context: context,
    useSafeArea: false,
    builder: (_) => _ClinicalHistoryDialog(patient: patient),
  );
}

class _ClinicalHistoryDialog extends StatelessWidget {
  const _ClinicalHistoryDialog({required this.patient});
  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final consultations =
        controller.consultations
            .where((item) => item.patientId == patient.id)
            .toList()
          ..sort((a, b) => compareDateTimeDescending(a.dateTime, b.dateTime));
    final independentStudies =
        controller.studies
            .where(
              (item) =>
                  item.patientId == patient.id && item.consultationId == null,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    return MaxModal(
      title: 'Historial clínico',
      maxWidth: 760,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            patient.fullName,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text('DNI ${patient.dni}'),
          const MaxSectionTitle('Consultas'),
          if (consultations.isEmpty)
            const EmptyState(
              icon: Icons.medical_information_outlined,
              title: 'Sin consultas',
              message: 'Este paciente aún no tiene atenciones clínicas.',
            )
          else
            for (final consultation in consultations)
              _HistoryConsultationCard(
                consultation: consultation,
                studies: controller.studies
                    .where((item) => item.consultationId == consultation.id)
                    .toList(),
              ),
          const MaxSectionTitle('Otros estudios'),
          if (independentStudies.isEmpty)
            Text(
              'No hay estudios independientes.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final study in independentStudies) _StudyTile(study: study),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _HistoryConsultationCard extends StatelessWidget {
  const _HistoryConsultationCard({
    required this.consultation,
    required this.studies,
  });
  final Consultation consultation;
  final List<Study> studies;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            formatDateTime(consultation.dateTime),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          if (consultation.updatedAt != null)
            Text(
              'Actualizado: ${formatDateTime(consultation.updatedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 12),
          _ClinicalValue(label: 'Anamnesis', value: consultation.anamnesis),
          _ClinicalValue(
            label: 'Examen físico',
            value: consultation.physicalExam,
          ),
          _ClinicalValue(
            label: 'Exámenes auxiliares',
            value: consultation.auxiliaryExams,
          ),
          _ClinicalValue(label: 'Diagnóstico', value: consultation.diagnosis),
          const SizedBox(height: 8),
          Text(
            'Estudios de la consulta',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (studies.isEmpty)
            Text(
              'Sin estudios asociados.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final study in studies) _StudyTile(study: study),
        ],
      ),
    ),
  );
}

class _ClinicalValue extends StatelessWidget {
  const _ClinicalValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(value.trim().isEmpty ? '--' : value),
      ],
    ),
  );
}

class _StudyTile extends StatelessWidget {
  const _StudyTile({required this.study});
  final Study study;

  @override
  Widget build(BuildContext context) {
    final description = study.description?.trim();
    final details = description?.isNotEmpty == true
        ? '${study.type} · $description · ${formatDate(study.date)}'
        : '${study.type} · ${formatDate(study.date)}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        study.isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
      ),
      title: Text(study.fileName ?? study.type),
      subtitle: Text(details, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.open_in_new),
      onTap: () => openStudyViewer(context, study),
    );
  }
}
