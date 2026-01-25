import '../models/bible_node.dart';
import '../models/node_connection.dart';
import '../mock/biblical_connections_mock.dart';

/// Repositório para acessar dados do grafo de conexões bíblicas
abstract class ConnectionsRepository {
  /// Retorna todos os nós do grafo
  Future<List<BibleNode>> getNodes();

  /// Retorna todas as conexões entre nós
  Future<List<NodeConnection>> getConnections();

  /// Retorna as conexões relacionadas a um nó específico
  Future<List<NodeConnection>> getConnectionsForNode(String nodeId);

  /// Retorna os períodos bíblicos disponíveis
  Future<List<String>> getAvailablePeriods();
}

/// Implementação mocada do repositório usando dados locais
class MockConnectionsRepository implements ConnectionsRepository {
  @override
  Future<List<BibleNode>> getNodes() async {
    // Simula delay de rede
    await Future.delayed(const Duration(milliseconds: 300));
    return BiblicalConnectionsMock.getAllNodes();
  }

  @override
  Future<List<NodeConnection>> getConnections() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return BiblicalConnectionsMock.getAllConnections();
  }

  @override
  Future<List<NodeConnection>> getConnectionsForNode(String nodeId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return BiblicalConnectionsMock.getConnectionsForNode(nodeId);
  }

  @override
  Future<List<String>> getAvailablePeriods() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return BiblicalConnectionsMock.getAvailablePeriods();
  }
}
