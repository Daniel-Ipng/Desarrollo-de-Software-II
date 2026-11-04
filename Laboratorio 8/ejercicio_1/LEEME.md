# Práctica 08.1 – GPS y Servicios de Ubicación (Flutter)

## Pasos
1. `flutter create practica08` y copia `lib/` encima de la carpeta `lib/` generada.
2. Las dependencias ya están declaradas en `pubspec.yaml`; ejecuta `flutter pub get`.
3. Android ya incluye los permisos en `android/app/src/main/AndroidManifest.xml`; configura allí tu API key de Google Maps.
4. iOS: pega `config/Info.plist.fragmento.xml` dentro del `<dict>` de `ios/Runner/Info.plist`.
5. Pon tu API key de Google Maps en el manifest (y en AppDelegate si usas iOS).
6. `flutter run` en un dispositivo real (el emulador necesita ubicación simulada).

## Mapeo con la rúbrica
| Criterio | Dónde está |
|---|---|
| Configuración de plataforma y permisos | `config/`, `pubspec_dependencias.yaml` |
| Gestión de permisos y robustez | `LocationService.verificarPermisos()` + `_vistaError()` (GPS apagado, denegado, denegado permanente) |
| Posición única + stream | `obtenerPosicion()` / `rastrearPosicion()`; perfiles alta precisión (10 m) y ahorro (50 m) con botón en la AppBar |
| Mapa e interactividad | `GoogleMapController`, marcadores (long press), polilínea en tiempo real, `animateCamera` |

## Mejoras sobre la guía
- Imports completos (`dart:async`, `google_maps_flutter`).
- Errores tipados y pantalla de error con acciones (abrir ajustes / activar GPS / reintentar).
- La polilínea se reemplaza en vez de acumular duplicados en el `Set`.
- Verificación `mounted` tras awaits; cancelación del stream en `dispose`.
- Distancia recorrida y dirección (geocodificación inversa) en pantalla.
