import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/bible_node.dart';
import '../../data/models/node_connection.dart';
import '../../data/models/node_type.dart';
import '../../data/repositories/connections_repository.dart';

/// Provider para o repositório de conexões
final connectionsRepositoryProvider = Provider<ConnectionsRepository>((ref) {
  return MockConnectionsRepository();
});

/// Estado imutável do grafo de conexões
class ConnectionsState {
  final List<BibleNode> allNodes;
  final List<NodeConnection> allConnections;
  final List<String> availablePeriods;
  
  // Estado de seleção e filtros
  final String? selectedNodeId;
  final Set<NodeType> hiddenNodeTypes;
  final Set<String> hiddenPeriods;
  final Set<String> favoriteNodeIds;
  
  // Estados de UI
  final bool isLoading;
  final String? errorMessage;

  ConnectionsState({
    required this.allNodes,
    required this.allConnections,
    required this.availablePeriods,
    this.selectedNodeId,
    this.hiddenNodeTypes = const {},
    this.hiddenPeriods = const {},
    this.favoriteNodeIds = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  /// Estado inicial com listas vazias
  factory ConnectionsState.initial() {
    return ConnectionsState(
      allNodes: const [],
      allConnections: const [],
      availablePeriods: const [],
      isLoading: true,
    );
  }

  /// Nós filtrados por tipo e período — calculado uma vez por instância de estado.
  late final List<BibleNode> filteredNodes = allNodes.where((node) {
    if (hiddenNodeTypes.contains(node.type)) return false;
    if (node.period != null && hiddenPeriods.contains(node.period)) return false;
    return true;
  }).toList();

  /// Retorna as conexões que devem ser destacadas (do nó selecionado)
  List<NodeConnection> get highlightedConnections {
    if (selectedNodeId == null) return [];
    
    return allConnections.where((conn) {
      return conn.sourceId == selectedNodeId || conn.targetId == selectedNodeId;
    }).toList();
  }

  /// Retorna nós conectados ao nó selecionado
  Set<String> get connectedNodeIds {
    if (selectedNodeId == null) return {};
    
    return highlightedConnections.map((conn) {
      return conn.sourceId == selectedNodeId ? conn.targetId : conn.sourceId;
    }).toSet();
  }

  /// Retorna o nó selecionado
  BibleNode? get selectedNode {
    if (selectedNodeId == null) return null;
    try {
      return allNodes.firstWhere((node) => node.id == selectedNodeId);
    } catch (e) {
      return null;
    }
  }

  /// Cria uma cópia com campos modificados
  ConnectionsState copyWith({
    List<BibleNode>? allNodes,
    List<NodeConnection>? allConnections,
    List<String>? availablePeriods,
    String? selectedNodeId,
    bool clearSelection = false,
    Set<NodeType>? hiddenNodeTypes,
    Set<String>? hiddenPeriods,
    Set<String>? favoriteNodeIds,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ConnectionsState(
      allNodes: allNodes ?? this.allNodes,
      allConnections: allConnections ?? this.allConnections,
      availablePeriods: availablePeriods ?? this.availablePeriods,
      selectedNodeId: clearSelection ? null : (selectedNodeId ?? this.selectedNodeId),
      hiddenNodeTypes: hiddenNodeTypes ?? this.hiddenNodeTypes,
      hiddenPeriods: hiddenPeriods ?? this.hiddenPeriods,
      favoriteNodeIds: favoriteNodeIds ?? this.favoriteNodeIds,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// StateNotifier para gerenciar o estado das conexões
class ConnectionsNotifier extends StateNotifier<ConnectionsState> {
  final ConnectionsRepository _repository;

  ConnectionsNotifier(this._repository) : super(ConnectionsState.initial()) {
    loadData();
  }

  /// Carrega os dados iniciais do repositório
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final nodes = await _repository.getNodes();
      final connections = await _repository.getConnections();
      final periods = await _repository.getAvailablePeriods();
      
      state = ConnectionsState(
        allNodes: nodes,
        allConnections: connections,
        availablePeriods: periods,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar dados: $e',
      );
    }
  }

  /// Seleciona um nó (ou limpa seleção se já estiver selecionado)
  void selectNode(String? nodeId) {
    if (state.selectedNodeId == nodeId) {
      // Se clicar no mesmo nó, remove seleção
      state = state.copyWith(clearSelection: true);
    } else {
      state = state.copyWith(selectedNodeId: nodeId);
    }
  }

  /// Limpa a seleção atual
  void clearSelection() {
    state = state.copyWith(clearSelection: true);
  }

  /// Alterna a visibilidade de um tipo de nó
  void toggleNodeTypeFilter(NodeType type) {
    final newHidden = Set<NodeType>.from(state.hiddenNodeTypes);
    if (newHidden.contains(type)) {
      newHidden.remove(type);
    } else {
      newHidden.add(type);
    }
    state = state.copyWith(hiddenNodeTypes: newHidden);
  }

  /// Alterna a visibilidade de um período
  void togglePeriodFilter(String period) {
    final newHidden = Set<String>.from(state.hiddenPeriods);
    if (newHidden.contains(period)) {
      newHidden.remove(period);
    } else {
      newHidden.add(period);
    }
    state = state.copyWith(hiddenPeriods: newHidden);
  }

  /// Limpa todos os filtros
  void clearFilters() {
    state = state.copyWith(
      hiddenNodeTypes: {},
      hiddenPeriods: {},
    );
  }

  /// Alterna favorito em um nó
  void toggleFavorite(String nodeId) {
    final newFavorites = Set<String>.from(state.favoriteNodeIds);
    if (newFavorites.contains(nodeId)) {
      newFavorites.remove(nodeId);
    } else {
      newFavorites.add(nodeId);
    }
    state = state.copyWith(favoriteNodeIds: newFavorites);
  }

  /// Verifica se um nó é favorito
  bool isFavorite(String nodeId) {
    return state.favoriteNodeIds.contains(nodeId);
  }
}

/// Provider principal do estado de conexões
final connectionsProvider = StateNotifierProvider<ConnectionsNotifier, ConnectionsState>((ref) {
  final repository = ref.watch(connectionsRepositoryProvider);
  return ConnectionsNotifier(repository);
});
