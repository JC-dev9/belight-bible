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

/// Repositório local com dados bíblicos embarcados na app
class LocalConnectionsRepository implements ConnectionsRepository {
  @override
  Future<List<BibleNode>> getNodes() async {
    return BiblicalConnectionsMock.getAllNodes();
  }

  @override
  Future<List<NodeConnection>> getConnections() async {
    return BiblicalConnectionsMock.getAllConnections();
  }

  @override
  Future<List<NodeConnection>> getConnectionsForNode(String nodeId) async {
    return BiblicalConnectionsMock.getConnectionsForNode(nodeId);
  }

  @override
  Future<List<String>> getAvailablePeriods() async {
    return BiblicalConnectionsMock.getAvailablePeriods();
  }
}
