double _toDoubleLicit(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String && value.isNotEmpty) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

String _formatDateLicit(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
}

class LicitacaoItemModel {
  final String id;
  final String materialId;
  final String descricao;
  final double quantidade;
  final double? valorEstimadoUnitario;
  final double valorEstimadoTotal;
  final String unidadeMedida;

  LicitacaoItemModel({
    this.id = '',
    this.materialId = '',
    this.descricao = '',
    this.quantidade = 0,
    this.valorEstimadoUnitario,
    this.valorEstimadoTotal = 0,
    this.unidadeMedida = '',
  });

  factory LicitacaoItemModel.fromJson(Map<String, dynamic> json) {
    return LicitacaoItemModel(
      id: json['id']?.toString() ?? '',
      materialId: json['materialId']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      quantidade: _toDoubleLicit(json['quantidade']),
      valorEstimadoUnitario: json['valorEstimadoUnitario'] != null
          ? _toDoubleLicit(json['valorEstimadoUnitario'])
          : null,
      valorEstimadoTotal: _toDoubleLicit(json['valorEstimadoTotal']),
      unidadeMedida: json['unidadeMedida']?.toString() ?? '',
    );
  }
}

class LicitacaoParticipanteModel {
  final String fornecedorId;
  final String fornecedorNome;
  final bool habilitado;

  LicitacaoParticipanteModel({
    this.fornecedorId = '',
    this.fornecedorNome = '',
    this.habilitado = true,
  });

  factory LicitacaoParticipanteModel.fromJson(Map<String, dynamic> json) {
    return LicitacaoParticipanteModel(
      fornecedorId: json['fornecedorId']?.toString() ?? '',
      fornecedorNome: json['fornecedorNome']?.toString() ?? '',
      habilitado: json['habilitado'] == true,
    );
  }
}

class LicitacaoPropostaModel {
  final String id;
  final String fornecedorId;
  final String fornecedorNome;
  final String materialId;
  final String materialDescricao;
  final double valorUnitario;
  final bool vencedor;

  LicitacaoPropostaModel({
    this.id = '',
    this.fornecedorId = '',
    this.fornecedorNome = '',
    this.materialId = '',
    this.materialDescricao = '',
    this.valorUnitario = 0,
    this.vencedor = false,
  });

  factory LicitacaoPropostaModel.fromJson(Map<String, dynamic> json) {
    return LicitacaoPropostaModel(
      id: json['id']?.toString() ?? '',
      fornecedorId: json['fornecedorId']?.toString() ?? '',
      fornecedorNome: json['fornecedorNome']?.toString() ?? '',
      materialId: json['materialId']?.toString() ?? '',
      materialDescricao: json['materialDescricao']?.toString() ?? '',
      valorUnitario: _toDoubleLicit(json['valorUnitario']),
      vencedor: json['vencedor'] == true,
    );
  }
}

class LicitacaoModel {
  final String id;
  final String tenantId;
  final String numero;
  final String modalidade;
  final String tipoJulgamento;
  final String objeto;
  final String? dataAbertura;
  final double? valorEstimado;
  final String? observacoes;
  final String status;
  final bool pedidoGerado;
  final String? criadoEm;
  final String pncpStatus;
  final String? pncpProtocolo;
  final String? pncpPublicadoEm;
  final String? pncpErro;
  final List<LicitacaoItemModel> itens;
  final List<LicitacaoParticipanteModel> participantes;
  final List<LicitacaoPropostaModel> propostas;

  LicitacaoModel({
    this.id = '',
    this.tenantId = '',
    this.numero = '',
    this.modalidade = '',
    this.tipoJulgamento = '',
    this.objeto = '',
    this.dataAbertura,
    this.valorEstimado,
    this.observacoes,
    this.status = 'EM_ELABORACAO',
    this.pedidoGerado = false,
    this.criadoEm,
    this.pncpStatus = 'NAO_PUBLICADO',
    this.pncpProtocolo,
    this.pncpPublicadoEm,
    this.pncpErro,
    this.itens = const [],
    this.participantes = const [],
    this.propostas = const [],
  });

  factory LicitacaoModel.fromJson(Map<String, dynamic> json) {
    final itensRaw = json['itens'];
    final participantesRaw = json['participantes'];
    final propostasRaw = json['propostas'];
    return LicitacaoModel(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      numero: json['numero']?.toString() ?? '',
      modalidade: json['modalidade']?.toString() ?? '',
      tipoJulgamento: json['tipoJulgamento']?.toString() ?? '',
      objeto: json['objeto']?.toString() ?? '',
      dataAbertura: json['dataAbertura']?.toString(),
      valorEstimado: json['valorEstimado'] != null ? _toDoubleLicit(json['valorEstimado']) : null,
      observacoes: json['observacoes']?.toString(),
      status: json['status']?.toString() ?? 'EM_ELABORACAO',
      pedidoGerado: json['pedidoGerado'] == true,
      criadoEm: json['criadoEm']?.toString(),
      pncpStatus: json['pncpStatus']?.toString() ?? 'NAO_PUBLICADO',
      pncpProtocolo: json['pncpProtocolo']?.toString(),
      pncpPublicadoEm: json['pncpPublicadoEm']?.toString(),
      pncpErro: json['pncpErro']?.toString(),
      itens: itensRaw is List
          ? itensRaw.map((e) => LicitacaoItemModel.fromJson(e)).toList()
          : const [],
      participantes: participantesRaw is List
          ? participantesRaw.map((e) => LicitacaoParticipanteModel.fromJson(e)).toList()
          : const [],
      propostas: propostasRaw is List
          ? propostasRaw.map((e) => LicitacaoPropostaModel.fromJson(e)).toList()
          : const [],
    );
  }

  String get modalidadeLabel => _labelModalidade(modalidade);
  String get tipoJulgamentoLabel => _labelJulgamento(tipoJulgamento);
  String get statusLabel => _labelStatus(status);
  String get dataAberturaFormatada => _formatDateLicit(dataAbertura);

  int get propostasPorFornecedor => participantes.length;

  bool get emElaboracao => status == 'EM_ELABORACAO';
  bool get emDisputa => status == 'PUBLICADA' || status == 'ABERTA';
  bool get adjudicada => status == 'ADJUDICADA';
  bool get homologada => status == 'HOMOLOGADA';
  bool get cancelada => status == 'CANCELADA';

  bool get pncpPublicado => pncpStatus == 'PUBLICADO';
  bool get pncpFalhou => pncpStatus == 'FALHA';
  String get pncpStatusLabel => _labelPncpStatus(pncpStatus);
  String get pncpPublicadoEmFormatado => _formatDateLicit(pncpPublicadoEm);

  bool get cancelavel => emElaboracao || emDisputa;
  bool get publicavel => emElaboracao;

  List<LicitacaoPropostaModel> get vencedores =>
      propostas.where((p) => p.vencedor).toList();
}

class CadastrarLicitacaoDTO {
  final String modalidade;
  final String tipoJulgamento;
  final String objeto;
  final String? dataAbertura;
  final String? observacoes;
  final List<LicitacaoItemDTO> itens;

  CadastrarLicitacaoDTO({
    required this.modalidade,
    required this.tipoJulgamento,
    required this.objeto,
    this.dataAbertura,
    this.observacoes,
    required this.itens,
  });

  Map<String, dynamic> toJson() => {
        'modalidade': modalidade,
        'tipoJulgamento': tipoJulgamento,
        'objeto': objeto,
        if (dataAbertura != null && dataAbertura!.isNotEmpty) 'dataAbertura': dataAbertura,
        if (observacoes != null && observacoes!.isNotEmpty) 'observacoes': observacoes,
        'itens': itens.map((e) => e.toJson()).toList(),
      };
}

class LicitacaoItemDTO {
  final String materialId;
  final double quantidade;
  final double? valorEstimadoUnitario;

  LicitacaoItemDTO({
    required this.materialId,
    required this.quantidade,
    this.valorEstimadoUnitario,
  });

  Map<String, dynamic> toJson() => {
        'materialId': materialId,
        'quantidade': quantidade,
        if (valorEstimadoUnitario != null) 'valorEstimadoUnitario': valorEstimadoUnitario,
      };
}

class PublicarLicitacaoDTO {
  final List<String> fornecedoresIds;

  PublicarLicitacaoDTO({required this.fornecedoresIds});

  Map<String, dynamic> toJson() => {'fornecedoresIds': fornecedoresIds};
}

class LicitacaoPropostaDTO {
  final String materialId;
  final double valorUnitario;

  LicitacaoPropostaDTO({required this.materialId, required this.valorUnitario});

  Map<String, dynamic> toJson() => {
        'materialId': materialId,
        'valorUnitario': valorUnitario,
      };
}

class RegistrarPropostasLicitacaoDTO {
  final String fornecedorId;
  final List<LicitacaoPropostaDTO> itens;

  RegistrarPropostasLicitacaoDTO({
    required this.fornecedorId,
    required this.itens,
  });

  Map<String, dynamic> toJson() => {
        'fornecedorId': fornecedorId,
        'itens': itens.map((e) => e.toJson()).toList(),
      };
}

String _labelModalidade(String m) {
  switch (m) {
    case 'PREGAO':
      return 'Pregão';
    case 'CONCORRENCIA':
      return 'Concorrência';
    case 'LEILAO':
      return 'Leilão';
    case 'CONCURSO':
      return 'Concurso';
    case 'DIALOGO_COMPETITIVO':
      return 'Diálogo Competitivo';
    default:
      return m;
  }
}

String _labelJulgamento(String j) {
  switch (j) {
    case 'MENOR_PRECO':
      return 'Menor Preço';
    case 'MAIOR_DESCONTO':
      return 'Maior Desconto';
    case 'MELHOR_TECNICA':
      return 'Melhor Técnica';
    case 'TECNICA_E_PRECO':
      return 'Técnica e Preço';
    case 'MAIOR_LANCE':
      return 'Maior Lance';
    default:
      return j;
  }
}

String _labelStatus(String s) {
  switch (s) {
    case 'EM_ELABORACAO':
      return 'Em elaboração';
    case 'PUBLICADA':
      return 'Publicada';
    case 'ABERTA':
      return 'Em disputa';
    case 'ADJUDICADA':
      return 'Adjudicada';
    case 'HOMOLOGADA':
      return 'Homologada';
    case 'CANCELADA':
      return 'Cancelada';
    default:
      return s;
  }
}

String _labelPncpStatus(String s) {
  switch (s) {
    case 'PUBLICADO':
      return 'Publicado no PNCP';
    case 'FALHA':
      return 'Falha no PNCP';
    default:
      return 'Não publicado no PNCP';
  }
}