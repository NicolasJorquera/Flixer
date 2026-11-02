# Mesa grupal: configuración de Firebase

La mesa en línea usa **Firebase Realtime Database** en el plan gratuito **Spark**. Sin una cuenta de facturación, Firebase no puede cobrar: si se llega al límite, la mesa en línea deja de responder hasta que se libera la cuota y la app ofrece jugar en un solo teléfono.

| Límite Spark (Realtime Database) | Valor |
|---|---|
| Conexiones simultáneas | 100 |
| Almacenamiento | 1 GB |
| Descarga | 10 GB/mes |

La app se conecta a Firebase solo mientras estás en una mesa y se desconecta al salir, así que las 100 conexiones son personas jugando al mismo tiempo, no usuarios de la app.

## Configuración (una sola vez)

### 1. Crear el proyecto

1. En [console.firebase.google.com](https://console.firebase.google.com) crea un proyecto **nuevo** (este repo usa `flixer-app`). Google Analytics no hace falta.
2. No uses el proyecto de Google Cloud de la cuenta de servicio de Play. Si ese proyecto llegara a tener facturación, Firebase lo pasaría al plan de pago Blaze.
3. Revisa que el plan diga **Spark** y nunca agregues una tarjeta.

### 2. Activar el inicio de sesión anónimo

**Build → Authentication → Get started → Sign-in method → Anonymous → Enable.** Cada teléfono entra sin cuenta; el ID anónimo solo sirve para que las reglas sepan quién vota.

### 3. Crear la base de datos

**Build → Realtime Database → Create database**, elige una ubicación (por ejemplo `us-central1`) y empieza en **locked mode**. Las reglas reales se suben en el paso 5.

### 4. Conectar la app

Instala las herramientas (una vez por máquina):

```bash
npm install -g firebase-tools
```

```bash
dart pub global activate flutterfire_cli
```

```bash
firebase login
```

Desde la raíz del repo, genera la configuración (reemplaza el ID del proyecto):

```bash
flutterfire configure --project=flixer-app --platforms=android,ios --yes
```

Esto reemplaza `lib/firebase_options.dart` y crea `android/app/google-services.json` e `ios/Runner/GoogleService-Info.plist`. Estos archivos identifican el proyecto pero no son secretos: lo que protege los datos son las reglas.

### 5. Subir las reglas

```bash
firebase deploy --only database --project flixer-app
```

Las reglas están en [`database.rules.json`](../database.rules.json):

- Solo usuarios con sesión anónima pueden leer o escribir, y solo dentro de `mesas/{código}`. Nadie puede listar las mesas.
- Solo el anfitrión crea, cambia el estado o borra su mesa. Un código existente no se puede pisar.
- Máximo **8 personas** por mesa y **30 títulos** por mazo; nombres de hasta 20 caracteres.
- Cada persona solo escribe sus propios votos, y solo mientras la mesa está votando.

## Datos

```
mesas/{código}: hostUid, createdAt, status (lobby | voting | done), mediaType,
                deck/{i} (id, título, póster, nota, año),
                members/{0..7}: {uid, name, done},
                votes/{0..7}/{i}: true | false
```

Una mesa pesa unos pocos KB. El anfitrión la borra al salir de los resultados. Si una mesa queda abandonada, no tiene costo y ocupa una fracción mínima del GB gratuito.
