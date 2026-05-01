import 'package:flutter/foundation.dart';

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

/// Entrada do índice. Mantém apenas índices numéricos do livro;
/// o nome é resolvido via [_bookNames] na construção do resultado.
class _IndexEntry {
  final int bookIdx;
  final int chapter;
  final int verse;
  final String original;
  final String normalized;

  const _IndexEntry({
    required this.bookIdx,
    required this.chapter,
    required this.verse,
    required this.original,
    required this.normalized,
  });
}

class _IndexBundle {
  final List<_IndexEntry> entries;
  final List<String> bookNames;
  const _IndexBundle(this.entries, this.bookNames);
}

/// Pesquisa em todos os versículos da Bíblia.
///
/// O custo está no índice normalizado, construído uma única vez por versão
/// dentro de um isolate via [compute] — depois cada pesquisa é apenas um
/// loop de [String.contains] sobre strings já normalizadas.
class BibleSearchService {
  static _IndexBundle? _bundle;
  static String? _cachedVersion;
  static Future<_IndexBundle>? _inflight;

  /// Garante que o índice está construído para a versão pedida.
  /// Chamadas concorrentes partilham o mesmo Future.
  static Future<void> ensureLoaded(String version) async {
    if (_cachedVersion == version && _bundle != null) return;

    if (_inflight != null && _cachedVersion == version) {
      await _inflight;
      return;
    }

    _cachedVersion = version;
    final raw = await LocalBibleLoader.load(version);
    _inflight = compute(_buildIndex, raw);
    try {
      _bundle = await _inflight;
    } finally {
      _inflight = null;
    }
  }

  /// Pesquisa por correspondência de substring normalizada (sem acentos,
  /// case-insensitive). Síncrona — opera sobre strings já normalizadas.
  static List<BibleSearchResult> search(String query, {int limit = 200}) {
    final bundle = _bundle;
    if (bundle == null) return const [];
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];

    final needle = _normalize(trimmed);
    final results = <BibleSearchResult>[];

    for (final entry in bundle.entries) {
      if (entry.normalized.contains(needle)) {
        results.add(BibleSearchResult(
          book: bundle.bookNames[entry.bookIdx],
          chapter: entry.chapter,
          verse: entry.verse,
          text: entry.original,
        ));
        if (results.length >= limit) return results;
      }
    }
    return results;
  }
}

// Mapa de diacríticos → ascii (PT) para pesquisa tolerante a acentos.
const Map<String, String> _diacritics = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c', 'ñ': 'n',
};

String _normalize(String input) {
  final lower = input.toLowerCase();
  final buf = StringBuffer();
  for (var i = 0; i < lower.length; i++) {
    final ch = lower[i];
    buf.write(_diacritics[ch] ?? ch);
  }
  return buf.toString();
}

/// Constrói o índice plano. Top-level para poder correr em isolate via [compute].
_IndexBundle _buildIndex(List<dynamic> raw) {
  final entries = <_IndexEntry>[];
  final names = <String>[];
  for (var b = 0; b < raw.length; b++) {
    final book = raw[b];
    names.add(book['name'].toString());
    final chapters = book['chapters'] as List;
    for (var c = 0; c < chapters.length; c++) {
      final verses = chapters[c] as List;
      for (var v = 0; v < verses.length; v++) {
        final text = verses[v].toString();
        entries.add(_IndexEntry(
          bookIdx: b,
          chapter: c + 1,
          verse: v + 1,
          original: text,
          normalized: _normalize(text),
        ));
      }
    }
  }
  return _IndexBundle(entries, names);
}
