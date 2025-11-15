# TaxiPro UsuarioX (Pasajero)

App Flutter del pasajero. Comparte el mismo proyecto Firebase con Chofer: `taxipro-chofer`.

## Requisitos
- Flutter 3.x y Dart >= 3.0
- Android Studio o VS Code con extensiones Flutter
- Cuenta de Firebase con proyecto: `taxipro-chofer`

## Configuración
- **Variables de entorno (`.env`)**
  - Copia `./.env.example` a `./.env` y completa:
    - `GOOGLE_API_KEY` (Geocoding/Places Web Service)
    - `STRIPE_PUBLISHABLE_KEY`
  - El archivo `.env` ya está ignorado por git.

- **Google Services (Android)**
  - Asegúrate de tener `android/app/google-services.json` del proyecto `taxipro-chofer`.

- **Google Maps Android SDK**
  - Copia `android/local.properties.example` a `android/local.properties` y define:
    - `MAPS_API_KEY=TU_API_KEY_ANDROID`
  - El `AndroidManifest.xml` usa `${MAPS_API_KEY}` como placeholder.

- **Firebase Options**
  - `lib/firebase_options.dart` debe apuntar a `taxipro-chofer` en todas las plataformas.
  - Si necesitas regenerarlo: `flutterfire configure --project taxipro-chofer`.

## Comandos básicos
```bash
flutter pub get
flutter analyze
flutter run -d <device>
# o
flutter build apk
```

## Estructura relevante
- `lib/` Código fuente de la app del pasajero
- `assets/` Recursos (branding, splash, fuentes)
- `android/app/src/main/AndroidManifest.xml` Package: `com.taxipro.usuariox`
- `android/app/build.gradle.kts` Placeholder de Maps: `${MAPS_API_KEY}`

## Notas de seguridad
- No compartas `.env` ni `android/local.properties`.
- Las claves reales deben configurarse localmente (no se suben a git).

## Problemas comunes
- Error de Maps: añade `MAPS_API_KEY` en `android/local.properties`.
- Geocoding falla: completa `GOOGLE_API_KEY` en `.env`.
- Stripe no inicia: completa `STRIPE_PUBLISHABLE_KEY` en `.env`.

## Git y despliegue
1) Inicializa el repositorio y primer commit.
2) Configura el remoto y haz push a `main`.

Ejemplo de comandos:
```bash
git init
git add .
git commit -m "chore: bootstrap app pasajero (proyecto Firebase: taxipro-chofer)"
git branch -M main
git remote add origin <git@github.com:OWNER/REPO.git>
git push -u origin main
```
