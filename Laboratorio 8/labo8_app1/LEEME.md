# Práctica 08.1 - GPS y Cámara (Flutter, Android) con mapa gratuito

## Pasos
1. Copia la carpeta `lib/` sobre la de tu proyecto (reemplaza `main.dart`).
2. Copia `android/app/src/main/res/xml/file_paths.xml` a la misma ruta en tu proyecto (crea la carpeta `xml` si no existe).
3. Abre `pubspec_dependencias.txt`, pega esas líneas en `dependencies:` de tu `pubspec.yaml` y ejecuta `flutter pub get`.
4. Abre `AndroidManifest_AGREGAR.xml` y pega los permisos y el `<provider>` en tu `AndroidManifest.xml`.
5. En `lib/screens/mapa_screen.dart`, cambia `userAgentPackageName: 'com.example.practica08'` por el `applicationId` de tu proyecto (está en `android/app/build.gradle`). OpenStreetMap lo exige.
6. Ejecuta en un celular físico (el emulador no tiene cámara real y su GPS es simulado): `flutter run`.

## Qué cubre la rúbrica
- Configuración y permisos: dependencias + permisos Android con FileProvider.
- Robustez: `LocationService.verificarPermisos()` maneja GPS apagado, denegado y denegado permanente; la cámara usa `permission_handler` con botón "Abrir ajustes".
- Geolocalización: `getCurrentPosition` y `getPositionStream` con perfiles alta precisión / ahorro de batería (interruptor en la barra superior).
- Mapa: flutter_map + OpenStreetMap, marcador propio, marcadores con pulsación larga (toque = borrar), polilínea de la ruta en tiempo real y cámara que sigue al usuario.
- Cámara: preview, foto, video (pulsación larga), zoom con pellizco, enfoque al tocar, flash y cambio de cámara.

## Si falla la compilación
- Error de `compileSdk`/`minSdk`: en `android/app/build.gradle` pon `minSdk = 21` (o `minSdkVersion 21`) y `compileSdk` 34 o más.
- Si usas iOS más adelante, agrega a `Info.plist` las claves NSLocationWhenInUseUsageDescription, NSCameraUsageDescription, NSMicrophoneUsageDescription, NSPhotoLibraryUsageDescription y NSPhotoLibraryAddUsageDescription (textos de la guía).
