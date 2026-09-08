
class MaterialModel {
  final String id;
  final String grupoId;
  final String? grupoNome;
  final String? codigoCatmat;
  final String? codigoBarras;
  final String descricao;
  final String unidadeMedida;
  final double? estoqueMinimo;
  final bool controlaLoteValidade;
  final bool ativo;

  MaterialModel({
    required this.id,
    required this.grupoId,
    this.grupoNome,
    this.codigoCatmat,
    this.codigoBarras,
    required this.descricao,
    required this.unidadeMedida,
    this.estoqueMinimo,
    this.controlaLoteValidade = false,
    this.ativo = true,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'] ?? '',
      grupoId: json['grupoId'] ?? '',
      grupoNome: json['grupoNome'],
      codigoCatmat: json['codigoCatmat'],
      codigoBarras: json['codigoBarras'],
      descricao: json['descricao'] ?? '',
      unidadeMedida: json['unidadeMedida'] ?? 'UN',
      estoqueMinimo: _toDouble(json['estoqueMinimo']),
      controlaLoteValidade: json['controlaLoteValidade'] ?? false,
      ativo: json['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grupoId': grupoId,
      'codigoCatmat': codigoCatmat,
      'codigoBarras': codigoBarras,
      'descricao': descricao,
      'unidadeMedida': unidadeMedida,
      'estoqueMinimo': estoqueMinimo,
      'controlaLoteValidade': controlaLoteValidade,
      'ativo': ativo,
    };
  }
}

class AlmoxarifadoModel {
  final String id;
  final String nome;
  final String? descricao;
  final String? responsavelCpcId;
  final bool ativo;

  AlmoxarifadoModel({
    required this.id,
    required this.nome,
    this.descricao,
    this.responsavelCpcId,
    this.ativo = true,
  });

  factory AlmoxarifadoModel.fromJson(Map<String, dynamic> json) {
    return AlmoxarifadoModel(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      descricao: json['descricao'],
      responsavelCpcId: json['responsavelCpcId'],
      ativo: json['ativo'] ?? true,
    );
  }
}

class EstoqueSaldoModel {
  final String id;
  final String almoxarifadoId;
  final String? almoxarifadoNome;
  final String materialId;
  final String? materialDescricao;
  final String? unidadeMedida;
  final String? codigoCatmat;
  final String? codigoBarras;
  final String? lote;
  final String? dataValidade;
  final double quantidadeAtual;
  final double custoMedioUnitario;
  final double valorTotal;
  final double? estoqueMinimo;

  EstoqueSaldoModel({
    required this.id,
    required this.almoxarifadoId,
    this.almoxarifadoNome,
    required this.materialId,
    this.materialDescricao,
    this.unidadeMedida,
    this.codigoCatmat,
    this.codigoBarras,
    this.lote,
    this.dataValidade,
    required this.quantidadeAtual,
    required this.custoMedioUnitario,
    required this.valorTotal,
    this.estoqueMinimo,
  });

  bool get isAbaixoMinimo =>
      estoqueMinimo != null && quantidadeAtual < (estoqueMinimo ?? 0);

  DateTime? get dataValidadeDateTime {
    if (dataValidade == null || dataValidade!.isEmpty) return null;
    return DateTime.tryParse(dataValidade!);
  }

  bool get isVencido {
    final data = dataValidadeDateTime;
    if (data == null) return false;
    final hoje = DateTime.now();
    return data.isBefore(DateTime(hoje.year, hoje.month, hoje.day));
  }

  int? get diasParaVencer {
    final data = dataValidadeDateTime;
    if (data == null || isVencido) return null;
    final hoje = DateTime.now();
    return data.difference(DateTime(hoje.year, hoje.month, hoje.day)).inDays;
  }

  factory EstoqueSaldoModel.fromJson(Map<String, dynamic> json) {
    final double qtd = _toDouble(json['quantidadeAtual']) ?? 0.0;
    final double custo = _toDouble(json['custoMedioUnitario']) ?? 0.0;
    final double total = _toDouble(json['valorTotal']) ?? (qtd * custo);

    return EstoqueSaldoModel(
      id: json['id'] ?? '',
      almoxarifadoId: json['almoxarifadoId'] ?? '',
      almoxarifadoNome: json['almoxarifadoNome'],
      materialId: json['materialId'] ?? '',
      materialDescricao: json['materialDescricao'],
      unidadeMedida: json['unidadeMedida'] ?? 'UN',
      codigoCatmat: json['codigoCatmat'],
      codigoBarras: json['codigoBarras'],
      lote: json['lote'],
      dataValidade: json['dataValidade'],
      quantidadeAtual: qtd,
      custoMedioUnitario: custo,
      valorTotal: total,
      estoqueMinimo: _toDouble(json['estoqueMinimo']),
    );
  }
}

class RequisicaoItemModel {
  final String? id;
  final String materialId;
  final String? materialDescricao;
  final String? unidadeMedida;
  final double quantidadeSolicitada;
  final double quantidadeAtendida;

  RequisicaoItemModel({
    this.id,
    required this.materialId,
    this.materialDescricao,
    this.unidadeMedida,
    required this.quantidadeSolicitada,
    this.quantidadeAtendida = 0.0,
  });

  factory RequisicaoItemModel.fromJson(Map<String, dynamic> json) {
    return RequisicaoItemModel(
      id: json['id'],
      materialId: json['materialId'] ?? '',
      materialDescricao: json['materialDescricao'],
      unidadeMedida: json['unidadeMedida'] ?? 'UN',
      quantidadeSolicitada: _toDouble(json['quantidadeSolicitada']) ?? 0.0,
      quantidadeAtendida: _toDouble(json['quantidadeAtendida']) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'materialId': materialId,
      'quantidadeSolicitada': quantidadeSolicitada,
    };
  }
}

class RequisicaoModel {
  final String id;
  final String almoxarifadoId;
  final String? almoxarifadoNome;
  final String solicitanteCpcId;
  final String? solicitanteNome;
  final String? departamento;
  final String? justificativa;
  final String status;
  final String? dataSolicitacao;
  final String? dataAtendimento;
  final List<RequisicaoItemModel> itens;

  RequisicaoModel({
    required this.id,
    required this.almoxarifadoId,
    this.almoxarifadoNome,
    required this.solicitanteCpcId,
    this.solicitanteNome,
    this.departamento,
    this.justificativa,
    required this.status,
    this.dataSolicitacao,
    this.dataAtendimento,
    this.itens = const [],
  });

  factory RequisicaoModel.fromJson(Map<String, dynamic> json) {
    var rawItens = json['itens'] as List? ?? [];
    List<RequisicaoItemModel> parsedItens =
        rawItens.map((i) => RequisicaoItemModel.fromJson(i)).toList();

    return RequisicaoModel(
      id: json['id'] ?? '',
      almoxarifadoId: json['almoxarifadoId'] ?? '',
      almoxarifadoNome: json['almoxarifadoNome'],
      solicitanteCpcId: json['solicitanteCpcId'] ?? '',
      solicitanteNome: json['solicitanteNome'],
      departamento: json['departamento'],
      justificativa: json['justificativa'],
      status: json['status'] ?? 'PENDENTE',
      dataSolicitacao: json['dataSolicitacao'],
      dataAtendimento: json['dataAtendimento'],
      itens: parsedItens,
    );
  }
}

class EntradaEstoqueRequestDTO {
  final String almoxarifadoId;
  final String materialId;
  final double quantidade;
  final double valorUnitario;
  final String? lote;
  final String? dataValidade;
  final String? documentoReferencia;
  final String? tipoTermo;
  final String? numeroTermo;

  EntradaEstoqueRequestDTO({
    required this.almoxarifadoId,
    required this.materialId,
    required this.quantidade,
    required this.valorUnitario,
    this.lote,
    this.dataValidade,
    this.documentoReferencia,
    this.tipoTermo,
    this.numeroTermo,
  });

  Map<String, dynamic> toJson() {
    return {
      'almoxarifadoId': almoxarifadoId,
      'materialId': materialId,
      'quantidade': quantidade,
      'valorUnitario': valorUnitario,
      if (lote != null && lote!.isNotEmpty) 'lote': lote,
      if (dataValidade != null && dataValidade!.isNotEmpty) 'dataValidade': dataValidade,
      if (documentoReferencia != null && documentoReferencia!.isNotEmpty)
        'documentoReferencia': documentoReferencia,
      if (tipoTermo != null && tipoTermo!.isNotEmpty) 'tipoTermo': tipoTermo,
      if (numeroTermo != null && numeroTermo!.isNotEmpty) 'numeroTermo': numeroTermo,
    };
  }
}

class SaidaEstoqueRequestDTO {
  final String almoxarifadoId;
  final String materialId;
  final double quantidade;
  final String? lote;
  final String? documentoReferencia;
  final String? motivoBaixa;
  final String? observacao;

  SaidaEstoqueRequestDTO({
    required this.almoxarifadoId,
    required this.materialId,
    required this.quantidade,
    this.lote,
    this.documentoReferencia,
    this.motivoBaixa,
    this.observacao,
  });

  Map<String, dynamic> toJson() {
    return {
      'almoxarifadoId': almoxarifadoId,
      'materialId': materialId,
      'quantidade': quantidade,
      if (lote != null && lote!.isNotEmpty) 'lote': lote,
      if (documentoReferencia != null && documentoReferencia!.isNotEmpty)
        'documentoReferencia': documentoReferencia,
      if (motivoBaixa != null && motivoBaixa!.isNotEmpty) 'motivoBaixa': motivoBaixa,
      if (observacao != null && observacao!.isNotEmpty) 'observacao': observacao,
    };
  }
}

class CriarRequisicaoRequestDTO {
  final String almoxarifadoId;
  final String? departamento;
  final String? justificativa;
  final List<RequisicaoItemModel> itens;

  CriarRequisicaoRequestDTO({
    required this.almoxarifadoId,
    this.departamento,
    this.justificativa,
    required this.itens,
  });

  Map<String, dynamic> toJson() {
    return {
      'almoxarifadoId': almoxarifadoId,
      if (departamento != null) 'departamento': departamento,
      if (justificativa != null) 'justificativa': justificativa,
      'itens': itens.map((item) => item.toJson()).toList(),
    };
  }
}

double? _toDouble(dynamic valor) {
  if (valor == null) return null;
  if (valor is num) return valor.toDouble();
  return double.tryParse(valor.toString().replaceAll(',', '.'));
}
