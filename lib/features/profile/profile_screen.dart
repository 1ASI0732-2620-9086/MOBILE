import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../application/app_controller.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/max_theme.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/max_widgets.dart';
import '../../data/max_api.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  String _originalEmail = '';
  final _currentPassword = TextEditingController();
  String? _avatarUrl;
  String? _error;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final user = AppScope.of(context).user!;
    final nameParts = user.name.trim().split(RegExp(r'\s+'));
    _firstName = TextEditingController(
      text: user.firstName ?? (nameParts.isEmpty ? '' : nameParts.first),
    );
    _lastName = TextEditingController(
      text:
          user.lastName ??
          (nameParts.length < 2 ? '' : nameParts.skip(1).join(' ')),
    );
    _email = TextEditingController(text: user.email);
    _originalEmail = user.email.toLowerCase();
    _avatarUrl = user.avatarUrl;
    _initialized = true;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _currentPassword.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 88,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > AppConfig.maxAvatarBytes) {
      setState(() => _error = 'La imagen supera el máximo de 5 MiB.');
      return;
    }
    final mime = lookupMimeType(
      file.name,
      headerBytes: bytes.take(16).toList(),
    );
    if (mime != 'image/jpeg' && mime != 'image/png') {
      setState(
        () => _error = 'El avatar debe ser una imagen JPEG o PNG válida.',
      );
      return;
    }
    setState(() {
      _avatarUrl = MaxApi.avatarDataUrl(bytes, mime!);
      _error = null;
    });
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_key.currentState!.validate()) return;
    final error = await AppScope.of(context).updateProfile(
      firstName: _firstName.text,
      lastName: _lastName.text,
      email: _email.text,
      avatarUrl: _avatarUrl,
      currentPassword: _currentPassword.text,
    );
    if (!mounted) return;
    if (error == null) {
      _originalEmail = _email.text.trim().toLowerCase();
      _currentPassword.clear();
      showResult(context, null, success: 'Perfil actualizado.');
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final letterFormatters = [
      FilteringTextInputFormatter.allow(MaxValidators.lettersAndSpaces),
      LengthLimitingTextInputFormatter(60),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi perfil',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Form(
            key: _key,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      _Avatar(url: _avatarUrl, radius: 54),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: IconButton.filled(
                          onPressed: _pickAvatar,
                          icon: const Icon(Icons.camera_alt_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _avatarUrl == null
                      ? null
                      : () => setState(() => _avatarUrl = null),
                  child: const Text('Quitar foto'),
                ),
                const MaxSectionTitle('Datos personales'),
                TextFormField(
                  controller: _firstName,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: letterFormatters,
                  decoration: const InputDecoration(labelText: 'Nombres'),
                  validator: (v) =>
                      MaxValidators.name(v, label: 'Los nombres', max: 60),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastName,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: letterFormatters,
                  decoration: const InputDecoration(labelText: 'Apellidos'),
                  validator: (v) =>
                      MaxValidators.name(v, label: 'Los apellidos', max: 60),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  inputFormatters: [LengthLimitingTextInputFormatter(120)],
                  decoration: const InputDecoration(labelText: 'Correo'),
                  validator: (v) => MaxValidators.email(v, required: true),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _currentPassword,
                  obscureText: true,
                  inputFormatters: [LengthLimitingTextInputFormatter(120)],
                  decoration: const InputDecoration(
                    labelText: 'Contraseña actual',
                    helperText:
                        'Se solicitará si cambias información sensible.',
                    helperMaxLines: 2,
                  ),
                  validator: (value) {
                    final emailChanged =
                        _email.text.trim().toLowerCase() != _originalEmail;
                    if (emailChanged && (value == null || value.isEmpty)) {
                      return 'Ingresa tu contraseña actual para cambiar el correo.';
                    }
                    return null;
                  },
                ),
                const MaxSectionTitle('Información de la cuenta'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.verified_user_outlined),
                        title: const Text('Rol'),
                        trailing: Text(controller.user?.role ?? '--'),
                      ),
                      const Divider(height: 1),
                      const ListTile(
                        leading: Icon(Icons.schedule_outlined),
                        title: Text('Zona horaria'),
                        trailing: Text('America/Lima'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.history),
                        title: const Text('Último acceso'),
                        subtitle: Text(
                          formatDateTime(controller.user?.lastLogin),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: controller.actionLoading ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    controller.actionLoading
                        ? 'Guardando...'
                        : 'Guardar perfil',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: controller.actionLoading
                      ? null
                      : () => showDialog<void>(
                          context: context,
                          builder: (_) => const _PasswordDialog(),
                        ),
                  icon: const Icon(Icons.password),
                  label: const Text('Cambiar contraseña'),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: controller.actionLoading
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await controller.logout();
                        },
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.radius});
  final String? url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    if (url?.startsWith('data:') == true) {
      final comma = url!.indexOf(',');
      if (comma > 0) {
        try {
          image = MemoryImage(base64Decode(url!.substring(comma + 1)));
        } catch (_) {}
      }
    } else if (url?.startsWith('http') == true) {
      image = NetworkImage(url!);
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: MaxColors.paleBlue,
      backgroundImage: image,
      child: image == null
          ? Icon(Icons.person, size: radius, color: MaxColors.blue)
          : null,
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();
  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _key = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _hidden = true;
  String? _error;
  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_key.currentState!.validate()) return;
    final error = await AppScope.of(
      context,
    ).changePassword(_current.text, _next.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
      showResult(context, null, success: 'Contraseña actualizada.');
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = AppScope.of(context).actionLoading;
    InputDecoration decoration(String label) => InputDecoration(
      labelText: label,
      suffixIcon: IconButton(
        onPressed: () => setState(() => _hidden = !_hidden),
        icon: Icon(
          _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    );
    return AlertDialog(
      title: const Text('Cambiar contraseña'),
      content: Form(
        key: _key,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _current,
                obscureText: _hidden,
                inputFormatters: [LengthLimitingTextInputFormatter(120)],
                decoration: decoration('Contraseña actual'),
                validator: (value) => MaxValidators.requiredText(
                  value,
                  label: 'La contraseña actual',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _next,
                obscureText: _hidden,
                inputFormatters: [LengthLimitingTextInputFormatter(120)],
                decoration: decoration('Nueva contraseña').copyWith(
                  helperText: '9+ caracteres, mayúscula, número y signo.',
                  helperMaxLines: 2,
                ),
                validator: MaxValidators.password,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: _hidden,
                inputFormatters: [LengthLimitingTextInputFormatter(120)],
                decoration: decoration('Confirmar contraseña'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirma la nueva contraseña.';
                  }
                  return value != _next.text
                      ? 'Las contraseñas no coinciden.'
                      : null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: busy ? null : _save,
          child: Text(busy ? 'Guardando...' : 'Actualizar'),
        ),
      ],
    );
  }
}
