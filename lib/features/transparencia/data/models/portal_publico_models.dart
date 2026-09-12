import 'package:flutter/foundation.dart';

double _asDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

@immutable
class PortalOrgaoModel {
  final String slug;
  final String nome;
  final String cnpj;

  const PortalOrgaoModel({required this.slug, required this.nome, required this.cnpj});

  factory PortalOrgaoModel.fromJson(Map<String, dynamic> json) => PortalOrgaoModel(
        slug: json['slug']?.toString() ?? '',
        nome: json['nome']?.toString() ?? '',
        cnpj: json['cnpj']?.toString() ?? '',
      );
}

@immutable
class PortalResumoModel {
  final PortalOrgaoModel orgao;
  final int licitacoesPublicadas;
  final int licitacoesEmAndamento;
  final int licitacoesHomologadas;
  final int contratosAtivos;
  final double valorEmpenhado;
  final double valorLiquidado;
  final double valorDespesasAno;
  final int publicacoesDivulgadas;
  final String ultimaCompetencia;

  const PortalResumoModel({
    required this.orgao,
    required this.licitacoesPublicadas,
    required this.licitacoesEmAndamento,
    required this.licitacoesHomologadas,
    required this.contratosAtivos,
    required this.valorEmpenhado,
    required this.valorLiquidado,
    required this.valorDespesasAno,
    required this.publicacoesDivulgadas,
    required this.ultimaCompetencia,
  });

  factory PortalResumoModel.fromJson(Map<String, dynamic> json) => PortalResumoModel(
        orgao: PortalOrgaoModel.fromJson(Map<String, dynamic>.from(json['orgao'] ?? {})),
        licitacoesPublicadas: _asInt(json['licitacoesPublicadas']),
        licitacoesEmAndamento: _asInt(json['licitacoesEmAndamento']),
        licitacoesHomologadas: _asInt(json['licitacoesHomologadas']),
        contratosAtivos: _asInt(json['contratosAtivos']),
        valorEmpenhado: _asDouble(json['valorEmpenhado']),
        valorLiquidado: _asDouble(json['valorLiquidado']),
        valorDespesasAno: _asDouble(json['valorDespesasAno']),
        publicacoesDivulgadas: _asInt(json['publicacoesDivulgadas']),
        ultimaCompetencia: json['ultimaCompetencia']?.toString() ?? '',
      );
}

@immutable
class PortalLicitacaoModel {
  final String id;
  final String numero;
  final String modalidade;
  final String status;
  final String objeto;
  final String? dataAbertura;
  final double valorEstimado;
  final String? pncpPublicadoEm;

  const PortalLicitacaoModel({
    required this.id,
    required this.numero,
    required this.modalidade,
    required this.status,
    required this.objeto,
    this.dataAbertura,
    required this.valorEstimado,
    this.pncpPublicadoEm,
  });

  String get modalidadeRotulo {
    const rotulos = {
      'PREGAO': 'Pregão',
      'CONCORRENCIA': 'Concorrência',
      'LEILAO': 'Leilão',
      'CONCURSO': 'Concurso',
    };
    return rotulos[modalidade] ?? modalidade;
  }

  factory PortalLicitacaoModel.fromJson(Map<String, dynamic> json) => PortalLicitacaoModel(
        id: json['id']?.toString() ?? '',
        numero: json['numero']?.toString() ?? '',
        modalidade: json['modalidade']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        objeto: json['objeto']?.toString() ?? '',
        dataAbertura: json['dataAbertura']?.toString(),
        valorEstimado: _asDouble(json['valorEstimado']),
        pncpPublicadoEm: json['pncpPublicadoEm']?.toString(),
      );
}

@immutable
class PortalLicitacaoItemModel {
  final String descricao;
  final double quantidade;
  final double valorEstimadoUnitario;
  final double valorEstimadoTotal;

  const PortalLicitacaoItemModel({
    required this.descricao,
    required this.quantidade,
    required this.valorEstimadoUnitario,
    required this.valorEstimadoTotal,
  });

  factory PortalLicitacaoItemModel.fromJson(Map<String, dynamic> json) =>
      PortalLicitacaoItemModel(
        descricao: json['descricao']?.toString() ?? '',
        quantidade: _asDouble(json['quantidade']),
        valorEstimadoUnitario: _asDouble(json['valorEstimadoUnitario']),
        valorEstimadoTotal: _asDouble(json['valorEstimadoTotal']),
      );
}

@immutable
class PortalLicitacaoDetalheModel {
  final String id;
  final String numero;
  final String modalidade;
  final String tipoJulgamento;
  final String status;
  final String objeto;
  final String? dataAbertura;
  final double valorEstimado;
  final String? observacoes;
  final String? pncpPublicadoEm;
  final List<PortalLicitacaoItemModel> itens;

  const PortalLicitacaoDetalheModel({
    required this.id,
    required this.numero,
    required this.modalidade,
    required this.tipoJulgamento,
    required this.status,
    required this.objeto,
    this.dataAbertura,
    required this.valorEstimado,
    this.observacoes,
    this.pncpPublicadoEm,
    this.itens = const [],
  });

  factory PortalLicitacaoDetalheModel.fromJson(Map<String, dynamic> json) =>
      PortalLicitacaoDetalheModel(
        id: json['id']?.toString() ?? '',
        numero: json['numero']?.toString() ?? '',
        modalidade: json['modalidade']?.toString() ?? '',
        tipoJulgamento: json['tipoJulgamento']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        objeto: json['objeto']?.toString() ?? '',
        dataAbertura: json['dataAbertura']?.toString(),
        valorEstimado: _asDouble(json['valorEstimado']),
        observacoes: json['observacoes']?.toString(),
        pncpPublicadoEm: json['pncpPublicadoEm']?.toString(),
        itens: (json['itens'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(PortalLicitacaoItemModel.fromJson)
            .toList(),
      );
}

@immutable
class PortalContratoModel {
  final String id;
  final String numero;
  final String objeto;
  final String? dataInicio;
  final String? dataFim;
  final String status;
  final double valorTotal;
  final double valorEmpenhado;
  final double valorLiquidado;
  final String? licitacaoId;

  const PortalContratoModel({
    required this.id,
    required this.numero,
    required this.objeto,
    this.dataInicio,
    this.dataFim,
    required this.status,
    required this.valorTotal,
    required this.valorEmpenhado,
    required this.valorLiquidado,
    this.licitacaoId,
  });

  factory PortalContratoModel.fromJson(Map<String, dynamic> json) => PortalContratoModel(
        id: json['id']?.toString() ?? '',
        numero: json['numero']?.toString() ?? '',
        objeto: json['objeto']?.toString() ?? '',
        dataInicio: json['dataInicio']?.toString(),
        dataFim: json['dataFim']?.toString(),
        status: json['status']?.toString() ?? '',
        valorTotal: _asDouble(json['valorTotal']),
        valorEmpenhado: _asDouble(json['valorEmpenhado']),
        valorLiquidado: _asDouble(json['valorLiquidado']),
        licitacaoId: json['licitacaoId']?.toString(),
      );
}

@immutable
class PortalAditivoModel {
  final String tipo;
  final String descricao;
  final String? justificativa;
  final int prazoAdicionadoDias;
  final double novoValorTotal;
  final bool aprovado;
  final String? criadoEm;

  const PortalAditivoModel({
    required this.tipo,
    required this.descricao,
    this.justificativa,
    required this.prazoAdicionadoDias,
    required this.novoValorTotal,
    required this.aprovado,
    this.criadoEm,
  });

  factory PortalAditivoModel.fromJson(Map<String, dynamic> json) => PortalAditivoModel(
        tipo: json['tipo']?.toString() ?? '',
        descricao: json['descricao']?.toString() ?? '',
        justificativa: json['justificativa']?.toString(),
        prazoAdicionadoDias: _asInt(json['prazoAdicionadoDias']),
        novoValorTotal: _asDouble(json['novoValorTotal']),
        aprovado: json['aprovado'] ?? false,
        criadoEm: json['criadoEm']?.toString(),
      );
}

@immutable
class PortalSancaoModel {
  final String tipo;
  final String descricao;
  final String? baseLegal;
  final double percentualMulta;
  final double valorMulta;
  final String? aplicadaEm;

  const PortalSancaoModel({
    required this.tipo,
    required this.descricao,
    this.baseLegal,
    required this.percentualMulta,
    required this.valorMulta,
    this.aplicadaEm,
  });

  factory PortalSancaoModel.fromJson(Map<String, dynamic> json) => PortalSancaoModel(
        tipo: json['tipo']?.toString() ?? '',
        descricao: json['descricao']?.toString() ?? '',
        baseLegal: json['baseLegal']?.toString(),
        percentualMulta: _asDouble(json['percentualMulta']),
        valorMulta: _asDouble(json['valorMulta']),
        aplicadaEm: json['aplicadaEm']?.toString(),
      );
}

@immutable
class PortalContratoDetalheModel {
  final String id;
  final String numero;
  final String objeto;
  final String? dataInicio;
  final String? dataFim;
  final String status;
  final double valorTotal;
  final double valorEmpenhado;
  final double valorLiquidado;
  final String? empenhoNumero;
  final String? licitacaoId;
  final List<PortalAditivoModel> aditivos;
  final List<PortalSancaoModel> sancoes;

  const PortalContratoDetalheModel({
    required this.id,
    required this.numero,
    required this.objeto,
    this.dataInicio,
    this.dataFim,
    required this.status,
    required this.valorTotal,
    required this.valorEmpenhado,
    required this.valorLiquidado,
    this.empenhoNumero,
    this.licitacaoId,
    this.aditivos = const [],
    this.sancoes = const [],
  });

  factory PortalContratoDetalheModel.fromJson(Map<String, dynamic> json) =>
      PortalContratoDetalheModel(
        id: json['id']?.toString() ?? '',
        numero: json['numero']?.toString() ?? '',
        objeto: json['objeto']?.toString() ?? '',
        dataInicio: json['dataInicio']?.toString(),
        dataFim: json['dataFim']?.toString(),
        status: json['status']?.toString() ?? '',
        valorTotal: _asDouble(json['valorTotal']),
        valorEmpenhado: _asDouble(json['valorEmpenhado']),
        valorLiquidado: _asDouble(json['valorLiquidado']),
        empenhoNumero: json['empenhoNumero']?.toString(),
        licitacaoId: json['licitacaoId']?.toString(),
        aditivos: (json['aditivos'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(PortalAditivoModel.fromJson)
            .toList(),
        sancoes: (json['sancoes'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(PortalSancaoModel.fromJson)
            .toList(),
      );
}

@immutable
class PortalPublicacaoModel {
  final String id;
  final String competencia;
  final String tipoPublicacao;
  final double valorTotal;
  final int itensCount;
  final String? dataPublicacao;
  final String? observacoes;

  const PortalPublicacaoModel({
    required this.id,
    required this.competencia,
    required this.tipoPublicacao,
    required this.valorTotal,
    required this.itensCount,
    this.dataPublicacao,
    this.observacoes,
  });

  factory PortalPublicacaoModel.fromJson(Map<String, dynamic> json) => PortalPublicacaoModel(
        id: json['id']?.toString() ?? '',
        competencia: json['competencia']?.toString() ?? '',
        tipoPublicacao: json['tipoPublicacao']?.toString() ?? '',
        valorTotal: _asDouble(json['valorTotal']),
        itensCount: _asInt(json['itensCount']),
        dataPublicacao: json['dataPublicacao']?.toString(),
        observacoes: json['observacoes']?.toString(),
      );
}