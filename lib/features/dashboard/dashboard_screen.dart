import 'package:flutter/material.dart';

import '../../application/app_controller.dart';
import '../../core/theme/max_theme.dart';
import '../../core/widgets/max_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onOpenModule});
  final ValueChanged<int> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final now = DateTime.now();
    final upcomingAppointments =
        controller.appointments.where((appointment) {
          final value = DateTime.tryParse(appointment.dateTime)?.toLocal();
          return value != null &&
              appointment.status == 'PROGRAMADA' &&
              value.isAfter(now);
        }).toList()..sort((a, b) {
          final first = DateTime.tryParse(a.dateTime) ?? DateTime(9999);
          final second = DateTime.tryParse(b.dateTime) ?? DateTime(9999);
          return first.compareTo(second);
        });
    final recent = [...controller.consultations]
      ..sort((a, b) => compareDateTimeDescending(a.dateTime, b.dateTime));

    return MaxPage(
      title:
          'Hola, ${controller.user?.firstName ?? controller.user?.name ?? ''}',
      subtitle: 'Resumen de la actividad del consultorio.',
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _MetricCard(
                icon: Icons.people,
                label: 'Pacientes',
                value: '${controller.patients.length}',
                color: MaxColors.blue,
                onTap: () => onOpenModule(1),
              ),
              _MetricCard(
                icon: Icons.today,
                label: 'Próximas citas',
                value: '${upcomingAppointments.length}',
                color: MaxColors.success,
                onTap: () => onOpenModule(2),
              ),
              _MetricCard(
                icon: Icons.medical_services,
                label: 'Consultas',
                value: '${controller.consultations.length}',
                color: const Color(0xFF8067D8),
                onTap: () => onOpenModule(2),
              ),
              _MetricCard(
                icon: Icons.image,
                label: 'Estudios',
                value: '${controller.studies.length}',
                color: const Color(0xFFE38B4B),
                onTap: () => onOpenModule(3),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Próximas citas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (upcomingAppointments.isEmpty)
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.event_available),
                      title: Text('No hay próximas citas programadas.'),
                    )
                  else
                    for (final appointment in upcomingAppointments.take(5))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          child: Icon(Icons.schedule, size: 19),
                        ),
                        title: Text(
                          controller
                                  .patientById(appointment.patientId)
                                  ?.fullName ??
                              'Paciente',
                        ),
                        subtitle: Text(appointment.reason),
                        trailing: Text(formatDateTime(appointment.dateTime)),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Atenciones recientes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (recent.isEmpty)
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.history),
                      title: Text('Aún no hay atenciones registradas.'),
                    )
                  else
                    for (final consultation in recent.take(5))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          child: Icon(
                            Icons.medical_information_outlined,
                            size: 19,
                          ),
                        ),
                        title: Text(
                          controller
                                  .patientById(consultation.patientId)
                                  ?.fullName ??
                              'Paciente',
                        ),
                        subtitle: Text(
                          consultation.diagnosis.isEmpty
                              ? 'Sin diagnóstico'
                              : consultation.diagnosis,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(formatDate(consultation.dateTime)),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
