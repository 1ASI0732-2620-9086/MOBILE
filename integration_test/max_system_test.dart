import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:max_mobile/app/max_app.dart';
import 'package:max_mobile/core/network/api_client.dart';
import 'package:max_mobile/core/config/app_config.dart';
import 'package:max_mobile/data/max_api.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android real: IAM, paciente, edición, estudio y logout', (tester) async {
    final endpoint = Uri.parse(AppConfig.apiBaseUrl);
    expect(['10.0.2.2', '127.0.0.1', 'localhost'].contains(endpoint.host), isTrue, reason: 'Se exige API de pruebas local.');
    final api = MaxApi(ApiClient());
    await api.logout();
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final email = 'android-$stamp@example.test';
    final dni = (10000000 + stamp % 80000000).toString();
    Finder field(String label) => find.byWidgetPredicate((widget) => widget is TextField && widget.decoration?.labelText == label);
    Future<void> visible(Finder finder) async {
      for (var attempt = 0; attempt < 100; attempt++) {
        await tester.pump(const Duration(milliseconds: 300));
        if (finder.evaluate().isNotEmpty) return;
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      expect(finder, findsWidgets);
    }
    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder.first);
      await tester.tap(finder.first);
      await tester.pumpAndSettle();
    }
    Future<void> fill(String label, String value) async {
      final finder = field(label).last;
      await tester.ensureVisible(finder);
      await tester.enterText(finder, value);
      await tester.pump();
    }
    await tester.pumpWidget(const MaxApp());
    await visible(find.text('Ingresar'));
    await tap(find.text('¿No tienes cuenta? Crear una'));
    await fill('Nombres', 'Doctor');
    await fill('Apellidos', 'Prueba');
    await fill('Correo', email);
    await fill('Contraseña', 'SyntheticOnly#123');
    await fill('Confirmar contraseña', 'SyntheticOnly#123');
    await tap(find.text('Registrarme'));
    await visible(find.byType(NavigationBar));
    await tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Pacientes')));
    expect(find.text('Sin resultados'), findsOneWidget);
    await tap(find.byTooltip('Nuevo paciente'));
    await fill('Nombres', 'Ana');
    await fill('Apellidos', 'Sintetica');
    await fill('DNI', dni);
    await tap(field('Fecha de nacimiento'));
    await tap(find.text('OK'));
    await tap(find.text('Sexo'));
    await tap(find.text('Femenino').last);
    await fill('Antecedentes médicos', 'Historial Android sintético');
    await tap(find.text('Guardar'));
    await visible(find.text('Ana Sintetica'));
    final stored = (await api.patients()).singleWhere((patient) => patient.dni == dni);
    expect(stored.firstName, 'Ana');
    await tap(find.byType(PopupMenuButton<String>));
    await tap(find.text('Editar'));
    await fill('Nota inicial del caso', 'Observación Android actualizada');
    await tap(find.text('Guardar'));
    await visible(find.text('Ana Sintetica'));
    expect((await api.patients()).singleWhere((patient) => patient.id == stored.id).notes, 'Observación Android actualizada');
    final bytes = Uint8List.fromList(base64Decode('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'));
    // Esta parte comprueba integración del cliente nativo con API/BD; el selector del sistema operativo no se simula.
    final study = await api.uploadStudy(patientId: stored.id, type: 'RX', date: '2026-10-07', description: 'Imagen Android sintética', fileName: 'android-sintetica.png', bytes: bytes);
    expect(study.patientId, stored.id);
    await tap(find.byTooltip('Actualizar'));
    await tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Estudios')));
    await visible(find.text('Imagen Android sintética'));
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('MAX-System-Android-Recorrido');
    await tap(find.text('Imagen Android sintética'));
    await visible(find.text('android-sintetica.png'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudo mostrar la imagen.'), findsNothing);
    await binding.takeScreenshot('MAX-System-Android-Estudio');
    await tap(find.byTooltip('Back'));
    await tap(find.byTooltip('Open navigation menu'));
    await tap(find.text('Cerrar sesión'));
    await visible(find.text('Ingresar'));
    await expectLater(api.me(), throwsA(isA<ApiException>()));
    binding.reportData = {...?binding.reportData, 'api': AppConfig.apiBaseUrl, 'account': 'sintética', 'patientDni': dni, 'storage': 'none / archivo embebido', 'filePicker': 'No automatizado: carga ejecutada mediante cliente API nativo'};
  });
}
