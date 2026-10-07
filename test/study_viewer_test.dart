import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:max_mobile/features/shared/study_viewer.dart';

void main() {
  testWidgets('la imagen histórica embebida usa bytes y conserva el visor', (tester) async {
    const png = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
    await tester.pumpWidget(const MaterialApp(home: StudyImage(url: 'data:image/png;base64,$png')));
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<MemoryImage>());
    expect((image.image as MemoryImage).bytes, isNotEmpty);
  });
  testWidgets('referencia embebida no imagen muestra un error accionable', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StudyImage(url: 'data:text/plain;base64,SG9sYQ==')));
    expect(find.text('No se pudo mostrar la imagen.'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
