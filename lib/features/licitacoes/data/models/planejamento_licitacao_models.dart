double _toDoublePlane(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String && value.isNotEmpty) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class EtpModel {
  final String id;
  final String objeto;
  final String justificativa;
  final String requisitos;
  final String alternativas;
  final double? valorEstimado;
  final String riscos;
  final String conclusao;
  final String responsavel;
  final String status;
  final String? dataAprovacao;

  EtpModel({
    this.id = '',
    this.objeto = '',
    this.justificativa = '',
    this.requisitos = '',
    this.alternativas = '',
    this.valorEstimado,
    this.riscos = '',
    this.conclusao = '',
    this.responsavel = '',
    this.status = 'RASCUNHO',
    this.dataAprovacao,
  });

  factory EtpModel.fromJson(Map<String, dynamic> json) {
    return EtpModel(
      id: json['id']?.toString() ?? '',
      objeto: json['objeto']?.toString() ?? '',
      justificativa: json['justificativa']?.toString() ?? '',
      requisitos: json['requisitos']?.toString() ?? '',
      alternativas: json['alternativas']?.toString() ?? '',
      valorEstimado: json['valorEstimado'] != null
          ? _toDoublePlane(json['valorEstimado'])
          : null,
      riscos: json['riscos']?.toString() ?? '',
      conclusao: json['conclusao']?.toString() ?? '',
      responsavel: json['responsavel']?.toString() ?? '',
      status: json['status']?.toString() ?? 'RASCUNHO',
      dataAprovacao: json['dataAprovacao']?.toString(),
    );
  }

  bool get aprovado => status == 'APROVADO';
  String get statusLabel => aprovado ? 'Aprovado' : 'Rascunho';
}

class TrModel {
  final String id;
  final String especificacoes;
  final String condicoesFornecimento;
  final String obrigacoes;
  final String criteriosAceitacao;
  final String prazosEntrega;
  final String garantia;
  final String formaPagamento;
  final String responsavel;
  final String status;
  final String? dataAprovacao;

  TrModel({
    this.id = '',
    this.especificacoes = '',
    this.condicoesFornecimento = '',
    this.obrigacoes = '',
    this.criteriosAceitacao = '',
    this.prazosEntrega = '',
    this.garantia = '',
    this.formaPagamento = '',
    this.responsavel = '',
    this.status = 'RASCUNHO',
    this.dataAprovacao,
  });

  factory TrModel.fromJson(Map<String, dynamic> json) {
    return TrModel(
      id: json['id']?.toString() ?? '',
      especificacoes: json['especificacoes']?.toString() ?? '',
      condicoesFornecimento: json['condicoesFornecimento']?.toString() ?? '',
      obrigacoes: json['obrigacoes']?.toString() ?? '',
      criteriosAceitacao: json['criteriosAceitacao']?.toString() ?? '',
      prazosEntrega: json['prazosEntrega']?.toString() ?? '',
      garantia: json['garantia']?.toString() ?? '',
      formaPagamento: json['formaPagamento']?.toString() ?? '',
      responsavel: json['responsavel']?.toString() ?? '',
      status: json['status']?.toString() ?? 'RASCUNHO',
      dataAprovacao: json['dataAprovacao']?.toString(),
    );
  }

  bool get aprovado => status == 'APROVADO';
  String get statusLabel => aprovado ? 'Aprovado' : 'Rascunho';
}

class EditalModel {
  final String id;
  final String numeroProcesso;
  final String numeroEdital;
  final String localSessao;
  final String? dataAberturaSessao;
  final String? horarioAbertura;
  final String formaEntregaPropostas;
  final String anexos;
  final String observacoes;
  final String status;
  final String? dataPublicacao;

  EditalModel({
    this.id = '',
    this.numeroProcesso = '',
    this.numeroEdital = '',
    this.localSessao = '',
    this.dataAberturaSessao,
    this.horarioAbertura,
    this.formaEntregaPropostas = '',
    this.anexos = '',
    this.observacoes = '',
    this.status = 'EM_ELABORACAO',
    this.dataPublicacao,
  });

  factory EditalModel.fromJson(Map<String, dynamic> json) {
    return EditalModel(
      id: json['id']?.toString() ?? '',
      numeroProcesso: json['numeroProcesso']?.toString() ?? '',
      numeroEdital: json['numeroEdital']?.toString() ?? '',
      localSessao: json['localSessao']?.toString() ?? '',
      dataAberturaSessao: json['dataAberturaSessao']?.toString(),
      horarioAbertura: json['horarioAbertura']?.toString(),
      formaEntregaPropostas: json['formaEntregaPropostas']?.toString() ?? '',
      anexos: json['anexos']?.toString() ?? '',
      observacoes: json['observacoes']?.toString() ?? '',
      status: json['status']?.toString() ?? 'EM_ELABORACAO',
      dataPublicacao: json['dataPublicacao']?.toString(),
    );
  }

  bool get publicado => status == 'PUBLICADO';
  String get statusLabel => publicado ? 'Publicado' : 'Em elaboração';

  String get formaEntregaLabel {
    switch (formaEntregaPropostas) {
      case 'PRESENCIAL':
        return 'Presencial';
      case 'ELETRONICA':
        return 'Eletrônica';
      default:
        return formaEntregaPropostas;
    }
  }

  String get dataSessaoFormatada => _formatDatePlane(dataAberturaSessao);
}

class PlanejamentoLicitacaoModel {
  final String licitacaoId;
  final String numero;
  final String licitacaoStatus;
  final EtpModel? etp;
  final TrModel? tr;
  final EditalModel? edital;

  PlanejamentoLicitacaoModel({
    required this.licitacaoId,
    required this.numero,
    required this.licitacaoStatus,
    this.etp,
    this.tr,
    this.edital,
  });

  factory PlanejamentoLicitacaoModel.fromJson(Map<String, dynamic> json) {
    final etpRaw = json['etp'];
    final trRaw = json['tr'];
    final editalRaw = json['edital'];
    return PlanejamentoLicitacaoModel(
      licitacaoId: json['licitacaoId']?.toString() ?? '',
      numero: json['numero']?.toString() ?? '',
      licitacaoStatus: json['licitacaoStatus']?.toString() ?? '',
      etp: etpRaw is Map<String, dynamic> ? EtpModel.fromJson(etpRaw) : null,
      tr: trRaw is Map<String, dynamic> ? TrModel.fromJson(trRaw) : null,
      edital: editalRaw is Map<String, dynamic>
          ? EditalModel.fromJson(editalRaw)
          : null,
    );
  }
}

class EtpDTO {
  final String objeto;
  final String justificativa;
  final String requisitos;
  final String? alternativas;
  final double? valorEstimado;
  final String? riscos;
  final String? conclusao;

  EtpDTO({
    required this.objeto,
    required this.justificativa,
    required this.requisitos,
    this.alternativas,
    this.valorEstimado,
    this.riscos,
    this.conclusao,
  });

  Map<String, dynamic> toJson() => {
        'objeto': objeto,
        'justificativa': justificativa,
        'requisitos': requisitos,
        if (alternativas != null && alternativas!.isNotEmpty)
          'alternativas': alternativas,
        if (valorEstimado != null) 'valorEstimado': valorEstimado,
        if (riscos != null && riscos!.isNotEmpty) 'riscos': riscos,
        if (conclusao != null && conclusao!.isNotEmpty) 'conclusao': conclusao,
      };
}

class TrDTO {
  final String especificacoes;
  final String condicoesFornecimento;
  final String obrigacoes;
  final String criteriosAceitacao;
  final String prazosEntrega;
  final String? garantia;
  final String? formaPagamento;

  TrDTO({
    required this.especificacoes,
    required this.condicoesFornecimento,
    required this.obrigacoes,
    required this.criteriosAceitacao,
    required this.prazosEntrega,
    this.garantia,
    this.formaPagamento,
  });

  Map<String, dynamic> toJson() => {
        'especificacoes': especificacoes,
        'condicoesFornecimento': condicoesFornecimento,
        'obrigacoes': obrigacoes,
        'criteriosAceitacao': criteriosAceitacao,
        'prazosEntrega': prazosEntrega,
        if (garantia != null && garantia!.isNotEmpty) 'garantia': garantia,
        if (formaPagamento != null && formaPagamento!.isNotEmpty)
          'formaPagamento': formaPagamento,
      };
}

class EditalDTO {
  final String? numeroProcesso;
  final String? numeroEdital;
  final String? localSessao;
  final String? dataAberturaSessao;
  final String? horarioAbertura;
  final String? formaEntregaPropostas;
  final String? anexos;
  final String? observacoes;

  EditalDTO({
    this.numeroProcesso,
    this.numeroEdital,
    this.localSessao,
    this.dataAberturaSessao,
    this.horarioAbertura,
    this.formaEntregaPropostas,
    this.anexos,
    this.observacoes,
  });

  Map<String, dynamic> toJson() => {
        if (numeroProcesso != null && numeroProcesso!.isNotEmpty)
          'numeroProcesso': numeroProcesso,
        if (numeroEdital != null && numeroEdital!.isNotEmpty)
          'numeroEdital': numeroEdital,
        if (localSessao != null && localSessao!.isNotEmpty)
          'localSessao': localSessao,
        if (dataAberturaSessao != null && dataAberturaSessao!.isNotEmpty)
          'dataAberturaSessao': dataAberturaSessao,
        if (horarioAbertura != null && horarioAbertura!.isNotEmpty)
          'horarioAbertura': horarioAbertura,
        if (formaEntregaPropostas != null && formaEntregaPropostas!.isNotEmpty)
          'formaEntregaPropostas': formaEntregaPropostas,
        if (anexos != null && anexos!.isNotEmpty) 'anexos': anexos,
        if (observacoes != null && observacoes!.isNotEmpty)
          'observacoes': observacoes,
      };
}

class AprovacaoDocumentoDTO {
  final String responsavel;

  AprovacaoDocumentoDTO({required this.responsavel});

  Map<String, dynamic> toJson() => {'responsavel': responsavel};
}

String _formatDatePlane(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  return '${parsed.day.toString().padLeft(2, '0')}/'
      '${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
}