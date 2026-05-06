import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/user_data_model.dart';

/// Converte anotações (formato Quill delta JSON ou texto simples) para texto
/// legível e partilha via share sheet nativo — zero dependências novas.
class NoteExportService {
  NoteExportService._();

  // ---------------------------------------------------------------------------
  // API pública
  // ---------------------------------------------------------------------------

  /// Partilha uma única nota como texto formatado.
  static Future<void> exportNote(UserNote note) async {
    final text = _buildSingleNoteText(note);
    await Share.share(text, subject: _noteSubject(note));
  }

  /// Partilha todas as notas como um ficheiro .txt.
  static Future<void> exportAllNotes(List<UserNote> notes) async {
    if (notes.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln('BeLight Bible — As Minhas Anotações');
    buffer.writeln('Exportado em ${_formatDate(DateTime.now())}');
    buffer.writeln('=' * 48);
    buffer.writeln();

    for (final note in notes) {
      buffer.write(_buildSingleNoteText(note));
      buffer.writeln();
      buffer.writeln('-' * 40);
      buffer.writeln();
    }

    final text = buffer.toString();

    try {
      // Guardar num ficheiro temporário para partilhar como anexo
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/belight_notes.txt');
      await file.writeAsString(text, flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/plain')],
        subject: 'As Minhas Anotações Bíblicas',
      );
    } catch (e) {
      // Fallback: partilhar como texto simples se o ficheiro falhar
      debugPrint('NoteExportService: fallback to text share — $e');
      await Share.share(text, subject: 'As Minhas Anotações Bíblicas');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers privados
  // ---------------------------------------------------------------------------

  static String _buildSingleNoteText(UserNote note) {
    final buffer = StringBuffer();

    // Referência bíblica
    buffer.writeln('📖 ${note.book} ${note.chapter}:${note.verse}');

    // Título (se existir)
    if (note.title != null && note.title!.isNotEmpty) {
      buffer.writeln('📝 ${note.title}');
    }

    buffer.writeln();

    // Conteúdo: tentar parsear delta Quill → texto puro
    buffer.writeln(_deltaToPlainText(note.content));

    // Data
    final dateStr = _formatDate(note.updatedAt ?? note.createdAt);
    if (dateStr.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('— Editado em $dateStr');
    }

    return buffer.toString().trim();
  }

  /// Converte delta Quill (JSON) em texto puro sem formatação.
  static String _deltaToPlainText(String content) {
    if (content.isEmpty) return '';

    try {
      final trimmed = content.trim();
      if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
        final dynamic decoded = jsonDecode(content);

        // Delta é uma List de ops
        if (decoded is List) {
          final sb = StringBuffer();
          for (final op in decoded) {
            if (op is Map && op['insert'] is String) {
              sb.write(op['insert'] as String);
            }
          }
          final result = sb.toString();
          // Remove trailing newline que o Quill adiciona automaticamente
          return result.endsWith('\n')
              ? result.substring(0, result.length - 1)
              : result;
        }
      }
    } catch (_) {
      // Conteúdo não é JSON válido — tratar como texto simples
    }

    return content;
  }

  static String _noteSubject(UserNote note) {
    if (note.title != null && note.title!.isNotEmpty) return note.title!;
    return 'Nota — ${note.book} ${note.chapter}:${note.verse}';
  }

  static String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }
}
