import 'local_bible_loader.dart';

class BibleSearchResult {
  final String book;
  final int chapter;
  final int verse;
  final String text;

  const BibleSearchResult({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  String get reference => '$book $chapter:$verse';
}

/// Pesquisa em todos os versículos da Bíblia, em memória, sobre o JSON local.
/// Reutiliza um cache estático por versão para evitar releitura do disco.
class BibleSearchService {
  static List<dynamic>? _cached;
  static String? _cachedVersion;

  static Future<void> ensureLoaded(String version) async {
    if (_cachedVersion == version && _cached != null) return;
    _cached = await LocalBibleLoader.load(version);
    _cachedVersion = version;
  }

  // Mapa de diacríticos → ascii (PT) para pesquisa tolerante a acentos.
  static const Map<String, String> _diacritics = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', 'ñ': 'n',
  };

  static String _normalize(String input) {
    final lower = input.toLowerCase();
    final buf = StringBuffer();
    for (var i = 0; i < lower.length; i++) {
      final ch = lower[i];
      buf.write(_diacritics[ch] ?? ch);
    }
    return buf.toString();
  }

  /// Pesquisa por correspondência de substring normalizada (sem acentos, case-insensitive).
  /// Retorna no máximo [limit] resultados, percorrendo a Bíblia em ordem canónica.
  static List<BibleSearchResult> search(String query, {int limit = 200}) {
    if (_cached == null) return const [];
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];

    final needle = _normalize(trimmed);
    final results = <BibleSearchResult>[];

    for (final book in _cached!) {
      final bookName = book['name'].toString();
      final chapters = book['chapters'] as List;
      for (var c = 0; c < chapters.length; c++) {
        final verses = chapters[c] as List;
        for (var v = 0; v < verses.length; v++) {
          final text = verses[v].toString();
          if (_normalize(text).contains(needle)) {
            results.add(BibleSearchResult(
              book: bookName,
              chapter: c + 1,
              verse: v + 1,
              text: text,
            ));
            if (results.length >= limit) return results;
          }
        }
      }
    }
    return results;
  }
}
