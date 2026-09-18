import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/app_controller.dart';
import '../../core/widgets/max_widgets.dart';
import '../../domain/models.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _limit = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final error = await AppScope.of(context).loadAdmin();
    if (!mounted) return;
    setState(() {
      _error = error;
      _limit.text =
          AppScope.of(context).profileLimit?.maxProfiles.toString() ?? '';
    });
  }

  Future<void> _saveLimit() async {
    final value = int.tryParse(_limit.text);
    if (value == null || value < 1 || value > 10000) {
      setState(() => _error = 'Ingresa un límite entre 1 y 10000.');
      return;
    }
    final error = await AppScope.of(context).updateLimit(value);
    if (mounted) {
      setState(() => _error = error);
      showResult(context, error, success: 'Límite actualizado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final limit = controller.profileLimit;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Administración',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              'Perfiles del consultorio',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Administra el cupo y accede a cada perfil con trazabilidad.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Límite de perfiles',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (limit != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          '${limit.usedProfiles} de ${limit.maxProfiles} perfiles utilizados',
                        ),
                      ),
                    TextField(
                      controller: _limit,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(5),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Máximo de perfiles',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: controller.actionLoading ? null : _saveLimit,
                      child: const Text('Guardar límite'),
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 16),
            if (controller.actionLoading && controller.adminProfiles.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (controller.adminProfiles.isEmpty)
              const EmptyState(
                icon: Icons.manage_accounts_outlined,
                title: 'Sin perfiles',
                message: 'No hay perfiles de usuario registrados.',
              )
            else
              for (final profile in controller.adminProfiles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            child: Text(
                              profile.name.isEmpty
                                  ? 'U'
                                  : profile.name[0].toUpperCase(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(profile.email),
                                Text(
                                  '${profile.role} · Alta: ${formatDateTime(profile.createdAt)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'enter') _impersonate(profile);
                              if (value == 'delete') _delete(profile);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'enter',
                                child: ListTile(
                                  leading: Icon(Icons.login),
                                  title: Text('Entrar al perfil'),
                                  dense: true,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete_forever_outlined),
                                  title: Text('Eliminar perfil'),
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
        ),
      ),
    );
  }

  Future<void> _impersonate(AdminProfile profile) async {
    final confirm = await confirmAction(
      context,
      title: 'Entrar al perfil',
      message: 'La sesión cambiará al perfil de ${profile.name}.',
      confirmText: 'Entrar',
      danger: false,
    );
    if (!confirm || !mounted) return;
    final error = await AppScope.of(context).impersonate(profile);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      showResult(context, error);
    }
  }

  Future<void> _delete(AdminProfile profile) async {
    final deleted = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteProfileDialog(profile: profile),
    );
    if (deleted == true && mounted) setState(() {});
  }
}

class _DeleteProfileDialog extends StatefulWidget {
  const _DeleteProfileDialog({required this.profile});
  final AdminProfile profile;
  @override
  State<_DeleteProfileDialog> createState() => _DeleteProfileDialogState();
}

class _DeleteProfileDialogState extends State<_DeleteProfileDialog> {
  final _email = TextEditingController();
  final _phrase = TextEditingController();
  bool _acknowledge = false;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    _phrase.dispose();
    super.dispose();
  }

  bool get _valid =>
      _email.text.trim().toLowerCase() == widget.profile.email.toLowerCase() &&
      _phrase.text.trim().toUpperCase() == 'ELIMINAR TODO' &&
      _acknowledge;

  Future<void> _delete() async {
    final error = await AppScope.of(context).deleteAdminProfile(widget.profile);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
      showResult(context, null, success: 'Perfil y sus datos eliminados.');
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Eliminar perfil completo'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Esta acción eliminará el perfil de ${widget.profile.name} y sus datos asociados según las reglas actuales.',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            inputFormatters: [LengthLimitingTextInputFormatter(120)],
            decoration: InputDecoration(
              labelText: 'Escribe ${widget.profile.email}',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phrase,
            inputFormatters: [LengthLimitingTextInputFormatter(13)],
            decoration: const InputDecoration(
              labelText: 'Escribe ELIMINAR TODO',
            ),
            onChanged: (_) => setState(() {}),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _acknowledge,
            onChanged: (value) => setState(() => _acknowledge = value ?? false),
            title: const Text('Entiendo que esta acción no se puede deshacer.'),
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
        onPressed: _valid && !AppScope.of(context).actionLoading
            ? _delete
            : null,
        child: const Text('Eliminar'),
      ),
    ],
  );
}
