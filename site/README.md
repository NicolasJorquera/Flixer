# Sitio de Flixer

Sitio web del desarrollador para la ficha de Play, en Firebase Hosting (sitio `flixer-app` del proyecto `flixer-app`), igual que Ludixa, TakeSync y FileFlow. Solo Hosting: este `firebase.json` no toca la Realtime Database del proyecto.

| Ruta | Qué es |
|---|---|
| `https://flixer-app.web.app/` | Portada con enlace a Play, política y contacto |
| `https://flixer-app.web.app/app-ads.txt` | `google.com, pub-3038495459046159, DIRECT, f08c47fec0942fa0` |
| `/privacidad`, `/privacy` | Redirigen a la política en TermsFeed |

## Publicar

```bash
cd site
firebase deploy --only hosting
```

## Después de publicar

1. Play Console › Store settings › Website: `https://flixer-app.web.app`.
2. AdMob › Apps › Flixer › App settings › Verify app (Google tarda hasta 24 h en rastrear `app-ads.txt`).
