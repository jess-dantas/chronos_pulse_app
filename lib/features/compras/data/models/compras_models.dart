bool validarChaveNfe(String chave) {
  final c = chave.replaceAll(RegExp('[^0-9]'), '');
  if (c.length != 44) return false;

  final base = c.substring(0, 43);
  int soma = 0;
  int peso = 2;
  for (var i = base.length - 1; i >= 0; i--) {
    soma += int.parse(base[i]) * peso;
    peso++;
    if (peso > 9) peso = 2;
  }
  final resto = soma % 11;
  final dv = resto < 2 ? 0 : 11 - resto;
  return dv == int.parse(c[43]);
}

String formatarChaveNfe(String chave) {
  final c = chave.replaceAll(RegExp('[^0-9]'), '');
  if (c.length != 44) return c;
  final sb = StringBuffer();
  for (var i = 0; i < 44; i++) {
    if (i > 0 && i % 4 == 0) sb.write(' ');
    sb.write(c[i]);
  }
  return sb.toString();
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String && value.isNotEmpty) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

String _formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
}

class FornecedorModel {
  final String id;
  final String? tenantId;
  final String cnpj;
  final String razaoSocial;
  final String? nomeFantasia;
  final String? inscricaoEstadual;
  final String? email;
  final String? telefone;
  final String? enderecoLogradouro;
  final String? enderecoNumero;
  final String? enderecoBairro;
  final String? enderecoCidade;
  final String? enderecoUf;
  final String? enderecoCep;
  final String? observacoes;
  final bool ativo;

  FornecedorModel({
    required this.id,
    this.tenantId,
    required this.cnpj,
    required this.razaoSocial,
    this.nomeFantasia,
    this.inscricaoEstadual,
    this.email,
    this.telefone,
    this.enderecoLogradouro,
    this.enderecoNumero,
    this.enderecoBairro,
    this.enderecoCidade,
    this.enderecoUf,
    this.enderecoCep,
    this.observacoes,
    this.ativo = true,
  });

  factory FornecedorModel.fromJson(Map<String, dynamic> json) {
    return FornecedorModel(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString(),
      cnpj: json['cnpj']?.toString() ?? '',
      razaoSocial: json['razaoSocial']?.toString() ?? '',
      nomeFantasia: json['nomeFantasia']?.toString(),
      inscricaoEstadual: json['inscricaoEstadual']?.toString(),
      email: json['email']?.toString(),
      telefone: json['telefone']?.toString(),
      enderecoLogradouro: json['enderecoLogradouro']?.toString(),
      enderecoNumero: json['enderecoNumero']?.toString(),
      enderecoBairro: json['enderecoBairro']?.toString(),
      enderecoCidade: json['enderecoCidade']?.toString(),
      enderecoUf: json['enderecoUf']?.toString(),
      enderecoCep: json['enderecoCep']?.toString(),
      observacoes: json['observacoes']?.toString(),
      ativo: json['ativo'] ?? true,
    );
  }

  String get nomeExibicao =>
      (nomeFantasia != null && nomeFantasia!.isNotEmpty) ? nomeFantasia! : razaoSocial;

  String get cnpjFormatado {
    final c = cnpj.replaceAll(RegExp('[^0-9]'), '');
    if (c.length != 14) return cnpj;
    return '${c.substring(0, 2)}.${c.substring(2, 5)}.${c.substring(5, 8)}/'
        '${c.substring(8, 12)}-${c.substring(12, 14)}';
  }
}

class CadastrarFornecedorDTO {
  final String cnpj;
  final String razaoSocial;
  final String? nomeFantasia;
  final String? inscricaoEstadual;
  final String? email;
  final String? telefone;
  final String? enderecoLogradouro;
  final String? enderecoNumero;
  final String? enderecoBairro;
  final String? enderecoCidade;
  final String? enderecoUf;
  final String? enderecoCep;
  final String? observacoes;

  CadastrarFornecedorDTO({
    required this.cnpj,
    required this.razaoSocial,
    this.nomeFantasia,
    this.inscricaoEstadual,
    this.email,
    this.telefone,
    this.enderecoLogradouro,
    this.enderecoNumero,
    this.enderecoBairro,
    this.enderecoCidade,
    this.enderecoUf,
    this.enderecoCep,
    this.observacoes,
  });

  Map<String, dynamic> toJson() {
    return {
      'cnpj': cnpj.replaceAll(RegExp('[^0-9A-Za-z]'), ''),
      'razaoSocial': razaoSocial,
      'nomeFantasia': nomeFantasia,
      'inscricaoEstadual': inscricaoEstadual,
      'email': email,
      'telefone': telefone,
      'enderecoLogradouro': enderecoLogradouro,
      'enderecoNumero': enderecoNumero,
      'enderecoBairro': enderecoBairro,
      'enderecoCidade': enderecoCidade,
      'enderecoUf': enderecoUf,
      'enderecoCep': enderecoCep,
      'observacoes': observacoes,
    };
  }
}

class AtualizarFornecedorDTO {
  final String? cnpj;
  final String? razaoSocial;
  final String? nomeFantasia;
  final String? inscricaoEstadual;
  final String? email;
  final String? telefone;
  final String? enderecoLogradouro;
  final String? enderecoNumero;
  final String? enderecoBairro;
  final String? enderecoCidade;
  final String? enderecoUf;
  final String? enderecoCep;
  final String? observacoes;
  final bool? ativo;

  AtualizarFornecedorDTO({
    this.cnpj,
    this.razaoSocial,
    this.nomeFantasia,
    this.inscricaoEstadual,
    this.email,
    this.telefone,
    this.enderecoLogradouro,
    this.enderecoNumero,
    this.enderecoBairro,
    this.enderecoCidade,
    this.enderecoUf,
    this.enderecoCep,
    this.observacoes,
    this.ativo,
  });

  Map<String, dynamic> toJson() {
    return {
      if (cnpj != null) 'cnpj': cnpj!.replaceAll(RegExp('[^0-9A-Za-z]'), ''),
      if (razaoSocial != null) 'razaoSocial': razaoSocial,
      if (nomeFantasia != null) 'nomeFantasia': nomeFantasia,
      if (inscricaoEstadual != null) 'inscricaoEstadual': inscricaoEstadual,
      if (email != null) 'email': email,
      if (telefone != null) 'telefone': telefone,
      if (enderecoLogradouro != null) 'enderecoLogradouro': enderecoLogradouro,
      if (enderecoNumero != null) 'enderecoNumero': enderecoNumero,
      if (enderecoBairro != null) 'enderecoBairro': enderecoBairro,
      if (enderecoCidade != null) 'enderecoCidade': enderecoCidade,
      if (enderecoUf != null) 'enderecoUf': enderecoUf,
      if (enderecoCep != null) 'enderecoCep': enderecoCep,
      if (observacoes != null) 'observacoes': observacoes,
      if (ativo != null) 'ativo': ativo,
    };
  }
}

class PedidoCompraItemModel {
  final String id;
  final String materialId;
  final String materialDescricao;
  final String materialUnidadeMedida;
  final double quantidade;
  final double valorUnitario;
  final double valorTotalItem;
  final double quantidadeRecebida;

  PedidoCompraItemModel({
    this.id = '',
    required this.materialId,
    this.materialDescricao = '',
    this.materialUnidadeMedida = '',
    this.quantidade = 0,
    this.valorUnitario = 0,
    this.valorTotalItem = 0,
    this.quantidadeRecebida = 0,
  });

  factory PedidoCompraItemModel.fromJson(Map<String, dynamic> json) {
    return PedidoCompraItemModel(
      id: json['id']?.toString() ?? '',
      materialId: json['materialId']?.toString() ?? '',
      materialDescricao: json['materialDescricao']?.toString() ?? '',
      materialUnidadeMedida: json['materialUnidadeMedida']?.toString() ?? '',
      quantidade: _toDouble(json['quantidade']),
      valorUnitario: _toDouble(json['valorUnitario']),
      valorTotalItem: _toDouble(json['valorTotalItem']),
      quantidadeRecebida: _toDouble(json['quantidadeRecebida']),
    );
  }

  double get quantidadeDisponivel => quantidade - quantidadeRecebida;
}

class PedidoCompraItemDTO {
  final String materialId;
  final double quantidade;
  final double valorUnitario;

  PedidoCompraItemDTO({
    required this.materialId,
    required this.quantidade,
    required this.valorUnitario,
  });

  Map<String, dynamic> toJson() => {
        'materialId': materialId,
        'quantidade': quantidade,
        'valorUnitario': valorUnitario,
      };
}

class CadastrarPedidoCompraDTO {
  final String fornecedorId;
  final String? objeto;
  final String? prazoEntrega;
  final String? contratoId;
  final String? empenhoNumero;
  final String? observacoes;
  final List<PedidoCompraItemDTO> itens;

  CadastrarPedidoCompraDTO({
    required this.fornecedorId,
    this.objeto,
    this.prazoEntrega,
    this.contratoId,
    this.empenhoNumero,
    this.observacoes,
    required this.itens,
  });

  Map<String, dynamic> toJson() => {
        'fornecedorId': fornecedorId,
        if (objeto != null && objeto!.isNotEmpty) 'objeto': objeto,
        if (prazoEntrega != null) 'prazoEntrega': prazoEntrega,
        if (contratoId != null) 'contratoId': contratoId,
        if (empenhoNumero != null && empenhoNumero!.isNotEmpty) 'empenhoNumero': empenhoNumero,
        if (observacoes != null && observacoes!.isNotEmpty) 'observacoes': observacoes,
        'itens': itens.map((e) => e.toJson()).toList(),
      };
}

class PedidoCompraModel {
  final String id;
  final String tenantId;
  final String numero;
  final String fornecedorId;
  final String fornecedorNome;
  final String? objeto;
  final String dataEmissao;
  final String? prazoEntrega;
  final String? contratoId;
  final String? empenhoNumero;
  final double valorTotal;
  final String status;
  final String? observacoes;
  final List<PedidoCompraItemModel> itens;

  PedidoCompraModel({
    this.id = '',
    this.tenantId = '',
    this.numero = '',
    this.fornecedorId = '',
    this.fornecedorNome = '',
    this.objeto,
    this.dataEmissao = '',
    this.prazoEntrega,
    this.contratoId,
    this.empenhoNumero,
    this.valorTotal = 0,
    this.status = '',
    this.observacoes,
    this.itens = const [],
  });

  factory PedidoCompraModel.fromJson(Map<String, dynamic> json) {
    final itensRaw = json['itens'];
    return PedidoCompraModel(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      numero: json['numero']?.toString() ?? '',
      fornecedorId: json['fornecedorId']?.toString() ?? '',
      fornecedorNome: json['fornecedorNome']?.toString() ?? '',
      objeto: json['objeto']?.toString(),
      dataEmissao: json['dataEmissao']?.toString() ?? '',
      prazoEntrega: json['prazoEntrega']?.toString(),
      contratoId: json['contratoId']?.toString(),
      empenhoNumero: json['empenhoNumero']?.toString(),
      valorTotal: _toDouble(json['valorTotal']),
      status: json['status']?.toString() ?? '',
      observacoes: json['observacoes']?.toString(),
      itens: itensRaw is List ? itensRaw.map((e) => PedidoCompraItemModel.fromJson(e)).toList() : const [],
    );
  }

  String get dataEmissaoFormatada => _formatDate(dataEmissao);
  String get prazoEntregaFormatado => _formatDate(prazoEntrega);

  bool get cancelavel => status == 'EMITIDO' || status == 'RECEBIDO_PARCIAL';
}

class ItemNfeDTO {
  final String materialId;
  final double quantidade;

  ItemNfeDTO({required this.materialId, required this.quantidade});

  Map<String, dynamic> toJson() => {
        'materialId': materialId,
        'quantidade': quantidade,
      };
}

class ReceberNfeDTO {
  final String chaveNfe;
  final String? numeroNfe;
  final String? serie;
  final String? dataEmissao;
  final double? valorNota;
  final String? fornecedorId;
  final String pedidoId;
  final String almoxarifadoId;
  final String? tipoTermo;
  final String? numeroTermo;
  final String? observacoes;
  final String? cnpjEmitente;
  final String? razaoEmitente;
  final String? xmlNfe;
  final List<ItemNfeDTO> itens;

  ReceberNfeDTO({
    required this.chaveNfe,
    this.numeroNfe,
    this.serie,
    this.dataEmissao,
    this.valorNota,
    this.fornecedorId,
    required this.pedidoId,
    required this.almoxarifadoId,
    this.tipoTermo,
    this.numeroTermo,
    this.observacoes,
    this.cnpjEmitente,
    this.razaoEmitente,
    this.xmlNfe,
    required this.itens,
  });

  Map<String, dynamic> toJson() => {
        'chaveNfe': chaveNfe.replaceAll(RegExp('[^0-9]'), ''),
        if (numeroNfe != null && numeroNfe!.isNotEmpty) 'numeroNfe': numeroNfe,
        if (serie != null && serie!.isNotEmpty) 'serie': serie,
        if (dataEmissao != null) 'dataEmissao': dataEmissao,
        if (valorNota != null) 'valorNota': valorNota,
        if (fornecedorId != null) 'fornecedorId': fornecedorId,
        'pedidoId': pedidoId,
        'almoxarifadoId': almoxarifadoId,
        if (tipoTermo != null && tipoTermo!.isNotEmpty) 'tipoTermo': tipoTermo,
        if (numeroTermo != null && numeroTermo!.isNotEmpty) 'numeroTermo': numeroTermo,
        if (observacoes != null && observacoes!.isNotEmpty) 'observacoes': observacoes,
        if (cnpjEmitente != null && cnpjEmitente!.isNotEmpty) 'cnpjEmitente': cnpjEmitente,
        if (razaoEmitente != null && razaoEmitente!.isNotEmpty) 'razaoEmitente': razaoEmitente,
        if (xmlNfe != null && xmlNfe!.isNotEmpty) 'xmlNfe': xmlNfe,
        'itens': itens.map((e) => e.toJson()).toList(),
      };
}

class EntradaNfeModel {
  final String id;
  final String tenantId;
  final String chaveNfe;
  final String? numeroNfe;
  final String? serie;
  final String? dataEmissao;
  final double? valorNota;
  final String? fornecedorId;
  final String pedidoId;
  final String pedidoNumero;
  final String? contratoId;
  final String? empenhoNumero;
  final String almoxarifadoId;
  final String tipoTermo;
  final String? numeroTermo;
  final String? cnpjEmitente;
  final String? razaoEmitente;
  final String? observacoes;
  final String? criadoEm;

  EntradaNfeModel({
    this.id = '',
    this.tenantId = '',
    this.chaveNfe = '',
    this.numeroNfe,
    this.serie,
    this.dataEmissao,
    this.valorNota,
    this.fornecedorId,
    this.pedidoId = '',
    this.pedidoNumero = '',
    this.contratoId,
    this.empenhoNumero,
    this.almoxarifadoId = '',
    this.tipoTermo = '',
    this.numeroTermo,
    this.cnpjEmitente,
    this.razaoEmitente,
    this.observacoes,
    this.criadoEm,
  });

  factory EntradaNfeModel.fromJson(Map<String, dynamic> json) {
    return EntradaNfeModel(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      chaveNfe: json['chaveNfe']?.toString() ?? '',
      numeroNfe: json['numeroNfe']?.toString(),
      serie: json['serie']?.toString(),
      dataEmissao: json['dataEmissao']?.toString(),
      valorNota: json['valorNota'] != null ? _toDouble(json['valorNota']) : null,
      fornecedorId: json['fornecedorId']?.toString(),
      pedidoId: json['pedidoId']?.toString() ?? '',
      pedidoNumero: json['pedidoNumero']?.toString() ?? '',
      contratoId: json['contratoId']?.toString(),
      empenhoNumero: json['empenhoNumero']?.toString(),
      almoxarifadoId: json['almoxarifadoId']?.toString() ?? '',
      tipoTermo: json['tipoTermo']?.toString() ?? '',
      numeroTermo: json['numeroTermo']?.toString(),
      cnpjEmitente: json['cnpjEmitente']?.toString(),
      razaoEmitente: json['razaoEmitente']?.toString(),
      observacoes: json['observacoes']?.toString(),
      criadoEm: json['criadoEm']?.toString(),
    );
  }

  String get dataEmissaoFormatada => _formatDate(dataEmissao);
}

class PrecoConsultaModel {
  final String materialId;
  final String materialDescricao;
  final String unidadeMedida;
  final String? ultimaCompraEm;
  final double ultimoValorUnitario;
  final double valorMedioUnitario;
  final int totalEntradas;

  PrecoConsultaModel({
    this.materialId = '',
    this.materialDescricao = '',
    this.unidadeMedida = '',
    this.ultimaCompraEm,
    this.ultimoValorUnitario = 0,
    this.valorMedioUnitario = 0,
    this.totalEntradas = 0,
  });

  factory PrecoConsultaModel.fromJson(Map<String, dynamic> json) {
    return PrecoConsultaModel(
      materialId: json['materialId']?.toString() ?? '',
      materialDescricao: json['materialDescricao']?.toString() ?? '',
      unidadeMedida: json['unidadeMedida']?.toString() ?? '',
      ultimaCompraEm: json['ultimaCompraEm']?.toString(),
      ultimoValorUnitario: _toDouble(json['ultimoValorUnitario']),
      valorMedioUnitario: _toDouble(json['valorMedioUnitario']),
      totalEntradas: (json['totalEntradas'] as num?)?.toInt() ?? 0,
    );
  }

  String get ultimaCompraEmFormatada => _formatDate(ultimaCompraEm);
}

String _labelStatusRequisicao(String? status) {
  switch (status) {
    case 'EM_ABERTO':
      return 'Em aberto';
    case 'COTADA':
      return 'Cotada';
    case 'CANCELADA':
      return 'Cancelada';
    default:
      return status ?? '';
  }
}

String _labelStatusCotacao(String? status) {
  switch (status) {
    case 'EM_ANDAMENTO':
      return 'Em andamento';
    case 'CONCLUIDA':
      return 'Concluída';
    case 'CANCELADA':
      return 'Cancelada';
    default:
      return status ?? '';
  }
}

class RequisicaoItemModel {
  final String id;
  final String materialId;
  final String materialDescricao;
  final String materialUnidadeMedida;
  final double quantidade;
  final String? observacao;

  RequisicaoItemModel({
    this.id = '',
    this.materialId = '',
    this.materialDescricao = '',
    this.materialUnidadeMedida = '',
    this.quantidade = 0,
    this.observacao,
  });

  factory RequisicaoItemModel.fromJson(Map<String, dynamic> json) {
    return RequisicaoItemModel(
      id: json['id']?.toString() ?? '',
      materialId: json['materialId']?.toString() ?? '',
      materialDescricao: json['materialDescricao']?.toString() ?? '',
      materialUnidadeMedida: json['materialUnidadeMedida']?.toString() ?? '',
      quantidade: _toDouble(json['quantidade']),
      observacao: json['observacao']?.toString(),
    );
  }
}

class RequisicaoItemDTO {
  final String materialId;
  final double quantidade;
  final String? observacao;

  RequisicaoItemDTO({
    required this.materialId,
    required this.quantidade,
    this.observacao,
  });

  Map<String, dynamic> toJson() => {
        'materialId': materialId,
        'quantidade': quantidade,
        if (observacao != null && observacao!.isNotEmpty) 'observacao': observacao,
      };
}

class CadastrarRequisicaoDTO {
  final String solicitanteCpcId;
  final String justificativa;
  final String? observacoes;
  final List<RequisicaoItemDTO> itens;

  CadastrarRequisicaoDTO({
    required this.solicitanteCpcId,
    required this.justificativa,
    this.observacoes,
    required this.itens,
  });

  Map<String, dynamic> toJson() => {
        'solicitanteCpcId': solicitanteCpcId,
        'justificativa': justificativa,
        if (observacoes != null && observacoes!.isNotEmpty) 'observacoes': observacoes,
        'itens': itens.map((e) => e.toJson()).toList(),
      };
}

class RequisicaoCompraModel {
  final String id;
  final String tenantId;
  final String numero;
  final String solicitanteCpcId;
  final String solicitanteNome;
  final String justificativa;
  final String dataRequisicao;
  final String? observacoes;
  final String status;
  final List<RequisicaoItemModel> itens;
  final String? criadoEm;

  RequisicaoCompraModel({
    this.id = '',
    this.tenantId = '',
    this.numero = '',
    this.solicitanteCpcId = '',
    this.solicitanteNome = '',
    this.justificativa = '',
    this.dataRequisicao = '',
    this.observacoes,
    this.status = '',
    this.itens = const [],
    this.criadoEm,
  });

  factory RequisicaoCompraModel.fromJson(Map<String, dynamic> json) {
    final itensRaw = json['itens'];
    return RequisicaoCompraModel(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      numero: json['numero']?.toString() ?? '',
      solicitanteCpcId: json['solicitanteCpcId']?.toString() ?? '',
      solicitanteNome: json['solicitanteNome']?.toString() ?? '',
      justificativa: json['justificativa']?.toString() ?? '',
      dataRequisicao: json['dataRequisicao']?.toString() ?? '',
      observacoes: json['observacoes']?.toString(),
      status: json['status']?.toString() ?? '',
      itens: itensRaw is List ? itensRaw.map((e) => RequisicaoItemModel.fromJson(e)).toList() : const [],
      criadoEm: json['criadoEm']?.toString(),
    );
  }

  String get statusLabel => _labelStatusRequisicao(status);
  String get dataRequisicaoFormatada => _formatDate(dataRequisicao);
  bool get cancelavel => status == 'EM_ABERTO';
  bool get cotavel => status == 'EM_ABERTO';
}

class FornecedorCotacaoModel {
  final String fornecedorId;
  final String razaoSocial;

  FornecedorCotacaoModel({
    this.fornecedorId = '',
    this.razaoSocial = '',
  });

  factory FornecedorCotacaoModel.fromJson(Map<String, dynamic> json) {
    return FornecedorCotacaoModel(
      fornecedorId: json['fornecedorId']?.toString() ?? '',
      razaoSocial: json['razaoSocial']?.toString() ?? '',
    );
  }
}

class PropostaModel {
  final String id;
  final String fornecedorId;
  final String fornecedorNome;
  final String materialId;
  final String materialDescricao;
  final double valorUnitario;
  final bool? vencedor;

  PropostaModel({
    this.id = '',
    this.fornecedorId = '',
    this.fornecedorNome = '',
    this.materialId = '',
    this.materialDescricao = '',
    this.valorUnitario = 0,
    this.vencedor,
  });

  factory PropostaModel.fromJson(Map<String, dynamic> json) {
    return PropostaModel(
      id: json['id']?.toString() ?? '',
      fornecedorId: json['fornecedorId']?.toString() ?? '',
      fornecedorNome: json['fornecedorNome']?.toString() ?? '',
      materialId: json['materialId']?.toString() ?? '',
      materialDescricao: json['materialDescricao']?.toString() ?? '',
      valorUnitario: _toDouble(json['valorUnitario']),
      vencedor: json['vencedor'],
    );
  }
}

class CotacaoCompraModel {
  final String id;
  final String tenantId;
  final String numero;
  final String requisicaoId;
  final String requisicaoNumero;
  final String? dataLimite;
  final String? observacoes;
  final String status;
  final bool pedidoGerado;
  final List<FornecedorCotacaoModel> fornecedores;
  final List<PropostaModel> propostas;
  final String? criadoEm;

  CotacaoCompraModel({
    this.id = '',
    this.tenantId = '',
    this.numero = '',
    this.requisicaoId = '',
    this.requisicaoNumero = '',
    this.dataLimite,
    this.observacoes,
    this.status = '',
    this.pedidoGerado = false,
    this.fornecedores = const [],
    this.propostas = const [],
    this.criadoEm,
  });

  factory CotacaoCompraModel.fromJson(Map<String, dynamic> json) {
    final fornecedoresRaw = json['fornecedores'];
    final propostasRaw = json['propostas'];
    return CotacaoCompraModel(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      numero: json['numero']?.toString() ?? '',
      requisicaoId: json['requisicaoId']?.toString() ?? '',
      requisicaoNumero: json['requisicaoNumero']?.toString() ?? '',
      dataLimite: json['dataLimite']?.toString(),
      observacoes: json['observacoes']?.toString(),
      status: json['status']?.toString() ?? '',
      pedidoGerado: json['pedidoGerado'] ?? false,
      fornecedores: fornecedoresRaw is List
          ? fornecedoresRaw.map((e) => FornecedorCotacaoModel.fromJson(e)).toList()
          : const [],
      propostas: propostasRaw is List
          ? propostasRaw.map((e) => PropostaModel.fromJson(e)).toList()
          : const [],
      criadoEm: json['criadoEm']?.toString(),
    );
  }

  String get statusLabel => _labelStatusCotacao(status);
  String get dataLimiteFormatada => _formatDate(dataLimite);

  bool get emAndamento => status == 'EM_ANDAMENTO';
  bool get concluida => status == 'CONCLUIDA';
  bool get podeGerarPedidos => concluida && !pedidoGerado;
}

class CadastrarCotacaoDTO {
  final String requisicaoId;
  final List<String> fornecedoresIds;
  final String? dataLimite;
  final String? observacoes;

  CadastrarCotacaoDTO({
    required this.requisicaoId,
    required this.fornecedoresIds,
    this.dataLimite,
    this.observacoes,
  });

  Map<String, dynamic> toJson() => {
        'requisicaoId': requisicaoId,
        'fornecedoresIds': fornecedoresIds,
        if (dataLimite != null && dataLimite!.isNotEmpty) 'dataLimite': dataLimite,
        if (observacoes != null && observacoes!.isNotEmpty) 'observacoes': observacoes,
      };
}

class PropostaItemDTO {
  final String materialId;
  final double valorUnitario;

  PropostaItemDTO({
    required this.materialId,
    required this.valorUnitario,
  });

  Map<String, dynamic> toJson() => {
        'materialId': materialId,
        'valorUnitario': valorUnitario,
      };
}

class RegistrarPropostasDTO {
  final String fornecedorId;
  final List<PropostaItemDTO> itens;

  RegistrarPropostasDTO({
    required this.fornecedorId,
    required this.itens,
  });

  Map<String, dynamic> toJson() => {
        'fornecedorId': fornecedorId,
        'itens': itens.map((e) => e.toJson()).toList(),
      };
}

class NfeImportadoItemModel {
  final int? numeroItem;
  final String? codigoProduto;
  final String? descricao;
  final String? ncm;
  final String? cfop;
  final String? unidadeComercial;
  final double quantidadeComercial;
  final double valorUnitarioComercial;
  final double valorTotalProduto;

  NfeImportadoItemModel({
    this.numeroItem,
    this.codigoProduto,
    this.descricao,
    this.ncm,
    this.cfop,
    this.unidadeComercial,
    this.quantidadeComercial = 0,
    this.valorUnitarioComercial = 0,
    this.valorTotalProduto = 0,
  });

  factory NfeImportadoItemModel.fromJson(Map<String, dynamic> json) {
    return NfeImportadoItemModel(
      numeroItem: json['numeroItem'] != null ? int.tryParse('${json['numeroItem']}') : null,
      codigoProduto: json['codigoProduto']?.toString(),
      descricao: json['descricao']?.toString(),
      ncm: json['ncm']?.toString(),
      cfop: json['cfop']?.toString(),
      unidadeComercial: json['unidadeComercial']?.toString(),
      quantidadeComercial: _toDouble(json['quantidadeComercial']),
      valorUnitarioComercial: _toDouble(json['valorUnitarioComercial']),
      valorTotalProduto: _toDouble(json['valorTotalProduto']),
    );
  }
}

class NfeImportadoModel {
  final String chaveNfe;
  final String? numero;
  final String? serie;
  final String? dataEmissao;
  final double? valorNota;
  final String? cnpjEmitente;
  final String? razaoEmitente;
  final String origem;
  final List<NfeImportadoItemModel> itens;

  NfeImportadoModel({
    this.chaveNfe = '',
    this.numero,
    this.serie,
    this.dataEmissao,
    this.valorNota,
    this.cnpjEmitente,
    this.razaoEmitente,
    this.origem = 'XML',
    this.itens = const [],
  });

  factory NfeImportadoModel.fromJson(Map<String, dynamic> json) {
    final itensRaw = json['itens'];
    return NfeImportadoModel(
      chaveNfe: json['chaveNfe']?.toString() ?? '',
      numero: json['numero']?.toString(),
      serie: json['serie']?.toString(),
      dataEmissao: json['dataEmissao']?.toString(),
      valorNota: json['valorNota'] != null ? _toDouble(json['valorNota']) : null,
      cnpjEmitente: json['cnpjEmitente']?.toString(),
      razaoEmitente: json['razaoEmitente']?.toString(),
      origem: json['origem']?.toString() ?? 'XML',
      itens: itensRaw is List
          ? itensRaw.map((e) => NfeImportadoItemModel.fromJson(e)).toList()
          : const [],
    );
  }

  int get totalItens => itens.length;
}