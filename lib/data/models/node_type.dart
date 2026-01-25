import 'package:flutter/material.dart';

/// Tipos de nós no grafo bíblico
enum NodeType {
  theme,      // Temas (ex: Fé, Redenção, Obediência)
  character,  // Personagens (ex: Abraão, Moisés, Paulo)
  event,      // Eventos (ex: Êxodo, Crucificação, Pentecostes)
  place,      // Lugares (ex: Jerusalém, Babilônia, Éden)
  doctrine,   // Doutrinas (ex: Justificação pela Fé, Ressurreição)
}

extension NodeTypeExtension on NodeType {
  /// Nome de exibição do tipo de nó
  String get displayName {
    switch (this) {
      case NodeType.theme:
        return 'Tema';
      case NodeType.character:
        return 'Personagem';
      case NodeType.event:
        return 'Evento';
      case NodeType.place:
        return 'Lugar';
      case NodeType.doctrine:
        return 'Doutrina';
    }
  }

  /// Cor associada ao tipo de nó
  Color get color {
    switch (this) {
      case NodeType.theme:
        return const Color(0xFF6366F1); // Índigo - Temas abstratos
      case NodeType.character:
        return const Color(0xFFEC4899); // Rosa - Personagens
      case NodeType.event:
        return const Color(0xFFF59E0B); // Âmbar - Eventos históricos
      case NodeType.place:
        return const Color(0xFF10B981); // Verde - Lugares geográficos
      case NodeType.doctrine:
        return const Color(0xFF8B5CF6); // Roxo - Doutrinas teológicas
    }
  }

  /// Ícone representando o tipo de nó
  IconData get icon {
    switch (this) {
      case NodeType.theme:
        return Icons.lightbulb_outline;
      case NodeType.character:
        return Icons.person_outline;
      case NodeType.event:
        return Icons.event_note_outlined;
      case NodeType.place:
        return Icons.place_outlined;
      case NodeType.doctrine:
        return Icons.school_outlined;
    }
  }
}
