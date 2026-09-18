# MAX Mobile

Aplicación Android en Flutter para usar los mismos perfiles, pacientes, citas, consultas y estudios de MAX Web. La aplicación consume el backend Spring Boot; nunca se conecta directamente a MySQL ni a R2.

## Requisitos

- Flutter 3.41 o posterior.
- Android Studio con Android SDK instalado.
- Backend MAX activo y conectado a su base de datos.
- Un emulador Android o un teléfono con depuración USB.

## Ejecutar con Android Studio

1. Abre esta carpeta como proyecto: `C:\Users\oscar\OneDrive\Desktop\PROJECTS\MAX\MAX_MOBILE`.
2. Espera a que Android Studio termine `pub get` y la sincronización Gradle.
3. En **Device Manager**, crea o inicia un emulador Android.
4. Comprueba que el backend escuche en el puerto `8080`.
5. Selecciona `lib/main.dart` y pulsa **Run**.

El valor predeterminado para el emulador es:

```text
http://10.0.2.2:8080/api
```

`10.0.2.2` es la dirección que usa el emulador Android para acceder al `localhost` de Windows.

## Ejecutar desde terminal

```powershell
cd C:\Users\oscar\OneDrive\Desktop\PROJECTS\MAX\MAX_MOBILE
flutter pub get
flutter devices
flutter run
```

Para un teléfono Android conectado por USB, se puede mantener la URL predeterminada redirigiendo el puerto:

```powershell
adb reverse tcp:8080 tcp:8080
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8080/api
```

Para usar una URL HTTPS publicada o una IP accesible desde el teléfono:

```powershell
flutter run --dart-define=API_BASE_URL=https://api.ejemplo.com/api
```

La compilación `debug` permite HTTP exclusivamente para probar el backend local. La compilación de producción mantiene HTTP desactivado y debe usar HTTPS.

## Verificación

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

El APK de depuración se genera en `build\app\outputs\flutter-apk\app-debug.apk`.

## Sesión y seguridad

- La sesión JWT se recibe como cookie de Spring Boot.
- Las cookies de sesión y CSRF se guardan con `flutter_secure_storage`.
- Cada cookie queda aislada por el origen configurado en `API_BASE_URL`.
- El token CSRF se envía en `X-XSRF-TOKEN` para escrituras y cargas multipart.
- No se guardan JWT, avatares ni datos clínicos en `SharedPreferences`.
- Al cerrar sesión se borran cookies y datos clínicos en memoria.
- Las respuestas iniciadas por una sesión anterior se descartan si el usuario cambia.
- Android Backup está desactivado para impedir copias del estado privado de la aplicación.

## Funciones incluidas

- Inicio de sesión, registro y recuperación de sesión.
- Panel con métricas y actividad reciente.
- Pacientes: búsqueda, alta con historial inicial, consulta, edición y eliminación.
- Consultas: agenda de citas, atenciones, historial y archivos relacionados.
- Estudios: carga validada de JPEG, PNG, WebP y PDF hasta 20 MiB, URL firmada y eliminación.
- Perfil: datos personales, avatar, contraseña y cierre de sesión.
- Configuración: tema, tamaño de texto, idioma español y notificaciones.
- Administración: límite de perfiles, suplantación trazable y eliminación confirmada.

Antes de publicar una versión release se debe configurar una clave de firma privada de Android. El proyecto no usa la clave de depuración para producción.
