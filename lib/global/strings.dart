import 'package:flixer/global/variables.dart';

const Map<String, Map<String, String>> _strings = {
  'movies': {'es': 'Películas', 'en': 'Movies'},
  'series': {'es': 'Series', 'en': 'Series'},
  'all': {'es': 'Todo', 'en': 'All'},
  'people': {'es': 'Personas', 'en': 'People'},
  'search': {'es': 'Buscar...', 'en': 'Search...'},
  'searchHint': {'es': 'Escribe algo para buscar', 'en': 'Type something to search'},
  'noResults': {'es': 'No encontramos nada', 'en': 'Nothing seems to match'},
  'knownFor': {'es': 'Conocido por ', 'en': 'Known for '},
  'and': {'es': ' y ', 'en': ' and '},
  'nothingYet': {'es': 'nada todavía', 'en': 'nothing yet'},
  'language': {'es': 'Idioma', 'en': 'Language'},
  'region': {'es': 'Región', 'en': 'Region'},
  'theme': {'es': 'Tema', 'en': 'Theme'},
  'dark': {'es': 'Oscuro', 'en': 'Dark'},
  'light': {'es': 'Claro', 'en': 'Light'},
  'whereToWatch': {'es': 'Dónde ver', 'en': 'Where to watch'},
  'noPlatforms': {
    'es': 'No está en plataformas de tu región',
    'en': 'Not available on platforms in your region'
  },
  'flatrate': {'es': 'Streaming', 'en': 'Stream'},
  'free': {'es': 'Gratis', 'en': 'Free'},
  'ads': {'es': 'Con anuncios', 'en': 'With ads'},
  'rent': {'es': 'Arriendo', 'en': 'Rent'},
  'buy': {'es': 'Compra', 'en': 'Buy'},
  'justWatch': {'es': 'Datos de plataformas: JustWatch', 'en': 'Streaming data: JustWatch'},
  'cast': {'es': 'Reparto', 'en': 'Cast'},
  'as': {'es': ' como', 'en': ' as'},
  'related': {'es': 'Similares', 'en': 'Related'},
  'pictures': {'es': 'Fotos', 'en': 'Pictures'},
  'noOverview': {'es': 'Sin sinopsis disponible.', 'en': 'No overview available.'},
  'errorTitle': {'es': 'No pudimos cargar el contenido', 'en': "We couldn't load this"},
  'errorBody': {
    'es': 'Revisa tu conexión e inténtalo de nuevo.',
    'en': 'Check your connection and try again.'
  },
  'retry': {'es': 'Reintentar', 'en': 'Try again'},
  'empty': {'es': 'No hay nada por aquí', 'en': 'Nothing here yet'},
  'back': {'es': 'Volver', 'en': 'Back'},
  'home': {'es': 'Inicio', 'en': 'Home'},
  'mute': {'es': 'Silenciar tráiler', 'en': 'Mute trailer'},
  'unmute': {'es': 'Activar sonido del tráiler', 'en': 'Unmute trailer'},
  'about': {'es': 'Datos', 'en': 'Data'},
};

/// UI text in the user's language, falling back to English.
String tr(String key) =>
    _strings[key]?[language] ?? _strings[key]?['en'] ?? key;
