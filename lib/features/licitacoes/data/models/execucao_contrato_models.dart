import 'dart:ui';

double _toDoubleExec(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String && value.isNotEmpty) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

String _formatDateExec(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  return '${parsed.day.toString().padLeft(2, '0')}/'
      '${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
}

class ContratoAditivoModel {
  final String id;
  final String tipo;
  final String descricao;
  final String? justificativa;
  final int? prazoAdicionadoDias;
  final double? novoValorTotal;
  final bool aprovado;
  final String? criadoEm;

  ContratoAditivoModel({
    this.id = '',
    this.tipo = '',
    this.descricao = '',
    this.justificativa,
    this.prazoAdicionadoDias,
    this.novoValorTotal,
    this.aprovado = false,
    this.criadoEm,
  });

  factory ContratoAditivoModel.fromJson(Map<String, dynamic> json) {
    return ContratoAditivoModel(
      id: json['id']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      justificativa: json['justificativa']?.toString(),
      prazoAdicionadoDias: json['prazoAdicionadoDias'] is int
          ? json['prazoAdicionadoDias'] as int
          : null,
      novoValorTotal: json['novoValorTotal'] != null
          ? _toDoubleExec(json['novoValorTotal'])
          : null,
      aprovado: json['aprovado'] == true,
      criadoEm: json['criadoEm']?.toString(),
    );
  }

  String get tipoLabel => 'Aditivo de ${_tipoAditivo(tipo)}';
  String get criadoEmFormatado => _formatDateExec(criadoEm);

  String _tipoAditivo(String t) {
    switch (t) {
      case 'VALOR':
        return 'valor';
      case 'PRAZO':
        return 'prazo';
      case 'QUANTITATIVO':
        return 'quantitativo';
      case 'OBJETO':
        return 'objeto';
      default:
        return t.toLowerCase();
    }
  }
}

class ContratoApontamentoModel {
  final String id;
  final String fiscal;
  final String descricao;
  final String gravidade;
  final bool resolvido;
  final String? resolvidoEm;
  final String? criadoEm;

  ContratoApontamentoModel({
    this.id = '',
    this.fiscal = '',
    this.descricao = '',
    this.gravidade = 'MEDIA',
    this.resolvido = false,
    this.resolvidoEm,
    this.criadoEm,
  });

  factory ContratoApontamentoModel.fromJson(Map<String, dynamic> json) {
    return ContratoApontamentoModel(
      id: json['id']?.toString() ?? '',
      fiscal: json['fiscal']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      gravidade: json['gravidade']?.toString() ?? 'MEDIA',
      resolvido: json['resolvido'] == true,
      resolvidoEm: json['resolvidoEm']?.toString(),
      criadoEm: json['criadoEm']?.toString(),
    );
  }

  String get gravidadeLabel => _gravidadeLabel(gravidade);
  String get criadoEmFormatado => _formatDateExec(criadoEm);

  Color get gravidadeCor {
    switch (gravidade) {
      case 'GRAVE':
        return const Color(0xFFD32F2F);
      case 'LEVE':
        return const Color(0xFF2E7D32);
      default:
        return const Color(0xFFF9A825);
    }
  }
}

class ContratoMedicaoModel {
  final String id;
  final String periodo;
  final double valorMedido;
  final double valorPago;
  final String? pagoEm;
  final String? observacao;
  final String? criadoEm;

  ContratoMedicaoModel({
    this.id = '',
    this.periodo = '',
    this.valorMedido = 0.0,
    this.valorPago = 0.0,
    this.pagoEm,
    this.observacao,
    this.criadoEm,
  });

  factory ContratoMedicaoModel.fromJson(Map<String, dynamic> json) {
    return ContratoMedicaoModel(
      id: json['id']?.toString() ?? '',
      periodo: json['periodo']?.toString() ?? '',
      valorMedido: _toDoubleExec(json['valorMedido']),
      valorPago: _toDoubleExec(json['valorPago']),
      pagoEm: json['pagoEm']?.toString(),
      observacao: json['observacao']?.toString(),
      criadoEm: json['criadoEm']?.toString(),
    );
  }

  String get pagoEmFormatado => _formatDateExec(pagoEm);
}

class ContratoSancaoModel {
  final String id;
  final String tipo;
  final String? baseLegal;
  final String descricao;
  final double? percentualMulta;
  final double? valorMulta;
  final String? aplicadaEm;
  final String? criadoEm;

  ContratoSancaoModel({
    this.id = '',
    this.tipo = '',
    this.baseLegal,
    this.descricao = '',
    this.percentualMulta,
    this.valorMulta,
    this.aplicadaEm,
    this.criadoEm,
  });

  factory ContratoSancaoModel.fromJson(Map<String, dynamic> json) {
    return ContratoSancaoModel(
      id: json['id']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? '',
      baseLegal: json['baseLegal']?.toString(),
      descricao: json['descricao']?.toString() ?? '',
      percentualMulta: json['percentualMulta'] != null
          ? _toDoubleExec(json['percentualMulta'])
          : null,
      valorMulta:
          json['valorMulta'] != null ? _toDoubleExec(json['valorMulta']) : null,
      aplicadaEm: json['aplicadaEm']?.toString(),
      criadoEm: json['criadoEm']?.toString(),
    );
  }

  String get tipoLabel => _labelSancao(tipo);
  String get aplicadaEmFormatado => _formatDateExec(aplicadaEm);
}

class ContratoRescisaoModel {
  final String id;
  final String tipo;
  final String motivo;
  final String? dataRescisao;
  final String? criadoEm;

  ContratoRescisaoModel({
    this.id = '',
    this.tipo = '',
    this.motivo = '',
    this.dataRescisao,
    this.criadoEm,
  });

  factory ContratoRescisaoModel.fromJson(Map<String, dynamic> json) {
    return ContratoRescisaoModel(
      id: json['id']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? '',
      motivo: json['motivo']?.toString() ?? '',
      dataRescisao: json['dataRescisao']?.toString(),
      criadoEm: json['criadoEm']?.toString(),
    );
  }

  String get tipoLabel => _labelRescisao(tipo);
  String get dataRescisaoFormatada => _formatDateExec(dataRescisao);
}

class ContratoExecucaoModel {
  final String id;
  final String numero;
  final String objeto;
  final String? dataInicio;
  final String? dataFim;
  final double valorMensal;
  final double valorTotal;
  final double valorEmpenhado;
  final double valorLiquidado;
  final String? empenhoNumero;
  final String status;
  final String situacao;
  final int diasParaVencimento;
  final bool atrasado;
  final String? observacoes;
  final String? licitacaoId;
  final List<ContratoAditivoModel> aditivos;
  final List<ContratoApontamentoModel> apontamentos;
  final List<ContratoMedicaoModel> medicoes;
  final List<ContratoSancaoModel> sancoes;
  final ContratoRescisaoModel? rescisao;

  ContratoExecucaoModel({
    this.id = '',
    this.numero = '',
    this.objeto = '',
    this.dataInicio,
    this.dataFim,
    this.valorMensal = 0.0,
    this.valorTotal = 0.0,
    this.valorEmpenhado = 0.0,
    this.valorLiquidado = 0.0,
    this.empenhoNumero,
    this.status = '',
    this.situacao = '',
    this.diasParaVencimento = 0,
    this.atrasado = false,
    this.observacoes,
    this.licitacaoId,
    this.aditivos = const [],
    this.apontamentos = const [],
    this.medicoes = const [],
    this.sancoes = const [],
    this.rescisao,
  });

  factory ContratoExecucaoModel.fromJson(Map<String, dynamic> json) {
    final aditivosRaw = json['aditivos'];
    final apontamentosRaw = json['apontamentos'];
    final medicoesRaw = json['medicoes'];
    final sancoesRaw = json['sancoes'];
    final rescisaoRaw = json['rescisao'];
    return ContratoExecucaoModel(
      id: json['id']?.toString() ?? '',
      numero: json['numero']?.toString() ?? '',
      objeto: json['objeto']?.toString() ?? '',
      dataInicio: json['dataInicio']?.toString(),
      dataFim: json['dataFim']?.toString(),
      valorMensal: _toDoubleExec(json['valorMensal']),
      valorTotal: _toDoubleExec(json['valorTotal']),
      valorEmpenhado: _toDoubleExec(json['valorEmpenhado']),
      valorLiquidado: _toDoubleExec(json['valorLiquidado']),
      empenhoNumero: json['empenhoNumero']?.toString(),
      status: json['status']?.toString() ?? '',
      situacao: json['situacao']?.toString() ?? '',
      diasParaVencimento: json['diasParaVencimento'] is int
          ? json['diasParaVencimento'] as int
          : 0,
      atrasado: json['atrasado'] == true,
      observacoes: json['observacoes']?.toString(),
      licitacaoId: json['licitacaoId']?.toString(),
      aditivos: aditivosRaw is List
          ? aditivosRaw.map((e) => ContratoAditivoModel.fromJson(e)).toList()
          : const [],
      apontamentos: apontamentosRaw is List
          ? apontamentosRaw
              .map((e) => ContratoApontamentoModel.fromJson(e))
              .toList()
          : const [],
      medicoes: medicoesRaw is List
          ? medicoesRaw.map((e) => ContratoMedicaoModel.fromJson(e)).toList()
          : const [],
      sancoes: sancoesRaw is List
          ? sancoesRaw.map((e) => ContratoSancaoModel.fromJson(e)).toList()
          : const [],
      rescisao: rescisaoRaw is Map<String, dynamic>
          ? ContratoRescisaoModel.fromJson(rescisaoRaw)
          : null,
    );
  }

  String get dataInicioFormatada => _formatDateExec(dataInicio);
  String get dataFimFormatada => _formatDateExec(dataFim);

  String get situacaoLabel => _labelSituacao(situacao);
  bool get rescindido => status == 'RESCINDIDO';
  bool get vencido => situacao == 'VENCIDO';

  double get valorMedidoTotal =>
      medicoes.fold(0.0, (acc, m) => acc + m.valorMedido);
  double get valorPagoTotal => medicoes.fold(0.0, (acc, m) => acc + m.valorPago);

  int get apontamentosAbertos =>
      apontamentos.where((a) => !a.resolvido).length;
}

class AdicionarAditivoDTO {
  final String tipo;
  final String descricao;
  final String? justificativa;
  final int? prazoAdicionadoDias;
  final double? novoValorTotal;

  AdicionarAditivoDTO({
    required this.tipo,
    required this.descricao,
    this.justificativa,
    this.prazoAdicionadoDias,
    this.novoValorTotal,
  });

  Map<String, dynamic> toJson() => {
        'tipo': tipo,
        'descricao': descricao,
        if (justificativa != null && justificativa!.isNotEmpty)
          'justificativa': justificativa,
        if (prazoAdicionadoDias != null) 'prazoAdicionadoDias': prazoAdicionadoDias,
        if (novoValorTotal != null) 'novoValorTotal': novoValorTotal,
      };
}

class AdicionarApontamentoDTO {
  final String fiscal;
  final String descricao;
  final String gravidade;

  AdicionarApontamentoDTO({
    required this.fiscal,
    required this.descricao,
    this.gravidade = 'MEDIA',
  });

  Map<String, dynamic> toJson() => {
        'fiscal': fiscal,
        'descricao': descricao,
        'gravidade': gravidade,
      };
}

class RegistrarMedicaoDTO {
  final String periodo;
  final double valorMedido;
  final double valorPago;
  final String? pagoEm;
  final String? observacao;

  RegistrarMedicaoDTO({
    required this.periodo,
    this.valorMedido = 0.0,
    this.valorPago = 0.0,
    this.pagoEm,
    this.observacao,
  });

  Map<String, dynamic> toJson() => {
        'periodo': periodo,
        'valorMedido': valorMedido,
        'valorPago': valorPago,
        if (pagoEm != null && pagoEm!.isNotEmpty) 'pagoEm': pagoEm,
        if (observacao != null && observacao!.isNotEmpty)
          'observacao': observacao,
      };
}

class AdicionarSancaoDTO {
  final String tipo;
  final String? baseLegal;
  final String descricao;
  final double? percentualMulta;
  final double? valorMulta;
  final String aplicadaEm;

  AdicionarSancaoDTO({
    required this.tipo,
    this.baseLegal,
    required this.descricao,
    this.percentualMulta,
    this.valorMulta,
    required this.aplicadaEm,
  });

  Map<String, dynamic> toJson() => {
        'tipo': tipo,
        if (baseLegal != null && baseLegal!.isNotEmpty) 'baseLegal': baseLegal,
        'descricao': descricao,
        if (percentualMulta != null) 'percentualMulta': percentualMulta,
        if (valorMulta != null) 'valorMulta': valorMulta,
        'aplicadaEm': aplicadaEm,
      };
}

class RescindirContratoDTO {
  final String tipo;
  final String motivo;
  final String dataRescisao;

  RescindirContratoDTO({
    required this.tipo,
    required this.motivo,
    required this.dataRescisao,
  });

  Map<String, dynamic> toJson() => {
        'tipo': tipo,
        'motivo': motivo,
        'dataRescisao': dataRescisao,
      };
}

String _gravidadeLabel(String g) {
  switch (g) {
    case 'GRAVE':
      return 'Grave';
    case 'LEVE':
      return 'Leve';
    default:
      return 'Média';
  }
}

String _labelSituacao(String s) {
  switch (s) {
    case 'VIGENTE':
      return 'Vigente';
    case 'EXPIRANDO':
      return 'Próximo do vencimento';
    case 'VENCIDO':
      return 'Vencido';
    case 'RESCINDIDO':
      return 'Rescindido';
    default:
      return s;
  }
}

String _labelSancao(String t) {
  switch (t) {
    case 'ADVERTENCIA':
      return 'Advertência';
    case 'MULTA':
      return 'Multa';
    case 'SUSPENSAO_TEMPORARIA':
      return 'Suspensão temporária';
    case 'IMPEDIMENTO':
      return 'Impedimento de licitar';
    case 'DECLARACAO_INIDONEIDADE':
      return 'Declaração de inidoneidade';
    default:
      return t;
  }
}

String _labelRescisao(String t) {
  switch (t) {
    case 'UNILATERAL':
      return 'Unilateral';
    case 'AMIGAVEL':
      return 'Amigável';
    case 'JUDICIAL':
      return 'Judicial';
    default:
      return t;
  }
}