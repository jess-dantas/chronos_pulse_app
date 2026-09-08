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