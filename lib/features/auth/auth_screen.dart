import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/app_controller.dart';
import '../../core/theme/max_theme.dart';
import '../../core/utils/validators.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _register = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    final controller = AppScope.of(context);
    final error = _register
        ? await controller.register(
            firstName: _firstName.text,
            lastName: _lastName.text,
            email: _email.text,
            password: _password.text,
          )
        : await controller.login(_email.text, _password.text);
    if (mounted && error != null) setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 40,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: constraints.maxWidth >= 760
                        ? IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Expanded(child: _AuthHero()),
                                Expanded(child: _form(controller)),
                              ],
                            ),
                          )
                        : Column(
                            children: [const _AuthHero(), _form(controller)],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form(AppController controller) => Padding(
    padding: const EdgeInsets.all(28),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _register ? 'Crear cuenta' : 'Iniciar sesión',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            _register
                ? 'Crea tu acceso al consultorio.'
                : 'Accede con tu cuenta del consultorio.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          if (_register) ...[
            TextFormField(
              controller: _firstName,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  MaxValidators.lettersAndSpaces,
                ),
                LengthLimitingTextInputFormatter(60),
              ],
              decoration: const InputDecoration(labelText: 'Nombres'),
              validator: (value) =>
                  MaxValidators.name(value, label: 'Los nombres', max: 60),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _lastName,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  MaxValidators.lettersAndSpaces,
                ),
                LengthLimitingTextInputFormatter(60),
              ],
              decoration: const InputDecoration(labelText: 'Apellidos'),
              validator: (value) =>
                  MaxValidators.name(value, label: 'Los apellidos', max: 60),
            ),
            const SizedBox(height: 14),
          ],
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            inputFormatters: [LengthLimitingTextInputFormatter(120)],
            decoration: const InputDecoration(
              labelText: 'Correo',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) => MaxValidators.email(value, required: true),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _password,
            obscureText: _hidePassword,
            autocorrect: false,
            inputFormatters: [LengthLimitingTextInputFormatter(120)],
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
                icon: Icon(
                  _hidePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              helperText: _register
                  ? '9+ caracteres, mayúscula, número y signo.'
                  : null,
              helperMaxLines: 2,
            ),
            validator: _register
                ? MaxValidators.password
                : (value) =>
                      MaxValidators.requiredText(value, label: 'La contraseña'),
          ),
          if (_register) ...[
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmPassword,
              obscureText: _hidePassword,
              inputFormatters: [LengthLimitingTextInputFormatter(120)],
              decoration: const InputDecoration(
                labelText: 'Confirmar contraseña',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirma la contraseña.';
                }
                return value != _password.text
                    ? 'Las contraseñas no coinciden.'
                    : null;
              },
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: controller.actionLoading ? null : _submit,
            child: controller.actionLoading
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_register ? 'Registrarme' : 'Ingresar'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: controller.actionLoading
                ? null
                : () => setState(() {
                    _register = !_register;
                    _error = null;
                    _formKey.currentState?.reset();
                  }),
            child: Text(
              _register
                  ? '¿Ya tienes cuenta? Inicia sesión'
                  : '¿No tienes cuenta? Crear una',
            ),
          ),
        ],
      ),
    ),
  );
}

class _AuthHero extends StatelessWidget {
  const _AuthHero();

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 280),
    padding: const EdgeInsets.all(34),
    color: Theme.of(context).brightness == Brightness.dark
        ? MaxColors.darkCanvas
        : MaxColors.canvas,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'M A X',
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: MaxColors.blue,
              letterSpacing: 7,
            ),
          ),
        ),
        const SizedBox(height: 26),
        Text(
          'Acceso seguro y rápido para gestionar pacientes, consultas y estudios.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 18),
        for (final item in [
          'Historial clínico en un solo lugar.',
          'Gestión rápida de pacientes y citas.',
          'Carga de imágenes y estudios.',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2, right: 9),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: MaxColors.blue,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
