class PatrimonioModel {
  final String id;
  final String? tombamento;
  final String descricao;
  final String? categoria;
  final String estado;
  final String? localizacao;
  final String? dataAquisicao;
  final String? valorAquisicao;
  final String? responsavelNome;
  final String? numeroNotaFiscal;
  final String? observacoes;
  final bool ativo;
  final String? vidaUtilMeses;
  final String? taxaDepreciacaoMensal;
  final String? valorDepreciado;
  final String? dataInicioDepreciacao;
  final String? valorAtual;

  PatrimonioModel({
    required this.id,
    this.tombamento,
    required this.descricao,
    this.categoria,
    this.estado = 'BOM',
    this.localizacao,
    this.dataAquisicao,
    this.valorAquisicao,
    this.responsavelNome,
    this.numeroNotaFiscal,
    this.observacoes,
    this.ativo = true,
    this.vidaUtilMeses,
    this.taxaDepreciacaoMensal,
    this.valorDepreciado,
    this.dataInicioDepreciacao,
    this.valorAtual,
  });

  factory PatrimonioModel.fromJson(Map<String, dynamic> json) {
    return PatrimonioModel(
      id: json['id']?.toString() ?? '',
      tombamento: json['tombamento']?.toString(),
      descricao: json['descricao']?.toString() ?? '',
      categoria: json['categoria']?.toString(),
      estado: json['estado']?.toString() ?? 'BOM',
      localizacao: json['localizacao']?.toString(),
      dataAquisicao: json['dataAquisicao']?.toString(),
      valorAquisicao: json['valorAquisicao']?.toString(),
      responsavelNome: json['responsavelNome']?.toString(),
      numeroNotaFiscal: json['numeroNotaFiscal']?.toString(),
      observacoes: json['observacoes']?.toString(),
      ativo: json['ativo'] ?? true,
      vidaUtilMeses: json['vidaUtilMeses']?.toString(),
      taxaDepreciacaoMensal: json['taxaDepreciacaoMensal']?.toString(),
      valorDepreciado: json['valorDepreciado']?.toString(),
      dataInicioDepreciacao: json['dataInicioDepreciacao']?.toString(),
      valorAtual: json['valorAtual']?.toString(),
    );
  }
}

class InventarioItemModel {
  final String? id;
  final String patrimonioId;
  final String? patrimonioTombamento;
  final String? patrimonioDescricao;
  final bool conferido;
  final String? conferidoPor;
  final String? dataConferencia;
  final String? resultado;
  final String? observacao;

  const InventarioItemModel({
    this.id,
    required this.patrimonioId,
    this.patrimonioTombamento,
    this.patrimonioDescricao,
    this.conferido = false,
    this.conferidoPor,
    this.dataConferencia,
    this.resultado,
    this.observacao,
  });

  factory InventarioItemModel.fromJson(Map<String, dynamic> json) {
    return InventarioItemModel(
      id: json['id']?.toString(),
      patrimonioId: json['patrimonioId']?.toString() ?? '',
      patrimonioTombamento: json['patrimonioTombamento']?.toString(),
      patrimonioDescricao: json['patrimonioDescricao']?.toString(),
      conferido: json['conferido'] == true,
      conferidoPor: json['conferidoPor']?.toString(),
      dataConferencia: json['dataConferencia']?.toString(),
      resultado: json['resultado']?.toString(),
      observacao: json['observacao']?.toString(),
    );
  }
}

class InventarioModel {
  final String id;
  final String descricao;
  final String? dataInicio;
  final String? dataFim;
  final String status;
  final String? criadoPor;
  final String? criadoEm;
  final int totalItens;
  final int totalConferidos;
  final int totalConformes;
  final int totalDivergencias;
  final List<InventarioItemModel> itens;

  const InventarioModel({
    required this.id,
    required this.descricao,
    this.dataInicio,
    this.dataFim,
    this.status = 'EM_ANDAMENTO',
    this.criadoPor,
    this.criadoEm,
    this.totalItens = 0,
    this.totalConferidos = 0,
    this.totalConformes = 0,
    this.totalDivergencias = 0,
    this.itens = const [],
  });

  double get progresso =>
      totalItens == 0 ? 0 : (totalConferidos / totalItens).clamp(0.0, 1.0);

  factory InventarioModel.fromJson(Map<String, dynamic> json) {
    final itens = (json['itens'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(InventarioItemModel.fromJson)
        .toList();
    return InventarioModel(
      id: json['id']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      dataInicio: json['dataInicio']?.toString(),
      dataFim: json['dataFim']?.toString(),
      status: json['status']?.toString() ?? 'EM_ANDAMENTO',
      criadoPor: json['criadoPor']?.toString(),
      criadoEm: json['criadoEm']?.toString(),
      totalItens: json['totalItens'] is num ? (json['totalItens'] as num).toInt() : itens.length,
      totalConferidos: json['totalConferidos'] is num
          ? (json['totalConferidos'] as num).toInt()
          : itens.where((i) => i.conferido).length,
      totalConformes: json['totalConformes'] is num
          ? (json['totalConformes'] as num).toInt()
          : itens.where((i) => i.resultado == 'CONFORME').length,
      totalDivergencias: json['totalDivergencias'] is num
          ? (json['totalDivergencias'] as num).toInt()
          : itens.where((i) => i.resultado == 'DIVERGENCIA').length,
      itens: itens,
    );
  }
}

class TransferenciaModel {
  final String id;
  final String patrimonioId;
  final String? localizacaoOrigem;
  final String localizacaoDestino;
  final String? responsavelOrigem;
  final String? responsavelDestino;
  final String? dataSolicitacao;
  final String? dataPrevista;
  final String? dataEfetivacao;
  final String status;
  final String? justificativa;
  final String? aprovadoPor;
  final String? solicitadoPor;

  const TransferenciaModel({
    required this.id,
    required this.patrimonioId,
    this.localizacaoOrigem,
    required this.localizacaoDestino,
    this.responsavelOrigem,
    this.responsavelDestino,
    this.dataSolicitacao,
    this.dataPrevista,
    this.dataEfetivacao,
    this.status = 'SOLICITADA',
    this.justificativa,
    this.aprovadoPor,
    this.solicitadoPor,
  });

  factory TransferenciaModel.fromJson(Map<String, dynamic> json) {
    return TransferenciaModel(
      id: json['id']?.toString() ?? '',
      patrimonioId: json['patrimonioId']?.toString() ?? '',
      localizacaoOrigem: json['localizacaoOrigem']?.toString(),
      localizacaoDestino: json['localizacaoDestino']?.toString() ?? '',
      responsavelOrigem: json['responsavelOrigem']?.toString(),
      responsavelDestino: json['responsavelDestino']?.toString(),
      dataSolicitacao: json['dataSolicitacao']?.toString(),
      dataPrevista: json['dataPrevista']?.toString(),
      dataEfetivacao: json['dataEfetivacao']?.toString(),
      status: json['status']?.toString() ?? 'SOLICITADA',
      justificativa: json['justificativa']?.toString(),
      aprovadoPor: json['aprovadoPor']?.toString(),
      solicitadoPor: json['solicitadoPor']?.toString(),
    );
  }
}

class DesfazimentoMembroModel {
  final String? id;
  final String nome;
  final String? cargo;
  final String? cpf;
  final String? parecer;
  final bool relator;

  const DesfazimentoMembroModel({
    this.id,
    required this.nome,
    this.cargo,
    this.cpf,
    this.parecer,
    this.relator = false,
  });

  factory DesfazimentoMembroModel.fromJson(Map<String, dynamic> json) {
    return DesfazimentoMembroModel(
      id: json['id']?.toString(),
      nome: json['nome']?.toString() ?? '',
      cargo: json['cargo']?.toString(),
      cpf: json['cpf']?.toString(),
      parecer: json['parecer']?.toString(),
      relator: json['relator'] == true,
    );
  }
}

class DesfazimentoModel {
  final String id;
  final String? tenantId;
  final String? patrimonioId;
  final String? patrimonioDescricao;
  final String? tombamento;
  final String estadoBem;
  final String tipoDesfazimento;
  final String? justificativa;
  final String? responsavelSolicitacao;
  final String? dataSolicitacao;
  final String? parecerComissao;
  final bool? aprovado;
  final String? dataAprovacao;
  final String? dataBaixa;
  final String status;
  final String? processoNumero;
  final List<DesfazimentoMembroModel> comissao;

  const DesfazimentoModel({
    required this.id,
    this.tenantId,
    this.patrimonioId,
    this.patrimonioDescricao,
    this.tombamento,
    this.estadoBem = 'OCIOSO',
    this.tipoDesfazimento = 'VENDA',
    this.justificativa,
    this.responsavelSolicitacao,
    this.dataSolicitacao,
    this.parecerComissao,
    this.aprovado,
    this.dataAprovacao,
    this.dataBaixa,
    this.status = 'EM_ANALISE',
    this.processoNumero,
    this.comissao = const [],
  });

  factory DesfazimentoModel.fromJson(Map<String, dynamic> json) {
    final membros = (json['comissao'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DesfazimentoMembroModel.fromJson)
        .toList();
    return DesfazimentoModel(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString(),
      patrimonioId: json['patrimonioId']?.toString(),
      patrimonioDescricao: json['patrimonioDescricao']?.toString(),
      tombamento: json['tombamento']?.toString(),
      estadoBem: json['estadoBem']?.toString() ?? 'OCIOSO',
      tipoDesfazimento: json['tipoDesfazimento']?.toString() ?? 'VENDA',
      justificativa: json['justificativa']?.toString(),
      responsavelSolicitacao: json['responsavelSolicitacao']?.toString(),
      dataSolicitacao: json['dataSolicitacao']?.toString(),
      parecerComissao: json['parecerComissao']?.toString(),
      aprovado: json['aprovado'],
      dataAprovacao: json['dataAprovacao']?.toString(),
      dataBaixa: json['dataBaixa']?.toString(),
      status: json['status']?.toString() ?? 'EM_ANALISE',
      processoNumero: json['processoNumero']?.toString(),
      comissao: membros,
    );
  }
}