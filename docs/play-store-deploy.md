# Despliegue a Play Store

El workflow [`.github/workflows/play-store.yml`](../.github/workflows/play-store.yml) compila el App Bundle firmado y lo sube a Play Store.

- **Se dispara** al pushear un tag `v*` (por ejemplo `v1.2.0`), o a mano desde la pestaña Actions eligiendo el track.
- **Track por defecto:** `internal`. Desde Play Console se promueve a producción cuando la versión está revisada.
- **versionName:** sale del tag (`v1.2.0` → `1.2.0`).
- **versionCode:** es `número de ejecución del workflow + VERSION_CODE_OFFSET`, así que siempre sube.

## Configuración (una sola vez)

### 1. Crear una upload key nueva

La upload key original se perdió, así que hay que crear una nueva y pedirle a Google que la acepte. Ejecútalo en tu máquina, nunca en el repo:

```bash
keytool -genkeypair -v -keystore ~/flixer-upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

Exporta el certificado público para enviárselo a Google:

```bash
keytool -export -rfc -keystore ~/flixer-upload.jks -alias upload -file ~/flixer-upload-cert.pem
```

Guarda el `.jks` y sus contraseñas en tu gestor de contraseñas. Si se vuelven a perder, hay que repetir el reset.

### 2. Pedir el reset de la upload key en Play Console

En Play Console, entra a Flixer → **Test and release → App integrity → App signing** y elige **Request upload key reset**. Sube `flixer-upload-cert.pem`.

Esto solo funciona si la app usa **Play App Signing** (es decir, Google guarda la clave de firma final). Si en esa pantalla no aparece la opción, la app firma con la clave original y no hay forma de actualizarla. En ese caso habría que publicarla como app nueva, con otro `applicationId`.

Google tarda unos días en aplicar el reset. Hasta entonces el workflow compila, pero la subida falla.

### 3. Crear la cuenta de servicio de Google Play

1. En Google Cloud Console, crea un proyecto (o usa uno existente) y habilita la **Google Play Android Developer API**.
2. Crea una cuenta de servicio y genera una clave en formato **JSON**.
3. En Play Console, ve a **Users and permissions → Invite new users** e invita el email de la cuenta de servicio. En **App permissions**, agrega Flixer con el permiso **Release to testing tracks** (y **Release to production** si vas a publicar en producción desde el workflow).

### 4. Cargar los secretos en GitHub

En el repo, ve a **Settings → Environments → New environment** y crea `play-store`. Agrega estos secretos a ese environment:

| Secreto | Valor |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | El resultado de `base64 -i ~/flixer-upload.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | La contraseña del keystore |
| `ANDROID_KEY_ALIAS` | `upload` (o el alias que usaste) |
| `ANDROID_KEY_PASSWORD` | La contraseña de la key |
| `PLAY_SERVICE_ACCOUNT_JSON` | El contenido completo del JSON de la cuenta de servicio |

En **Settings → Secrets and variables → Actions → Variables**, crea `VERSION_CODE_OFFSET` con un número mayor que el último versionCode publicado. Ese número aparece en Play Console → **App bundle explorer**. Si no defines la variable, el workflow usa 100.

Opcional: en el environment `play-store` puedes activar **Required reviewers** para aprobar a mano cada publicación.

## Publicar una versión

```bash
git tag v1.2.0
```

```bash
git push origin v1.2.0
```

El workflow sube la versión al track `internal`. El `.aab` también queda como artefacto de la ejecución durante 30 días.

## Builds locales

Sin `android/key.properties`, `flutter build appbundle --release` firma con la clave de debug. Sirve para probar, pero Play Store no acepta ese bundle. Para firmar en local con la upload key, crea `android/key.properties` (ya está en `.gitignore`):

```properties
storeFile=/ruta/a/flixer-upload.jks
storePassword=...
keyAlias=upload
keyPassword=...
```
