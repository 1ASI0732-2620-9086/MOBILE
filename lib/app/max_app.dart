import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import '../core/theme/max_theme.dart';
import '../features/auth/auth_screen.dart';
import '../features/shell/app_shell.dart';

class MaxApp extends StatefulWidget {
  const MaxApp({super.key});

  @override
  State<MaxApp> createState() => _MaxAppState();
}

class _MaxAppState extends State<MaxApp> {
  late final AppController controller;

  @override
  void initState() {
    super.initState();
    controller = AppController();
    controller.initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => MaterialApp(
          key: ValueKey(controller.user?.id ?? 'anonymous'),
          title: 'MAX',
          debugShowCheckedModeBanner: false,
          theme: MaxTheme.light(largeText: controller.largeText),
          darkTheme: MaxTheme.dark(largeText: controller.largeText),
          themeMode: controller.darkMode ? ThemeMode.dark : ThemeMode.light,
          home: switch (controller.state) {
            AppLoadState.pending ||
            AppLoadState.loading => const _SplashScreen(),
            AppLoadState.error => _StartupError(
              message: controller.errorMessage ?? 'No se pudo iniciar MAX.',
            ),
            AppLoadState.ready =>
              controller.isAuthenticated
                  ? AppShell(key: ValueKey(controller.user!.id))
                  : const AuthScreen(),
          },
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'M A X',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: MaxColors.blue,
              letterSpacing: 8,
            ),
          ),
          SizedBox(height: 28),
          CircularProgressIndicator(),
        ],
      ),
    ),
  );
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 52),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: AppScope.of(context).initialize,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
