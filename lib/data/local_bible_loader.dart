import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class LocalBibleLoader {
  // Cache LRU de Bíblias já descodificadas. Trocar entre versões já visitadas
  // passa a ser O(1) sem I/O nem decode. Mantemos no máximo [_maxCached]
  // versões para limitar uso de RAM (~4MB JSON descodificado por versão).
  static const int _maxCached = 3;
  static final LinkedHashMap<String, List<dynamic>> _cache =
      LinkedHashMap<String, List<dynamic>>();

  // Loads em curso por versão — evita decodes paralelos da mesma Bíblia
  // se [load] for chamado várias vezes em rápida sucessão.
  static final Map<String, Future<List<dynamic>>> _inflight = {};

  /// Indica se a versão indicada já está em memória (lookup síncrono).
  static bool isCached(String version) =>
      _cache.containsKey(version.toLowerCase());

  /// Carrega a Bíblia: hit no cache devolve imediatamente; miss lê do disco
  /// (ou do bundle) e descodifica num isolate via [compute].
  static Future<List<dynamic>> load(String version) {
    final key = version.toLowerCase();

    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached; // re-insere no fim (LRU)
      return Future.value(cached);
    }

    final pending = _inflight[key];
    if (pending != null) return pending;

    final future = _loadFromSource(key).whenComplete(() {
      _inflight.remove(key);
    });
    _inflight[key] = future;
    return future;
  }

  /// Pré-aquece o cache em background sem bloquear o caller.
  /// Usado para que a próxima troca para uma versão já transferida seja instantânea.
  static void prefetch(String version) {
    final key = version.toLowerCase();
    if (_cache.containsKey(key) || _inflight.containsKey(key)) return;
    // ignore: unawaited_futures
    load(key);
  }

  static Future<List<dynamic>> _loadFromSource(String key) async {
    final raw = await _readRaw(key);
    final decoded = await compute(_decode, raw);
    _store(key, decoded);
    return decoded;
  }

  static Future<String> _readRaw(String key) async {
    // 1. Tentar do armazenamento interno (versões transferidas).
    try {
      final directory = await getApplicationDocumentsDirectory();
      final candidates = [
        File('${directory.path}/$key.json'),
        File('${directory.path}/${key.toUpperCase()}.json'),
      ];
      for (final file in candidates) {
        if (await file.exists()) {
          final jsonString = await file.readAsString();
          if (jsonString.trim().isNotEmpty) return jsonString;
        }
      }
    } catch (e) {
      debugPrint('Erro ao ler arquivo local (ignorando): $e');
    }

    // 2. Fallback: assets do bundle.
    try {
      return await rootBundle.loadString('assets/bible/$key.json');
    } catch (e) {
      debugPrint('Erro fatal: nem disco nem asset: $e');
      throw Exception('Ficheiro da Bíblia não encontrado: $key');
    }
  }

  static List<dynamic> _decode(String raw) =>
      jsonDecode(raw) as List<dynamic>;

  static void _store(String key, List<dynamic> data) {
    _cache.remove(key);
    _cache[key] = data;
    while (_cache.length > _maxCached) {
      _cache.remove(_cache.keys.first);
    }
  }

  /// Liberta a versão do cache (ex: depois de a apagar do disco).
  static void evict(String version) {
    _cache.remove(version.toLowerCase());
  }
}
