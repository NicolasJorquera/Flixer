# Evaluación de API de metadatos para monetizar Flixer

Fecha: 2026-11-16 · Alcance: evaluación técnica y lectura de términos públicos. No se migró código ni se crearon cuentas, claves ni registros en ningún servicio. **La interpretación contractual y las licencias se validan con Legal/Administración; la decisión de pagar o no una licencia es de Gestión y Finanzas.**

## Resumen (5 líneas)

1. Con AdMob y la compra «Sin anuncios», Flixer es **uso comercial** para TMDB: sus términos nombran la publicidad y exigen un acuerdo escrito; el precio no es público ([términos §2.A](https://www.themoviedb.org/api-terms-of-use)).
2. **Ninguna API gratuita cubre lo que Flixer hace hoy**: el filtro y la ficha «dónde ver» (datos de JustWatch) no tienen sustituto gratis con uso comercial y cupo suficiente, y solo TMDB reúne en una fuente sinopsis en español latino en las listas, recomendaciones y descubrir con filtros combinados por plataforma.
3. **Recomendación: pedir cotización de licencia comercial a TMDB (sales@themoviedb.org) y, en paralelo, solicitar acceso de producción a Trakt.** Si TMDB cotiza un precio asumible, seguir con TMDB (≈ 1 día de trabajo, sin perder funciones).
4. **Plan B: Trakt**, la única candidata que permite expresamente apps gratis «supported by advertising» y con compras únicas, sin umbral de ingresos ([política de uso de la API](https://developer.trakt.tv/docs/api-use-policy)). Exige cuenta de GitHub verificada, revisión de acceso de producción, cachear imágenes (no hotlink) y aviso de no respaldo; **no da «dónde ver»** en el acceso estándar. TheTVDB (gratis < 50 000 USD/año) queda como plan C; TVmaze y Wikidata, solo complementos; OMDb, fanart.tv y Simkl, descartados.
5. Esfuerzo del plan B: **≈ 9–13 días** de desarrollo detrás de una interfaz `MetadataProvider`, más el registro en Trakt y la prueba con clave (lo hace el dueño).

---

## 1. Inventario: qué usa Flixer hoy de TMDB

Todas las llamadas pasan por `tmdbGet()` ([tmdb.dart](../lib/src/apiFunctions/tmdb.dart)), que añade `api_key` y `language` (`es-MX` o `en-US`). Región seleccionable: `CL` (por defecto) o `US` ([main.dart:33-34](../lib/main.dart)). Imágenes desde `image.tmdb.org/t/p/w500` y `/original` ([constants.dart](../lib/global/constants.dart)).

| # | Funcionalidad | Dónde | Endpoint / campos TMDB |
|---|---|---|---|
| 1 | Fila «Tendencias» | [catalog.dart](../lib/src/apiFunctions/catalog.dart) `homeSections` | `/trending/{movie,tv}/week` |
| 2 | «En cines» / «Próximamente» (películas) | catalog.dart | `/movie/now_playing`, `/movie/upcoming` con `region` |
| 3 | «En emisión» (series) | catalog.dart | `/tv/on_the_air` |
| 4 | «Popular en streaming» | catalog.dart | `/discover/{type}` `sort_by=popularity.desc`, `watch_region`, `with_watch_monetization_types=flatrate` |
| 5 | «Mejor valoradas» | catalog.dart | `/discover` `sort_by=vote_average.desc`, `vote_count.gte` |
| 6 | Filas por género (8 de películas, 7 de series) | catalog.dart, [homeFeed.dart](../lib/src/widgets/homeFeed.dart) | `/genre/{type}/list` (nombres traducidos) + `/discover` `with_genres` con IDs fijos de TMDB |
| 7 | Barra de plataformas (filtro de la home) | [app.dart:48](../lib/src/app.dart), [providerBar.dart](../lib/src/widgets/providerBar.dart) | `/watch/providers/{movie,tv}?watch_region` (`provider_id`, `logo_path`, `display_priorities`); luego `/discover` con `with_watch_providers` (OR), `with_watch_monetization_types=flatrate\|free\|ads` y secciones popular / mejor valoradas / recientes (`primary_release_date.lte`) |
| 8 | Explorar (grilla paginada + filtro de géneros) | [exploreView.dart](../lib/src/views/exploreView.dart) | Las mismas consultas con `page`; `total_pages` (tope 500); `with_genres` múltiple |
| 9 | Búsqueda (películas, series y personas) | [search.dart](../lib/src/apiFunctions/search.dart), [searchView.dart](../lib/src/views/searchView.dart) | `/search/multi` (`media_type`, `poster_path`, `profile_path`) |
| 10 | Ficha: título, sinopsis, nota, fecha, backdrop, géneros | [movieInfo.dart:64-98](../lib/src/widgets/movieInfo.dart) | `/{movie,tv}/{id}` `append_to_response=videos,credits,recommendations,watch/providers` |
| 11 | Trailer embebido (autoplay silenciado) | movieInfo.dart | `videos` (`site=YouTube`, `type=Trailer`, `key`) con `include_video_language={idioma},en,null` → `youtube_player_flutter` |
| 12 | Reparto | movieInfo.dart | `credits.cast` (`profile_path`) |
| 13 | Recomendaciones | movieInfo.dart | `recommendations.results` |
| 14 | «Dónde ver» en la ficha | movieInfo.dart `parsePlatforms` | `watch/providers.results[region]` (`flatrate`, `free`, `ads`, `rent`, `buy`, `logo_path`); se muestra «Datos de plataformas: JustWatch» |
| 15 | Ficha de persona | [personInfo.dart:43](../lib/src/widgets/personInfo.dart) | `/person/{id}` `append_to_response=images,movie_credits,tv_credits` |
| 16 | Mesa grupal (mazo para votar) | [mesaModels.dart](../lib/src/mesa/mesaModels.dart), [mesaSetupView.dart](../lib/src/mesa/mesaSetupView.dart) | `/discover` con `with_genres`, `with_watch_providers`, `vote_average.gte`, `with_runtime.lte`, `{fecha}.gte`, `vote_count.gte=50`, páginas 1–5; + géneros y plataformas. El mazo (id, título, `poster_path`, nota, fecha) se **sincroniza en Firebase Realtime Database** |
| 17 | Mi lista | [myList.dart](../lib/src/myList.dart) | Guarda los ítems TMDB (incl. `poster_path`, `backdrop_path`) en `SharedPreferences` |
| 18 | Atribución | [app.dart:454-458](../lib/src/app.dart) | Texto «This product uses the TMDB API but is not endorsed or certified by TMDB» + JustWatch. **No muestra el logo de TMDB**, que los términos exigen |

Qué **no** hace Flixer: no reproduce contenido, no enlaza a sitios de descarga ni de streaming (no usa `url_launcher`), y la app declara que no es un servicio de streaming (`tr('notStreaming')`). Los trailers son vídeos oficiales de YouTube embebidos con el reproductor oficial. Esto es relevante para cláusulas antipiratería (§5.4).

---

## 2. Términos oficiales de cada candidata

Las citas son literales y breves. «No confirmado» = no se encontró en fuentes oficiales.

### 2.1 Trakt

Fuente vigente: la documentación nueva [developer.trakt.tv](https://developer.trakt.tv/) (la de Apiary está obsoleta).

- **Uso comercial gratis, con anuncios e IAP: CONFIRMADO.** «free or paid apps, including apps supported by advertising, subscriptions, lifetime purchases…»; «Standard API access is free for commercial and noncommercial use. Commercial status, revenue, and user numbers alone do not require Premium». Los usos permitidos «do not require individual approval… or a separate commercial agreement» — [api-use-policy](https://developer.trakt.tv/docs/api-use-policy). Los [términos generales](https://app.trakt.tv/terms) hablan de «personal, non-commercial use», pero la política aclara que esos cubren el servicio de usuario y que la API se rige por la política: **punto a validar por Legal**.
- **Cuenta de GitHub verificada y acceso de producción: CONFIRMADO.** «Creating an app requires a verified GitHub account.» Toda app nace en *Development* (el dueño + hasta 16 invitados); para publicarla hay que pedir «Request Production access» y pasar una revisión de «a few business days»; para apps que solo leen datos públicos se da acceso de producción de solo lectura. Piden descripción, enlace a la app, política de privacidad, MAU esperados y la frase de no respaldo — [create-an-app](https://developer.trakt.tv/docs/create-an-app). Las apps sin uso durante 30 días seguidos se borran (api-use-policy).
- **Atribución**: «[App name] uses Trakt but is not endorsed or certified by Trakt» en About/Ajustes **y en la ficha de la tienda**; logo opcional ([branding](https://app.trakt.tv/branding)); «no separate credit beside every item» — api-use-policy.
- **Límites**: sin autenticar, 500 llamadas GET cada 5 minutos por client ID + IP pública (es decir, por dispositivo) — [rate-limiting](https://developer.trakt.tv/docs/rate-limiting).
- **Imágenes: caché obligatoria, CONFIRMADO.** Con `?extended=full` devuelve pósters, fanart y logos (WebP). «All images are required to be cached in your app or server and not loaded directly from our CDN. Hotlinking images is not allowed and will be blocked» — [images](https://developer.trakt.tv/docs/images). Qué cuenta exactamente como «cachear en la app» (¿basta descargar una vez y guardar en disco en el dispositivo?) **no está claro**: preguntarlo en la solicitud de producción. Al terminar la integración no se pueden seguir usando metadatos ni artwork.
- **Español**: `/movies/{id}/translations/{language}` y `/shows/{id}/translations/{language}` devuelven título, tagline y sinopsis; las fichas traen `available_translations`; hay filtro `languages` — [filters](https://developer.trakt.tv/docs/filters). Requiere **una llamada extra por título**; un parámetro para traer listas ya traducidas: **no confirmado**. Variante (es-ES vs es-419) y cobertura real: **no confirmado**.
- **Cobertura**: trending, popular, búsqueda por texto y por ID, `/genres` y filtro `?genres=` en listas; `/movies/{id}/videos` (YouTube); `/movies/{id}/related` (usable como recomendaciones). `/recommendations` personalizadas exigen login OAuth. Filtros por años, duración y nota en listas: **no confirmado en esta revisión** (revisar [filters](https://developer.trakt.tv/docs/filters)).
- **«Dónde ver»: NO disponible.** Los endpoints *watchnow* y JustWatch son «Limited Access»; personal de Trakt: «JustWatch and Younify are internal only (Limited Access)» — [discussions/808](https://github.com/trakt/trakt-api/discussions/808), [limited access](https://developer.trakt.tv/docs/limted-access).
- **Piratería y datos**: «Do not use Trakt data in applications or websites that promote copyright infringement or piracy»; prohibido hacer mirror del catálogo o revender datos; caché de datos permitida («no fixed maximum cache duration»); los datos públicos no requieren login del usuario — api-use-policy.

### 2.2 TheTVDB (API v4)

- **Uso comercial gratis por ingresos**: tabla de la página de alta: «Less than $50k per year … Free - requires attribution»; 50k–250k = 1 000 USD/año; 250k–1M = 10 000 USD/año; > 1M, contactar. [thetvdb.com/api-information/signup](https://thetvdb.com/api-information/signup) (verificado directamente el 2026-11-16). «Our API is available for both commercial projects and to individual developers» — [api-information](https://thetvdb.com/api-information).
- **Anuncios / compras in-app**: la tabla se basa en ingresos del proyecto, sin distinguir modelo. Mención explícita de anuncios o IAP: **no confirmado**.
- **Contradicción a aclarar**: una FAQ antigua («Last Updated 5 years ago») dice «All API keys are required to have either a commercial license, or have subscriptions enabled for end users» — [support.thetvdb.com](https://support.thetvdb.com/kb/faq.php?id=62).
- **Cambios sin aviso**: «We reserve the right to change our interfaces, fees, or licensing terms at any point without notice» — [github.com/thetvdb/v4-api](https://github.com/thetvdb/v4-api).
- **Atribución**: «attribution with a direct link to TheTVDB.com must be displayed to end users» — [api-information](https://thetvdb.com/api-information).
- **Límites de tasa**: **no confirmado** (solo «Search is limited to 5k results max» en el swagger). Recomiendan caché: «We strongly recommend maintaining your own copy of the database or making use of a caching proxy» — [v4-api](https://github.com/thetvdb/v4-api).
- **Imágenes**: propias (pósters, fondos, artworks por URL). «We do not claim ownership of any of the images or data in the API». Reglas de hotlinking: **no confirmado**.
- **Español**: endpoints `/movies/{id}/translations/{language}` y `/series/{id}/translations/{language}`; cobertura real en español: **no confirmado** (hay que probarla con clave).
- **Cobertura**: películas y series; campo `trailers`; `/movies/filter` y `/series/filter` (género, país, idioma, orden por score/fecha/nombre); `/genres`. **Sin** endpoint de recomendaciones ni de «dónde ver» (solo compañías/networks).
- Registro: exige cuenta de TheTVDB y formulario describiendo el proyecto.

### 2.3 TVmaze

- **Licencia**: CC BY-SA. «the data can freely be used for any purpose, as long as TVmaze is properly credited as source» — [tvmaze.com/api](https://www.tvmaze.com/api). Uso comercial permitido por «any purpose» (con ShareAlike).
- **Atribución**: «linking back to TVmaze from within your application».
- **Límite**: «at least 20 calls every 10 seconds per IP address»; luego 429. Sin clave.
- **Imágenes**: «You are free to directly link ("hotlink") to our image CDN»; «Images can safely be cached indefinitely».
- **Cobertura**: **solo series** (series, temporadas, episodios, personas, programación). Sin películas, trailers, recomendaciones ni «dónde ver» por región (tiene `webChannel`/`network`, no catálogo por país).
- **Español**: los resúmenes son en inglés (comprobado en la muestra, §4); títulos locales solo vía `/shows/{id}/akas`, con cobertura pobre para hispanohablantes (§4).

### 2.4 Wikidata / Wikipedia / Wikimedia Commons

- **Datos**: «All structured data … is released into the public domain under Creative Commons Zero» — [Wikidata:Licensing](https://www.wikidata.org/wiki/Wikidata:Licensing). Sin atribución obligatoria.
- **Límites WDQS**: «One client (user agent + IP) is allowed 60 seconds of processing time each 60 seconds»; máx. 5 consultas paralelas por IP — [WDQS User Manual](https://www.mediawiki.org/wiki/Wikidata_Query_Service/User_Manual). Backend nuevo anunciado para 2026-2027.
- **User-Agent**: «Scripts should use an informative User-Agent string with contact information, or they may be blocked without notice» — [Policy:User-Agent](https://foundation.wikimedia.org/wiki/Policy:User-Agent_policy).
- **APIs REST de Wikimedia** (límites nuevos 2026, experimentales): 10 peticiones/min sin identificar; 200/min con User-Agent válido — [Wikimedia APIs/Rate limits](https://www.mediawiki.org/wiki/Wikimedia_APIs/Rate_limits). Wikimedia Enterprise gratis hasta 50 000 peticiones/mes — [enterprise.wikimedia.com](https://enterprise.wikimedia.com/).
- **Sinopsis**: Wikidata no tiene sinopsis, solo una descripción de una línea. El extracto de Wikipedia es CC BY-SA 4.0: usable «for any purpose so long as licensing terms are met» (atribución + ShareAlike) — [Reusing Wikipedia content](https://en.wikipedia.org/wiki/Wikipedia:Reusing_Wikipedia_content).
- **Imágenes**: Commons no admite «fair use» («covers, screenshots» se borran) — [Commons:Fair use](https://commons.wikimedia.org/wiki/Commons:Fair_use). Inferencia: los pósters con copyright casi nunca están en Commons; los de Wikipedia son fair use y no se pueden reutilizar libremente.
- Cubre: IDs cruzados (TMDB, IMDb, TVDB), fechas, géneros (no los de TMDB), reparto. No cubre trailers, popularidad/tendencias, notas ni «dónde ver».

### 2.5 OMDb

- **No comercial**: «All content licensed under CC BY-NC 4.0» — [omdbapi.com](https://www.omdbapi.com/); términos: «You may not build a business utilizing the Contributions, whether or not for profit» — [legal.htm](https://www.omdbapi.com/legal.htm). Que algún nivel de Patreon permita uso comercial: **no confirmado**.
- Pósters solo para mecenas de Patreon; sin parámetro de idioma (sin español); sin trailers, «dónde ver», recomendaciones ni descubrir por género. **Descartado.**

### 2.6 Otras evaluadas

| Servicio | Qué aporta | ¿Comercial gratis? | Fuente |
|---|---|---|---|
| **JustWatch** (origen de los datos «dónde ver») | Disponibilidad por país | No hay API pública; contrato de partner con token, enlaces de marca obligatorios, precio no publicado | [apis.justwatch.com/docs/api](https://apis.justwatch.com/docs/api/) |
| **Watchmode** | Disponibilidad | Plan gratis: «Non-commercial use, with attribution»; comercial desde 349 USD/mes | [api.watchmode.com](https://api.watchmode.com/) |
| **Streaming Availability (Movie of the Night)** | Disponibilidad | Sí: «all subscription plans, including the free tier, allows commercial usage», pero 1 000 peticiones/mes (insuficiente para ~1 060 MAU sin backend con caché); 49 USD/mes = 25 000 | [pricing](https://www.movieofthenight.com/about/api/pricing) |
| **KinoCheck** | Trailers oficiales | 1 000 peticiones/día gratis; uso comercial y atribución: **no confirmado** | [api.kinocheck.com](https://api.kinocheck.com/), [términos](https://www.kinocheck.com/api-terms-of-use) |
| **fanart.tv** | Solo imágenes | «Do not use our API for commercial use without written consent» (cita del buscador; el sitio devolvió 403, **verificar a mano**) | [fanart.tv/get-an-api-key](https://fanart.tv/get-an-api-key/) |
| **Simkl** | Seguimiento + metadatos | Gratis solo si la app factura < 150 USD/mes; además pide no usarla como fuente genérica («please use TVDB and TMDB») y búsqueda/géneros exigen login de usuario (AUTH V2) | [api-rules](https://api.simkl.org/api-rules), [rate limits](https://api.simkl.org/resources/rate-limits) |

### 2.7 TMDB (referencia)

- **Uso comercial**: el ingreso por publicidad cuenta como comercial y requiere «a written agreement with TMDB that expressly permits Your commercial use» — [términos §2.A](https://www.themoviedb.org/api-terms-of-use). FAQ: «considered commercial if the primary purpose is to create revenue for the benefit of the owner» — [FAQ](https://developer.themoviedb.org/docs/faq). Contacto: sales@themoviedb.org; precio no público.
- **Atribución**: «You must use the TMDB logo» (menos prominente que el de la app) + aviso de no respaldo, en «About» o «Credits». Flixer hoy solo tiene el texto (§1, fila 18).
- **JustWatch**: «you must attribute the source of the data as JustWatch» — [watch providers](https://developer.themoviedb.org/reference/movie-watch-providers). Flixer ya lo hace.
- **Límite**: «somewhere in the 40 requests per second range» — [rate limiting](https://developer.themoviedb.org/docs/rate-limiting).
- **Caché**: no más de 6 meses; purgar todo al terminar la licencia (afecta a Mi lista y a los mazos guardados en Firebase).

---

## 3. Cobertura funcional

✅ cubre · 🟡 parcial / con trabajo · ❌ no cubre · ? no confirmado

| Funcionalidad (fila del §1) | TMDB | TheTVDB | Trakt | TVmaze | Wikidata+Wikipedia |
|---|---|---|---|---|---|
| Tendencias / populares (1, 4) | ✅ | 🟡 orden por score | ✅ | 🟡 solo series | ❌ |
| En cines / próximamente / en emisión (2, 3) | ✅ por región | 🟡 filtro por fecha | 🟡 calendarios / «anticipated»; por región ? | 🟡 programación, solo series | ❌ |
| Mejor valoradas (5) | ✅ | 🟡 score | 🟡 orden por nota ? | 🟡 rating, solo series | ❌ |
| Géneros + descubrir con filtros combinados (6, 8, 16) | ✅ | 🟡 1 género por filtro; sin nota mín. ni duración ? | 🟡 filtro de géneros en listas; resto ? | ❌ | 🟡 SPARQL, lento |
| Búsqueda multi (9) | ✅ | ✅ series, películas, personas | ✅ | 🟡 series y personas | 🟡 |
| Sinopsis en español (10) | ✅ es-MX | ? traducciones | 🟡 traducciones, 1 llamada por título | ❌ inglés | 🟡 extracto Wikipedia (CC BY-SA) |
| Títulos en español | ✅ | ? | 🟡 traducciones | ❌ casi nunca | 🟡 label `es`, a menudo el original |
| Pósters / backdrops | ✅ | ✅ | 🟡 sí, pero caché obligatoria | ✅ solo series | ❌ casi sin pósters |
| Trailers YouTube (11) | ✅ | ✅ campo `trailers` | ✅ `/videos` | ❌ | ❌ |
| Reparto y persona (12, 15) | ✅ | ✅ | ✅ ? | 🟡 series | 🟡 |
| Recomendaciones (13) | ✅ | ❌ | ✅ `/related` | ❌ | ❌ |
| «Dónde ver» y filtro de plataformas por país (7, 14, 16) | ✅ (JustWatch) | ❌ | ❌ Limited Access | ❌ | ❌ |
| Uso comercial gratis con anuncios + IAP | ❌ licencia | ✅ < 50k USD/año | ✅ explícito, sin umbral | ✅ CC BY-SA | ✅ CC0 / CC BY-SA |

Conclusión del cuadro: **el «dónde ver» por país no lo cubre gratis ninguna alternativa** y es una función central (barra de plataformas, home filtrada, mesa grupal y ficha). Recomendaciones: TMDB y Trakt (`/related`). Trakt es la alternativa con más cobertura; TheTVDB, la segunda.

---

## 4. Muestra de calidad (sin clave: TVmaze y Wikidata)

Método: los 10 primeros resultados de `/movie/popular` y `/tv/popular` de TMDB (región CL, es-MX, lo que ve Flixer) el 2026-11-16; se buscó cada título en TVmaze (por ID de TVDB/IMDb) y en Wikidata (por propiedad de ID TMDB, P4947/P4983) más el resumen de es.wikipedia. Script de una sola ejecución, ~60 peticiones.

**Películas** (todas estrenos de 2026):

| Película (Flixer) | Wikidata: encontrada por ID TMDB | Título `es` en Wikidata | Imagen P18 | Año | Extracto es.wikipedia |
|---|---|---|---|---|---|
| El corazón de la bestia | sí | — | no | 2026 | vacío |
| Resident Evil: Noche cero | no¹ | — | no | — | no |
| La Odisea | sí | La Odisea | sí | 2026 | sí |
| Madre siniestra | sí | Other Mommy | no | 2026 | sí |
| Spider-Man: Un nuevo día | sí | Spider-Man: Brand New Day | no | 2026 | sí |
| Proyecto Fin del Mundo | sí | Project Hail Mary | no | 2026 | sí |
| Hope: El primer impacto | sí | Hope | sí | 2026 | sí |
| Una historia de Derry | no | — | no | — | no |
| Apocalipsis Z: Nuevo mundo | no¹ | — | no | — | no |
| No nos rendimos | no¹ | — | no | — | no |

¹ El ítem existe en Wikidata (TMDB conoce su QID) pero no tiene la propiedad de ID TMDB, así que no se encuentra por ese camino.

**Series:**

| Serie (Flixer) | TVmaze: encontrada / año / imagen | TVmaze: título | TVmaze: sinopsis | Wikidata: título `es` | Extracto es.wikipedia |
|---|---|---|---|---|---|
| La Ley y el Orden: UVE | sí / 1999 / sí | Law & Order: SVU | inglés | (inglés) | sí |
| American Horror Story | sí / 2011 / sí | igual | inglés | igual | sí |
| Doctor Who | sí / 2005 / sí | igual | inglés | — | no |
| La Oficina | sí / 2005 / sí | The Office | inglés | The Office | sí |
| Los Simpson | sí / 1989 / sí | The Simpsons | inglés | Los Simpson | sí |
| Cómo conocí a tu madre | sí / 2005 / sí | How I Met Your Mother | inglés | (inglés) | sí |
| Dr. House | sí / 2004 / sí | House | inglés | House M. D. | sí |
| El mentalista | sí / 2008 / sí | The Mentalist | inglés | El mentalista | sí |
| Una Familia Moderna | sí / 2009 / sí | Modern Family | inglés | Familia Moderna | sí |
| Flash | sí / 2014 / sí | The Flash | inglés | The Flash | sí |

Resultados:

| Métrica (20 títulos) | Flixer hoy (TMDB) | TVmaze | Wikidata + es.wikipedia |
|---|---|---|---|
| Encontrado | 20/20 | 10/10 series (0 películas: no las cubre) | 16/20 por ID TMDB |
| Sinopsis en español | 20/20 | 0/10 (todas en inglés) | 0/20 en Wikidata; 14/20 con extracto de es.wikipedia (no es una sinopsis, mezcla ficha técnica) |
| Título igual al que muestra Flixer | 20/20 | 2/10 | 4/20 |
| Póster | 20/20 | 10/10 | 0/20 pósters reales (P18 en 5/20, suelen ser fotos de rodaje o eventos) |
| Año correcto | 20/20 | 10/10 | 16/20 |

Otras observaciones: en TVmaze los títulos en español vía `/akas` son casi inexistentes (*The Simpsons* solo tiene «Los Simpson» con país ES; *House* no tiene ninguno en español). Wikidata va por detrás en estrenos: 4 de los 10 estrenos de 2026 no tienen ID TMDB enlazado o no existen.

**Lo que habría que probar con clave** (no se hizo; requiere registro del dueño):
- **TheTVDB**: las mismas 20 fichas con `/translations/spa`: ¿hay sinopsis y título en español (y de qué variante)? ¿Póster? ¿Trailers? ¿`/movies/filter` y `/series/filter` dan listas útiles como «populares»/«recientes»? Latencia y límites reales.
- **Trakt**: las mismas 20 fichas: ¿`available_translations` incluye `es` y la sinopsis traducida es latina o de España? ¿Pósters para los 10 estrenos de 2026? ¿`/related` da recomendaciones razonables? ¿Cuántas llamadas consume una home completa traduciendo títulos (límite: 500 por 5 min por dispositivo)? ¿Qué filtros admiten las listas (años, duración, nota) para la mesa grupal?

---

## 5. Recomendación y diseño

### 5.1 Recomendación

1. **Primero: pedir cotización de licencia comercial a TMDB** (sales@themoviedb.org, indicando país, ~1 060 MAU, AdMob + compra única, sin backend). Si el precio es asumible para los ingresos de Flixer, es la opción más barata en total: cero migración, cero pérdida de funciones, y solo añadir el logo de TMDB en Ajustes/Créditos. Lo decide Gestión con Finanzas; el contrato lo revisa Legal.
2. **Si no es viable: migrar a Trakt como fuente principal** detrás de `MetadataProvider`. Es la única con permiso explícito para apps con anuncios y compras únicas, sin umbral de ingresos ni contrato aparte, y cubre tendencias, populares, géneros, búsqueda, trailers, related y traducciones. Aceptar que:
   - «Dónde ver» y la barra de plataformas desaparecen (no hay disponibilidad por país en el acceso estándar). Alternativa de pago: Streaming Availability desde 49 USD/mes (requeriría backend con caché) o JustWatch con contrato.
   - Las imágenes deben pasar por una caché en disco en el dispositivo (p. ej. `cached_network_image` con caché persistente), y confirmar con Trakt que eso basta.
   - El español exige una llamada de traducción por título (más llamadas y latencia; cachear localmente).
   - «En cines / próximamente» por región se reemplaza por calendarios o «anticipated» globales.
   - **Plan C: TheTVDB** (gratis con atribución si el proyecto factura < 50 000 USD/año, previa confirmación escrita porque su FAQ antigua lo contradice; ver §2.2). No tiene recomendaciones; habría que sustituirlas por «más del mismo género».
3. **No usar** OMDb ni fanart.tv (no comerciales). **TVmaze y Wikidata solo como complemento** (p. ej. TVmaze para fechas de emisión de series), no como fuente principal: sin películas, sin español, sin pósters de película.
4. **Mientras se decide**, la app sigue en producción con TMDB sin la compra «Sin anuncios». Ojo: con los anuncios actuales ya es uso comercial según los términos de TMDB; esto conviene llevarlo a Legal cuanto antes, independientemente de la compra.

### 5.2 Interfaz propuesta

Hoy las vistas consumen `Map` crudos de TMDB (`poster_path`, `media_type`, IDs de género de TMDB). El primer paso, útil en cualquier escenario, es un modelo propio y una interfaz:

```dart
enum MediaType { movie, tv }

class Title {            // lo que hoy son los Map de TMDB
  final String id;       // "tmdb:603" / "tvdb:12345": prefijo de proveedor
  final MediaType type;
  final String name;
  final String? overview;
  final int? year;
  final double? rating;
  final String? posterUrl;   // URL completa, no path
  final String? backdropUrl;
}

class TitleDetail extends Title {
  final List<Genre> genres;
  final List<CastMember> cast;
  final Trailer? trailer;          // YouTube key, o null
  final List<WatchOption> watch;   // vacío si el proveedor no lo da
  final List<Title> related;       // recomendaciones o similares
}

class CatalogFilter {
  final MediaType type;
  final Set<String> genreIds, providerIds;
  final double? minRating;
  final int? maxRuntime, fromYear;
  final CatalogSort sort;          // popular, topRated, recent, trending
}

abstract class MetadataProvider {
  Set<Capability> get capabilities; // watchProviders, recommendations, trending...
  Future<Page<Title>> catalog(CatalogFilter filter, {int page = 1});
  Future<List<Title>> search(String query); // + Person
  Future<TitleDetail> detail(MediaType type, String id);
  Future<PersonDetail> person(String id);
  Future<List<Genre>> genres(MediaType type);
  Future<List<WatchProvider>> watchProviders(String region); // vacío si no hay
  String get attribution;           // texto/logo para Ajustes y Créditos
}
```

`capabilities` permite que la UI oculte la barra de plataformas o la fila de recomendaciones cuando el proveedor no las ofrece. `TmdbProvider` envuelve el código actual sin cambiar el comportamiento; `TraktProvider` sería la segunda implementación.

### 5.3 Qué cambia en la app y esfuerzo

| Parte | Cambio | Plan A (TMDB con licencia) | Plan B (Trakt) |
|---|---|---|---|
| `lib/src/apiFunctions/*` | `TmdbProvider` / `TraktProvider` (cabeceras `trakt-api-key`, traducciones, filtros) | 0 d | 3–4 d |
| Imágenes | Caché persistente en disco para cumplir «no hotlink» | 0 d | 1 d |
| Modelos y vistas (`homeFeed`, `exploreView`, `searchView`, `movieInfo`, `personInfo`, `posterCard`, `sectionRow`, `discoverByCategory`) | Pasar de `Map` TMDB a `Title`; URLs completas de imagen | 0 d (opcional) | 2–3 d |
| Home y géneros (`catalog.dart`) | Slugs de género de Trakt; secciones sin «en cines» por región | — | 1 d |
| Plataformas (`providerBar`, `app.dart`, ficha, mesa) | Ocultar o rediseñar | — | 1 d |
| Mesa grupal (`mesaModels.dart`) | Filtros equivalentes; mazos con IDs nuevos (mesas abiertas se rompen al actualizar) | — | 1 d |
| Mi lista | Migrar ítems guardados con IDs TMDB (Trakt permite buscar por ID externo) | — | 0,5–1 d |
| Atribución | Logo TMDB / frase de no respaldo de Trakt en Ajustes y ficha de Play | 0,5 d | 0,5 d |
| Pruebas y publicación | Pista interna con el pipeline existente | 0,5 d | 1–2 d |
| **Total** | | **≈ 1 día** | **≈ 9–13 días** (TheTVDB, plan C: similar, ≈ 8–12) |

### 5.4 Riesgos

- **Piratería**: Trakt prohíbe expresamente apps que «promote copyright infringement or piracy»; TheTVDB cumple la DMCA; KinoCheck prohíbe usos ilegales. Flixer no enlaza a descargas ni a streaming, solo muestra trailers oficiales de YouTube con el reproductor oficial y declara que no es un servicio de streaming: **bajo riesgo**, siempre que se mantenga así (no añadir enlaces externos a sitios no oficiales).
- **Términos cambiantes y aprobación**: Trakt puede rechazar o tardar en dar acceso de producción, borra apps inactivas 30 días y bloquea el hotlink de imágenes; sus términos generales dicen «non-commercial» (la política de la API dice lo contrario). TheTVDB se reserva cambiar tarifas «without notice» y su FAQ antigua contradice el tramo gratis. Pedir confirmación escrita en ambos casos.
- **Pérdida de funciones** en el plan B («dónde ver», «en cines» por región; recomendaciones solo en plan C) puede afectar a la retención de ~1 060 MAU: medir antes y después.
- **Español**: no verificado ni en Trakt ni en TheTVDB; si la cobertura es baja, la app se vería mayoritariamente en inglés para un público de Chile. Es la prueba más importante antes de decidir.
- **Datos ya almacenados**: Mi lista (local) y mazos en Firebase guardan datos de TMDB; los términos de TMDB obligan a purgarlos si se deja la API (caché ≤ 6 meses).
- **Clave en el repositorio**: la clave de TMDB está en `lib/global/constants.dart` y el repo es público. Con licencia comercial convendría rotarla y no publicarla (en una app sin backend siempre será extraíble del APK, pero no indexada en GitHub). Lo mismo para la clave de Trakt o TheTVDB.
- **Atribución actual incompleta**: falta el logo de TMDB (§1, fila 18).
- **ShareAlike**: si se usan textos de TVmaze o Wikipedia, esos textos quedan bajo CC BY-SA (atribución y misma licencia), cosa que Legal debe validar.

### 5.5 Qué tendría que hacer el dueño

1. Escribir a **sales@themoviedb.org** pidiendo cotización de licencia comercial (país, MAU, modelo AdMob + compra única) y llevar la respuesta a Gestión/Finanzas y el contrato a Legal.
2. **Trakt** (en paralelo): verificar la cuenta de GitHub, crear la app en Trakt (queda en *Development*), ejecutar la prueba de las 20 fichas del §4 y, si convence, pedir «Production access» (descripción, enlace a Play, política de privacidad, ~1 060 MAU, frase de no respaldo). En la solicitud, preguntar si la caché en disco del dispositivo cumple la regla de imágenes. Llevar a Legal la contradicción entre los términos generales y la política de la API.
3. Solo si Trakt no sirve: crear cuenta en **TheTVDB**, pedir clave en [api-information/signup](https://thetvdb.com/api-information/signup) en el tramo < 50k USD y **pedir por escrito** que confirmen que una app con anuncios + compra in-app cabe en ese tramo.
4. Decidir (Gestión) si «dónde ver» es imprescindible; si lo es y TMDB no es viable, presupuestar Streaming Availability (49 USD/mes + backend con caché) o contrato con JustWatch.
