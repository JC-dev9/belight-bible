import 'package:equatable/equatable.dart';
import 'connection_type.dart';

/// Modelo imutável para uma conexão entre nós no grafo bíblico
class NodeConnection extends Equatable {
  final String id;
  final String sourceId; // ID do nó de origem
  final String targetId; // ID do nó de destino
  final ConnectionType type;
  final String description;
  final List<String>? supportingVerses; // Versículos que apoiam esta conexão

  const NodeConnection({
    required this.id,
    required this.sourceId,
    required this.targetId,
    required this.type,
    required this.description,
    this.supportingVerses,
  });

  @override
  List<Object?> get props => [id, sourceId, targetId, type, description, supportingVerses];

  NodeConnection copyWith({
    String? id,
    String? sourceId,
    String? targetId,
    ConnectionType? type,
    String? description,
    List<String>? supportingVerses,
  }) {
    return NodeConnection(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
      type: type ?? this.type,
      description: description ?? this.description,
      supportingVerses: supportingVerses ?? this.supportingVerses,
    );
  }
}
