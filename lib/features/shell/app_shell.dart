import 'dart:convert';

import 'package:flutter/material.dart';

import '../../application/app_controller.dart';
import '../../core/theme/max_theme.dart';
import '../../core/widgets/max_widgets.dart';
import '../admin/admin_screen.dart';
import '../consultations/consultations_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../patients/patients_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../studies/studies_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  static const _titles = ['Inicio', 'Pacientes', 'Consultas', 'Estudios'];

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final pages = [
      DashboardScreen(onOpenModule: (index) => setState(() => _index = index)),
      const PatientsScreen(),
      const ConsultationsScreen(),
      const StudiesScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'MAX',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: MaxColors.blue,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              _titles[_index],
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: controller.actionLoading
                ? null
                : () async {
                    final error = await controller.refreshClinical();
                    if (!context.mounted) return;
                    showResult(context, error, success: 'Datos actualizados.');
                  },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      drawer: _MainDrawer(
        selectedIndex: _index,
        onSelect: (index) {
          Navigator.pop(context);
          setState(() => _index = index);
        },
      ),
      body: Stack(
        children: [
          IndexedStack(index: _index, children: pages),
          if (controller.actionLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Pacientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services),
            label: 'Consultas',
          ),
          NavigationDestination(
            icon: Icon(Icons.image_outlined),
            selectedIcon: Icon(Icons.image),
            label: 'Estudios',
          ),
        ],
      ),
    );
  }
}

class _MainDrawer extends StatelessWidget {
  const _MainDrawer({required this.selectedIndex, required this.onSelect});
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  Future<void> _open(BuildContext context, Widget page) async {
    Navigator.pop(context);
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final user = controller.user!;
    return NavigationDrawer(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelect,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 36, 22, 20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: MaxColors.paleBlue,
                backgroundImage: _avatar(user.avatarUrl),
                child: _avatar(user.avatarUrl) == null
                    ? Text(
                        user.name.isEmpty ? 'M' : user.name[0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.dashboard_outlined),
          label: Text('Inicio'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.people_outline),
          label: Text('Pacientes'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.medical_services_outlined),
          label: Text('Consultas'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.image_outlined),
          label: Text('Estudios'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('Mi perfil'),
          onTap: () => _open(context, const ProfileScreen()),
        ),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text('Configuración'),
          onTap: () => _open(context, const SettingsScreen()),
        ),
        if (user.isAdmin)
          ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined),
            title: const Text('Administración'),
            onTap: () => _open(context, const AdminScreen()),
          ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Cerrar sesión'),
          onTap: controller.actionLoading
              ? null
              : () async {
                  Navigator.pop(context);
                  await controller.logout();
                },
        ),
      ],
    );
  }

  ImageProvider? _avatar(String? value) {
    if (value?.startsWith('http') == true) return NetworkImage(value!);
    if (value?.startsWith('data:') == true) {
      final comma = value!.indexOf(',');
      if (comma > 0) {
        try {
          return MemoryImage(base64Decode(value.substring(comma + 1)));
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }
}
