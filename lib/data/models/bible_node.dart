import 'package:equatable/equatable.dart';
import 'node_type.dart';

/// Modelo imutável para um nó no grafo bíblico
class BibleNode extends Equatable {
  final String id;
  final String title;
  final NodeType type;
  final String? period; // Período bíblico (ex: "Patriarcas", "Reino Dividido")
  final List<String> references; // Referências bíblicas (ex: ["Gn 12:1-3", "Gl 3:8"])
  final int weight; // Peso/importância do nó (1-10)
  final String description;

  const BibleNode({
    required this.id,
    required this.title,
    required this.type,
    this.period,
    required this.references,
    required this.weight,
    required this.description,
  });

  @override
  List<Object?> get props => [id, title, type, period, references, weight, description];

  BibleNode copyWith({
    String? id,
    String? title,
    NodeType? type,
    String? period,
    List<String>? references,
    int? weight,
    String? description,
  }) {
    return BibleNode(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      period: period ?? this.period,
      references: references ?? this.references,
      weight: weight ?? this.weight,
      description: description ?? this.description,
    );
  }
}
