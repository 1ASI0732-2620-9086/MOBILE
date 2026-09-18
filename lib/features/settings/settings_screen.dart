import 'package:flutter/material.dart';

import '../../application/app_controller.dart';
import '../../core/config/app_config.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: controller.darkMode,
                  onChanged: controller.setDarkMode,
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Tema oscuro'),
                  subtitle: const Text(
                    'Cambia la apariencia de toda la aplicación.',
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: controller.largeText,
                  onChanged: controller.setLargeText,
                  secondary: const Icon(Icons.text_increase),
                  title: const Text('Texto grande'),
                  subtitle: const Text(
                    'Aumenta el tamaño para facilitar la lectura.',
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: controller.notificationsEnabled,
                  onChanged: controller.setNotifications,
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Notificaciones'),
                  subtitle: const Text(
                    'Preferencia local para avisos de la aplicación.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Idioma'),
              subtitle: const Text(
                'La versión inicial conserva el contenido en español.',
              ),
              trailing: DropdownButton<String>(
                value: controller.language,
                underline: const SizedBox(),
                items: const [DropdownMenuItem(value: 'es', child: Text('ES'))],
                onChanged: (value) {
                  if (value != null) controller.setLanguage(value);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: const Text('Servidor de datos'),
              subtitle: Text(AppConfig.apiBaseUrl),
            ),
          ),
          const SizedBox(height: 14),
          const Center(child: Text('MAX Mobile · 1.0.0')),
        ],
      ),
    );
  }
}
