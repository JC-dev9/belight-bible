import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class LocalBibleLoader {
  static Future<List<dynamic>> load(String version) async {
    // 1. TENTATIVA: Ler do armazenamento interno (caso tenha sido baixado)
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$version.json');

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        // Verifica se o arquivo não está vazio antes de tentar decodificar
        if (jsonString.trim().isNotEmpty) {
          return jsonDecode(jsonString);
        }
      }
    } catch (e) {
      // Se der qualquer erro ao ler o arquivo do disco (corrompido, etc),
      // nós apenas ignoramos e deixamos o código seguir para o Asset.
      debugPrint("Erro ao ler arquivo local (ignorando): $e");
    }

    // 2. TENTATIVA (SEGURANÇA): Carregar dos Assets originais
    try {
      final assetPath = 'assets/bible/${version.toLowerCase()}.json';
      final jsonString = await rootBundle.loadString(assetPath);
      return jsonDecode(jsonString);
    } catch (e) {
      debugPrint("Erro fatal: Não encontrou nem no disco nem no asset: $e");
      throw Exception("Ficheiro da Bíblia não encontrado: $version");
    }
  }
}
