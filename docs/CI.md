# Pruebas y GitHub Actions

Rama: `ci/max-tests-actions`. Workflow: **MAX Android CI**,
`.github/workflows/ci.yml` en la raíz del repositorio.
Se ejecuta al publicar esta rama y en PR hacia `main`.

Flutter 3.41.9, Java 21, instalación con lockfile obligatorio,
`flutter analyze`, 22 pruebas de modelos/validación, IAM, pacientes, estudios,
transporte de archivos y visor; después construye un APK debug interno.
La fecha de estudio se envía como ISO datetime y el visor admite imágenes data URI
históricas; ambas correcciones quedan cubiertas por las pruebas publicadas.

```powershell
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:18080/api
```

El APK usa el backend local de pruebas del emulador. No se distribuye a Play Store.
El CI básico no arranca un emulador ni ejecuta el recorrido instrumental Android;
la suite `integration_test/` y `test_driver/` queda publicada para ejecutarlo aparte
con una API/MySQL sintética y un dispositivo o emulador disponibles.

Artefactos:

- `android-reports-<SHA>`: salida JSON del runner Flutter.
- `android-internal-<SHA>`: APK debug, commit y SHA-256; solo tras aprobar las comprobaciones.

No necesita secretos ni credenciales de producción. Actions debe permitir checkout,
setup-java, flutter-action y upload-artifact. No se encontró ningún workflow existente
de publicación Android ni despliegues registrados en GitHub.

**MAX Delivery Candidate**, `delivery.yml`, es manual y recupera/verifica un candidato
de CI aprobado en `main`; no publica aplicaciones. No requiere firma de distribución.
Los workflows manuales nuevos aparecerán cuando existan en la rama por defecto;
el CI por PR no requiere fusionar ni desplegar.
