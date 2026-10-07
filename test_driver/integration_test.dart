import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    writeResponseOnFailure: true,
    onScreenshot: (name, bytes, [args]) async {
      if (!RegExp(r'^MAX-[A-Za-z0-9-]+$').hasMatch(name)) return false;
      final file = File('../assets/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      return bytes.isNotEmpty;
    },
    responseDataCallback: (data) async {
      final report = Map<String, dynamic>.from(data ?? {})..remove('screenshots');
      await writeResponseData(report, destinationDirectory: 'reports', testOutputFilename: 'android-system-response');
    },
  );
}
