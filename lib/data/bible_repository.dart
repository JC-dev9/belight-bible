import 'package:dio/dio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'local_bible_loader.dart';

class BibleRepository {
  String version;
  List<dynamic>? _cachedBible;

  BibleRepository({required this.version});

  // Versões disponíveis localmente em assets/bible/
  static const Map<String, String> availableVersions = {
    'ACF': 'Almeida Corrigida Fiel',
    'ARC': 'Almeida Revista e Corrigida',
    'NTLH': 'Nova Tradução na Linguagem de Hoje',
  };

  /// Carrega a Bíblia localmente
  Future<void> ensureLoaded() async {
    _cachedBible = await LocalBibleLoader.load(version);
  }

  /// Lista de versões baixadas localmente
  static Future<List<String>> getDownloadedVersions() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync();
    return files
        .where((f) => f.path.endsWith('.json'))
        .map((f) => f.path.split('/').last.replaceAll('.json', ''))
        .toList();
  }

  /// Faz download de uma nova versão
  Future<void> downloadNewVersion(
      String verCode, Function(double) onProgress) async {
    final dio = Dio();
    final directory = await getApplicationDocumentsDirectory();
    final savePath = '${directory.path}/$verCode.json';

    // URL Raw do GitHub
    final url =
        'https://raw.githubusercontent.com/damarals/biblias/main/inst/json/${verCode.toUpperCase()}.json';

    await dio.download(
      url,
      savePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          onProgress(received / total);
        }
      },
    );
  }

  /// Lista de livros da Bíblia
  List<String> get allBooks {
    if (_cachedBible == null) return [];
    return _cachedBible!.map((book) => book['name'].toString()).toList();
  }

  /// Mapeamento livro -> número de capítulos
  Map<String, int> get chaptersPerBook {
    if (_cachedBible == null) return {};
    return {
      for (var book in _cachedBible!)
        book['name'].toString(): (book['chapters'] as List).length
    };
  }

  /// Retorna um capítulo específico
  Future<List<Map<String, dynamic>>> getChapter(
      String bookName, int chapter) async {
    await ensureLoaded();
    final bookData = _cachedBible?.firstWhere(
      (b) => b['name'] == bookName,
      orElse: () => null,
    );
    if (bookData == null) return [];
    final List<dynamic> allChapters = bookData['chapters'];
    if (chapter < 1 || chapter > allChapters.length) return [];
    final List<dynamic> versesList = allChapters[chapter - 1];

    return versesList.asMap().entries.map<Map<String, dynamic>>((e) {
      return {
        'number': e.key + 1,
        'text': e.value.toString(),
        'highlighted': null,
        'note': '',
      };
    }).toList();
  }

  /// Retorna a quantidade de versículos de um capítulo
  Future<int> getVerseCount(String bookName, int chapter) async {
    await ensureLoaded();
    final bookData = _cachedBible?.firstWhere(
      (b) => b['name'] == bookName,
      orElse: () => null,
    );
    if (bookData == null) return 0;
    final List<dynamic> allChapters = bookData['chapters'];
    if (chapter < 1 || chapter > allChapters.length) return 0;
    final List<dynamic> versesList = allChapters[chapter - 1];
    return versesList.length;
  }
}

