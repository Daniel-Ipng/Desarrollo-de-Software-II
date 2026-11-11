# Práctica 10 – Flutter: Integración de servicios externos

Contenido: `lib/` (Ejercicio 1 y 2) y `backend/` (API REST con JWT para el Ejercicio 2).

## 1. Dependencias (en la raíz de tu proyecto Flutter)

```bash
flutter pub add http dio flutter_riverpod:^2.6.1 flutter_secure_storage:^9.2.2 shared_preferences
```

Requiere Dart 3 / Flutter 3.10 o superior (usa `switch` con patrones y `sealed class`).

## 2. Copiar el código

Borra el contenido de tu `lib/` y copia la carpeta `lib/` de este zip (reemplaza `main.dart`).
Todos los imports son relativos, así que no depende del nombre de tu proyecto.

## 3. Permisos Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.INTERNET" />

<application
    android:usesCleartextTraffic="true"   <!-- la API local usa http, no https -->
    ... >
```

## 4. Ejercicio 1 – API key de OpenWeatherMap

Regístrate en openweathermap.org y copia tu key (las keys nuevas pueden tardar hasta ~2 h en activarse; mientras tanto la app muestra el error de API key, que es parte del ejercicio).

```bash
flutter run --dart-define=OPENWEATHER_API_KEY=TU_KEY
```

(o pega la key en `defaultValue` de `lib/ejercicio1_clima/weather_constants.dart`; no la subas a git).

## 5. Ejercicio 2 – Levantar la API

```bash
cd backend
npm install
npm start                    # http://localhost:3000
# Para probar el refresh automático del token (access token de 20 s):
#   Linux/Mac: ACCESS_TTL=20s npm start      Windows PowerShell: $env:ACCESS_TTL="20s"; npm start
```

Necesitas Node.js 18+. Luego ejecuta la app:

- **Emulador Android:** `flutter run` (usa `http://10.0.2.2:3000` por defecto).
- **Celular físico (misma red Wi-Fi):** `flutter run --dart-define=API_BASE_URL=http://TU_IP_LOCAL:3000`
  o con USB: `adb reverse tcp:3000 tcp:3000` y `--dart-define=API_BASE_URL=http://localhost:3000`.

Puedes combinar ambos: `flutter run --dart-define=OPENWEATHER_API_KEY=... --dart-define=API_BASE_URL=...`

## Estructura

```
lib/
├── main.dart, home_page.dart            (menú de ejercicios)
├── ejercicio1_clima/                    (Ejercicio 1)
├── core/                                (Ejercicio 2)
│   ├── network/  dio_factory, auth_interceptor, error_interceptor, logging_interceptor
│   ├── exceptions/api_exceptions.dart   (sealed class)
│   ├── storage/token_storage.dart       (flutter_secure_storage)
│   └── ...
└── features/
    ├── auth/   data / domain / presentation
    └── tasks/  data / domain / presentation
```
