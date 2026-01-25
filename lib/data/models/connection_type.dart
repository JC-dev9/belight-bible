import 'package:flutter/material.dart';

/// Tipos de conexões entre nós no grafo bíblico
enum ConnectionType {
  promise,      // Promessa (ex: Abraão recebe promessa)
  fulfillment,  // Cumprimento (ex: Jesus cumpre profecia)
  contrast,     // Contraste (ex: Adão vs Cristo)
  typology,     // Tipologia (ex: Êxodo prefigura Redenção)
  parallel,     // Paralelo (ex: eventos semelhantes)
  causation,    // Causalidade (ex: pecado causa morte)
}

extension ConnectionTypeExtension on ConnectionType {
  /// Nome de exibição do tipo de conexão
  String get displayName {
    switch (this) {
      case ConnectionType.promise:
        return 'Promessa';
      case ConnectionType.fulfillment:
        return 'Cumprimento';
      case ConnectionType.contrast:
        return 'Contraste';
      case ConnectionType.typology:
        return 'Tipologia';
      case ConnectionType.parallel:
        return 'Paralelo';
      case ConnectionType.causation:
        return 'Causalidade';
    }
  }

  /// Descrição do tipo de conexão
  String get description {
    switch (this) {
      case ConnectionType.promise:
        return 'Uma promessa feita que será cumprida';
      case ConnectionType.fulfillment:
        return 'Cumprimento de uma promessa ou profecia';
      case ConnectionType.contrast:
        return 'Contraste ou oposição entre conceitos';
      case ConnectionType.typology:
        return 'Símbolo ou prefiguração de algo futuro';
      case ConnectionType.parallel:
        return 'Eventos ou conceitos paralelos';
      case ConnectionType.causation:
        return 'Relação de causa e efeito';
    }
  }

  /// Cor da linha de conexão
  Color get color {
    switch (this) {
      case ConnectionType.promise:
        return const Color(0xFF3B82F6); // Azul
      case ConnectionType.fulfillment:
        return const Color(0xFF10B981); // Verde
      case ConnectionType.contrast:
        return const Color(0xFFEF4444); // Vermelho
      case ConnectionType.typology:
        return const Color(0xFF8B5CF6); // Roxo
      case ConnectionType.parallel:
        return const Color(0xFF6366F1); // Índigo
      case ConnectionType.causation:
        return const Color(0xFFF59E0B); // Âmbar
    }
  }

  /// Estilo de linha (sólida, tracejada, pontilhada)
  LineStyle get lineStyle {
    switch (this) {
      case ConnectionType.promise:
      case ConnectionType.fulfillment:
      case ConnectionType.causation:
        return LineStyle.solid;
      case ConnectionType.contrast:
        return LineStyle.dashed;
      case ConnectionType.typology:
      case ConnectionType.parallel:
        return LineStyle.dotted;
    }
  }

  /// Se a linha deve ter seta
  bool get hasArrow {
    switch (this) {
      case ConnectionType.promise:
      case ConnectionType.fulfillment:
      case ConnectionType.causation:
        return true;
      case ConnectionType.contrast:
      case ConnectionType.typology:
      case ConnectionType.parallel:
        return false;
    }
  }
}

/// Estilos de linha para conexões
enum LineStyle {
  solid,   // Linha sólida
  dashed,  // Linha tracejada
  dotted,  // Linha pontilhada
}
