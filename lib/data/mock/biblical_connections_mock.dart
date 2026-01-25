import '../models/bible_node.dart';
import '../models/node_connection.dart';
import '../models/node_type.dart';
import '../models/connection_type.dart';

/// Dados mocados para o grafo bíblico com conexões semânticas ricas
class BiblicalConnectionsMock {
  // =================== NÓS ===================
  
  static final List<BibleNode> nodes = [
    // PERSONAGENS
    const BibleNode(
      id: 'abraao',
      title: 'Abraão',
      type: NodeType.character,
      period: 'Patriarcas',
      references: ['Gn 12:1-3', 'Gn 15:6', 'Rm 4:3', 'Gl 3:6-9'],
      weight: 10,
      description: 'Pai da fé e patriarca do povo de Israel. Deus fez uma aliança com ele, prometendo descendência numerosa e bênção para todas as nações.',
    ),
    const BibleNode(
      id: 'isaque',
      title: 'Isaque',
      type: NodeType.character,
      period: 'Patriarcas',
      references: ['Gn 21:1-7', 'Gn 22:1-19', 'Hb 11:17-19'],
      weight: 7,
      description: 'Filho da promessa, nascido de Abraão e Sara na velhice. Sua vida ilustra a fidelidade de Deus em cumprir suas promessas.',
    ),
    const BibleNode(
      id: 'moises',
      title: 'Moisés',
      type: NodeType.character,
      period: 'Êxodo',
      references: ['Êx 3:1-15', 'Êx 14:21-31', 'Dt 34:10-12'],
      weight: 10,
      description: 'Libertador de Israel do Egito, mediador da Lei e profeta incomparável. Conduziu o povo através do Mar Vermelho.',
    ),
    const BibleNode(
      id: 'davi',
      title: 'Davi',
      type: NodeType.character,
      period: 'Monarquia',
      references: ['1Sm 16:1-13', '2Sm 7:12-16', 'Sl 89:3-4'],
      weight: 9,
      description: 'Rei segundo o coração de Deus, da linhagem do qual viria o Messias. Autor de muitos salmos.',
    ),
    const BibleNode(
      id: 'jesus',
      title: 'Jesus Cristo',
      type: NodeType.character,
      period: 'Novo Testamento',
      references: ['Mt 1:1', 'Jo 1:1-14', 'Fp 2:5-11', 'Ap 19:16'],
      weight: 10,
      description: 'O Messias prometido, Filho de Deus, Salvador do mundo. Cumprimento de todas as promessas e profecias.',
    ),
    const BibleNode(
      id: 'paulo',
      title: 'Paulo',
      type: NodeType.character,
      period: 'Igreja Primitiva',
      references: ['At 9:1-19', 'Rm 1:1', 'Gl 1:11-24', 'Fp 3:4-11'],
      weight: 9,
      description: 'Apóstolo dos gentios, autor de grande parte do Novo Testamento. Convertido dramaticamente no caminho de Damasco.',
    ),
    const BibleNode(
      id: 'adao',
      title: 'Adão',
      type: NodeType.character,
      period: 'Criação',
      references: ['Gn 1:26-27', 'Gn 2:7', 'Gn 3:1-24', 'Rm 5:12-21'],
      weight: 8,
      description: 'Primeiro homem criado por Deus. Sua queda trouxe pecado e morte ao mundo.',
    ),

    // TEMAS
    const BibleNode(
      id: 'fe',
      title: 'Fé',
      type: NodeType.theme,
      references: ['Hb 11:1', 'Rm 1:17', 'Ef 2:8', 'Tg 2:14-26'],
      weight: 10,
      description: 'Confiança e certeza nas promessas de Deus, mesmo sem ver. É o meio pelo qual somos justificados.',
    ),
    const BibleNode(
      id: 'redencao',
      title: 'Redenção',
      type: NodeType.theme,
      references: ['Êx 6:6', 'Is 53:5', 'Ef 1:7', 'Tt 2:14', '1Pe 1:18-19'],
      weight: 9,
      description: 'Libertação do pecado e escravidão através do sacrifício de Cristo, prefigurada pela libertação de Israel do Egito.',
    ),
    const BibleNode(
      id: 'alianca',
      title: 'Aliança',
      type: NodeType.theme,
      references: ['Gn 15:18', 'Êx 24:7-8', 'Jr 31:31-34', 'Lc 22:20'],
      weight: 9,
      description: 'Pacto solene entre Deus e seu povo, estabelecendo promessas e compromissos mútuos.',
    ),
    const BibleNode(
      id: 'graca',
      title: 'Graça',
      type: NodeType.theme,
      references: ['Ef 2:8-9', 'Rm 3:24', 'Rm 11:6', 'Tt 2:11'],
      weight: 10,
      description: 'Favor imerecido de Deus concedido aos pecadores. Somos salvos pela graça mediante a fé.',
    ),
    const BibleNode(
      id: 'obediencia',
      title: 'Obediência',
      type: NodeType.theme,
      references: ['Dt 11:27', '1Sm 15:22', 'Jo 14:15', 'Tg 1:22'],
      weight: 7,
      description: 'Submissão à vontade de Deus demonstrada através de ações. Melhor que sacrifícios.',
    ),
    const BibleNode(
      id: 'sacrificio',
      title: 'Sacrifício',
      type: NodeType.theme,
      references: ['Lv 16:15-16', 'Is 53:10', 'Hb 9:11-14', 'Hb 10:10'],
      weight: 8,
      description: 'Oferta para expiação do pecado, cumprida perfeitamente no sacrifício de Cristo.',
    ),

    // EVENTOS
    const BibleNode(
      id: 'exodo',
      title: 'Êxodo',
      type: NodeType.event,
      period: 'Êxodo',
      references: ['Êx 12:31-42', 'Êx 14:21-31', '1Co 5:7'],
      weight: 9,
      description: 'Libertação miraculosa de Israel da escravidão do Egito através de Moisés, prefigurando a redenção em Cristo.',
    ),
    const BibleNode(
      id: 'crucificacao',
      title: 'Crucificação',
      type: NodeType.event,
      period: 'Novo Testamento',
      references: ['Mt 27:32-56', 'Jo 19:17-30', '1Co 1:18', 'Gl 6:14'],
      weight: 10,
      description: 'Morte de Jesus na cruz, pagando o preço pelos pecados da humanidade. Evento central da história da redenção.',
    ),
    const BibleNode(
      id: 'pentecostes',
      title: 'Pentecostes',
      type: NodeType.event,
      period: 'Igreja Primitiva',
      references: ['At 2:1-41', 'Jl 2:28-29'],
      weight: 8,
      description: 'Derramamento do Espírito Santo sobre os discípulos, inaugurando a era da Igreja.',
    ),

    // LUGARES
    const BibleNode(
      id: 'jerusalem',
      title: 'Jerusalém',
      type: NodeType.place,
      period: 'Monarquia',
      references: ['2Sm 5:6-9', '1Rs 8:1', 'Sl 122:6', 'Ap 21:2'],
      weight: 9,
      description: 'Cidade santa, capital do reino de Davi, local do Templo. Símbolo da presença de Deus e da cidade celestial.',
    ),
    const BibleNode(
      id: 'babilonia',
      title: 'Babilônia',
      type: NodeType.place,
      period: 'Exílio',
      references: ['2Rs 25:8-21', 'Dn 1:1-7', 'Ap 17:5', 'Ap 18:2'],
      weight: 7,
      description: 'Local do exílio de Judá e símbolo de oposição a Deus. Representa sistemas mundanos contrários ao Reino.',
    ),
    const BibleNode(
      id: 'eden',
      title: 'Jardim do Éden',
      type: NodeType.place,
      period: 'Criação',
      references: ['Gn 2:8-15', 'Gn 3:23-24', 'Ap 22:1-5'],
      weight: 8,
      description: 'Paraíso original onde Deus colocou Adão e Eva. Prefigura a Nova Criação restaurada.',
    ),

    // DOUTRINAS
    const BibleNode(
      id: 'justificacao',
      title: 'Justificação pela Fé',
      type: NodeType.doctrine,
      references: ['Rm 3:28', 'Rm 5:1', 'Gl 2:16', 'Gl 3:11'],
      weight: 10,
      description: 'Doutrina central de que somos declarados justos diante de Deus pela fé em Cristo, não por obras.',
    ),
    const BibleNode(
      id: 'ressurreicao',
      title: 'Ressurreição',
      type: NodeType.doctrine,
      references: ['Mt 28:1-10', '1Co 15:3-8', '1Co 15:20-23', '1Ts 4:16-17'],
      weight: 9,
      description: 'Cristo ressuscitou dos mortos e garante a ressurreição de todos os que creem nele.',
    ),
    const BibleNode(
      id: 'trindade',
      title: 'Trindade',
      type: NodeType.doctrine,
      references: ['Mt 28:19', 'Jo 14:16-17', '2Co 13:13', '1Pe 1:2'],
      weight: 8,
      description: 'Deus existe eternamente em três pessoas: Pai, Filho e Espírito Santo.',
    ),
  ];

  // =================== CONEXÕES ===================
  
  static final List<NodeConnection> connections = [
    // Abraão → Fé → Justificação
    const NodeConnection(
      id: 'conn_1',
      sourceId: 'abraao',
      targetId: 'fe',
      type: ConnectionType.typology,
      description: 'Abraão é o modelo bíblico de fé genuína',
      supportingVerses: ['Gn 15:6', 'Rm 4:3', 'Tg 2:23'],
    ),
    const NodeConnection(
      id: 'conn_2',
      sourceId: 'fe',
      targetId: 'justificacao',
      type: ConnectionType.causation,
      description: 'A fé é o meio pelo qual somos justificados',
      supportingVerses: ['Rm 3:28', 'Rm 5:1', 'Gl 2:16'],
    ),
    const NodeConnection(
      id: 'conn_3',
      sourceId: 'abraao',
      targetId: 'justificacao',
      type: ConnectionType.fulfillment,
      description: 'Abraão foi justificado pela fé, exemplo para todos os crentes',
      supportingVerses: ['Rm 4:22-24', 'Gl 3:6-9'],
    ),

    // Abraão → Isaque (Promessa)
    const NodeConnection(
      id: 'conn_4',
      sourceId: 'abraao',
      targetId: 'isaque',
      type: ConnectionType.promise,
      description: 'Deus prometeu um filho a Abraão e Sara',
      supportingVerses: ['Gn 15:4', 'Gn 17:19', 'Gn 21:1-2'],
    ),
    const NodeConnection(
      id: 'conn_5',
      sourceId: 'isaque',
      targetId: 'alianca',
      type: ConnectionType.fulfillment,
      description: 'O nascimento de Isaque confirmou a aliança de Deus',
      supportingVerses: ['Gn 17:21', 'Gn 26:3-4'],
    ),

    // Êxodo → Redenção (Tipologia)
    const NodeConnection(
      id: 'conn_6',
      sourceId: 'exodo',
      targetId: 'redencao',
      type: ConnectionType.typology,
      description: 'O Êxodo prefigura a redenção espiritual em Cristo',
      supportingVerses: ['1Co 5:7', '1Co 10:1-4'],
    ),
    const NodeConnection(
      id: 'conn_7',
      sourceId: 'moises',
      targetId: 'exodo',
      type: ConnectionType.causation,
      description: 'Moisés foi o instrumento de Deus para libertar Israel',
      supportingVerses: ['Êx 3:10', 'Êx 14:21', 'Êx 15:1'],
    ),
    const NodeConnection(
      id: 'conn_8',
      sourceId: 'crucificacao',
      targetId: 'redencao',
      type: ConnectionType.fulfillment,
      description: 'A cruz é o cumprimento pleno da redenção',
      supportingVerses: ['Ef 1:7', 'Cl 1:14', '1Pe 1:18-19'],
    ),

    // Davi → Jesus (Linhagem)
    const NodeConnection(
      id: 'conn_9',
      sourceId: 'davi',
      targetId: 'jesus',
      type: ConnectionType.promise,
      description: 'Deus prometeu que da linhagem de Davi viria o Messias',
      supportingVerses: ['2Sm 7:12-16', 'Is 11:1', 'Jr 23:5'],
    ),
    const NodeConnection(
      id: 'conn_10',
      sourceId: 'jesus',
      targetId: 'davi',
      type: ConnectionType.fulfillment,
      description: 'Jesus é o Filho de Davi, o Messias prometido',
      supportingVerses: ['Mt 1:1', 'Lc 1:32', 'Rm 1:3'],
    ),

    // Sacrifício → Jesus
    const NodeConnection(
      id: 'conn_11',
      sourceId: 'sacrificio',
      targetId: 'jesus',
      type: ConnectionType.typology,
      description: 'Os sacrifícios do AT apontavam para o sacrifício perfeito de Cristo',
      supportingVerses: ['Hb 9:11-14', 'Hb 10:1-10'],
    ),
    const NodeConnection(
      id: 'conn_12',
      sourceId: 'jesus',
      targetId: 'crucificacao',
      type: ConnectionType.causation,
      description: 'Jesus se ofereceu voluntariamente na cruz',
      supportingVerses: ['Jo 10:18', 'Fp 2:8', 'Hb 12:2'],
    ),

    // Graça vs Obras
    const NodeConnection(
      id: 'conn_13',
      sourceId: 'graca',
      targetId: 'obediencia',
      type: ConnectionType.contrast,
      description: 'Salvos pela graça, não por obras, mas a fé verdadeira produz obediência',
      supportingVerses: ['Ef 2:8-10', 'Tt 2:11-14'],
    ),

    // Adão vs Cristo (Contraste)
    const NodeConnection(
      id: 'conn_14',
      sourceId: 'adao',
      targetId: 'jesus',
      type: ConnectionType.contrast,
      description: 'Adão trouxe morte, Cristo trouxe vida',
      supportingVerses: ['Rm 5:12-21', '1Co 15:21-22', '1Co 15:45'],
    ),
    const NodeConnection(
      id: 'conn_15',
      sourceId: 'eden',
      targetId: 'adao',
      type: ConnectionType.causation,
      description: 'Adão foi criado e colocado no Éden',
      supportingVerses: ['Gn 2:8', 'Gn 2:15'],
    ),

    // Paulo → Justificação
    const NodeConnection(
      id: 'conn_16',
      sourceId: 'paulo',
      targetId: 'justificacao',
      type: ConnectionType.causation,
      description: 'Paulo foi o principal expositor da doutrina da justificação pela fé',
      supportingVerses: ['Rm 3:21-28', 'Gl 2:16', 'Gl 3:11'],
    ),

    // Jerusalém → Templo
    const NodeConnection(
      id: 'conn_17',
      sourceId: 'davi',
      targetId: 'jerusalem',
      type: ConnectionType.causation,
      description: 'Davi conquistou Jerusalém e a estabeleceu como capital',
      supportingVerses: ['2Sm 5:6-9', '1Cr 11:4-9'],
    ),

    // Babilônia vs Jerusalém
    const NodeConnection(
      id: 'conn_18',
      sourceId: 'babilonia',
      targetId: 'jerusalem',
      type: ConnectionType.contrast,
      description: 'Babilônia representa o sistema mundano oposto à cidade santa',
      supportingVerses: ['Ap 17:5', 'Ap 18:2', 'Ap 21:2'],
    ),

    // Pentecostes → Igreja
    const NodeConnection(
      id: 'conn_19',
      sourceId: 'pentecostes',
      targetId: 'paulo',
      type: ConnectionType.parallel,
      description: 'Paulo foi um instrumento-chave na expansão da igreja após Pentecostes',
      supportingVerses: ['At 9:15', 'At 13:2-4', 'Rm 15:18-19'],
    ),

    // Ressurreição → Jesus
    const NodeConnection(
      id: 'conn_20',
      sourceId: 'jesus',
      targetId: 'ressurreicao',
      type: ConnectionType.fulfillment,
      description: 'Jesus ressuscitou, garantindo a ressurreição de todos os crentes',
      supportingVerses: ['1Co 15:20', '1Co 15:23', '1Ts 4:14'],
    ),

    // Fé → Obediência
    const NodeConnection(
      id: 'conn_21',
      sourceId: 'fe',
      targetId: 'obediencia',
      type: ConnectionType.causation,
      description: 'A fé verdadeira resulta em obediência',
      supportingVerses: ['Tg 2:14-26', 'Hb 11:8', '1Jo 2:3-6'],
    ),

    // Aliança → Jesus
    const NodeConnection(
      id: 'conn_22',
      sourceId: 'jesus',
      targetId: 'alianca',
      type: ConnectionType.fulfillment,
      description: 'Jesus é o mediador da Nova Aliança',
      supportingVerses: ['Jr 31:31-34', 'Lc 22:20', 'Hb 8:6-13'],
    ),

    // Trindade → Jesus
    const NodeConnection(
      id: 'conn_23',
      sourceId: 'jesus',
      targetId: 'trindade',
      type: ConnectionType.causation,
      description: 'Jesus revelou plenamente a natureza triúna de Deus',
      supportingVerses: ['Mt 28:19', 'Jo 14:16-17', 'Jo 16:13-15'],
    ),
  ];

  /// Retorna todos os nós
  static List<BibleNode> getAllNodes() => nodes;

  /// Retorna todas as conexões
  static List<NodeConnection> getAllConnections() => connections;

  /// Retorna conexões para um nó específico
  static List<NodeConnection> getConnectionsForNode(String nodeId) {
    return connections.where((conn) =>
      conn.sourceId == nodeId || conn.targetId == nodeId
    ).toList();
  }

  /// Retorna períodos únicos disponíveis
  static List<String> getAvailablePeriods() {
    final periods = nodes
        .where((node) => node.period != null)
        .map((node) => node.period!)
        .toSet()
        .toList();
    periods.sort();
    return periods;
  }
}
