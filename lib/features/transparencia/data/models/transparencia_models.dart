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
class TransparenciaResumoModel {
  final ContratosResumoModel contratos;
  final ComprasResumoModel compras;
  final LicitacoesResumoModel licitacoes;
  final EstoqueResumoModel estoque;
  final PatrimonioResumoModel patrimonio;
  final FrotaResumoModel frota;
  final ColaboradoresResumoModel colaboradores;
  final PontoResumoModel ponto;
  final PublicacoesResumoModel publicacoes;

  const TransparenciaResumoModel({
    required this.contratos,
    required this.compras,
    required this.licitacoes,
    required this.estoque,
    required this.patrimonio,
    required this.frota,
    required this.colaboradores,
    required this.ponto,
    required this.publicacoes,
  });

  factory TransparenciaResumoModel.fromJson(Map<String, dynamic> json) {
    return TransparenciaResumoModel(
      contratos: ContratosResumoModel.fromJson(json['contratos'] ?? {}),
      compras: ComprasResumoModel.fromJson(json['compras'] ?? {}),
      licitacoes: LicitacoesResumoModel.fromJson(json['licitacoes'] ?? {}),
      estoque: EstoqueResumoModel.fromJson(json['estoque'] ?? {}),
      patrimonio: PatrimonioResumoModel.fromJson(json['patrimonio'] ?? {}),
      frota: FrotaResumoModel.fromJson(json['frota'] ?? {}),
      colaboradores: ColaboradoresResumoModel.fromJson(json['colaboradores'] ?? {}),
      ponto: PontoResumoModel.fromJson(json['ponto'] ?? {}),
      publicacoes: PublicacoesResumoModel.fromJson(json['publicacoes'] ?? {}),
    );
  }
}

@immutable
class ContratosResumoModel {
  final int ativos;
  final double valorEmpenhado;
  final double valorLiquidado;
  final double saldoTotal;
  final int vencendo30Dias;
  final int vencendo60Dias;
  final int vencendo90Dias;
  final int vencidos;

  const ContratosResumoModel({
    required this.ativos,
    required this.valorEmpenhado,
    required this.valorLiquidado,
    required this.saldoTotal,
    required this.vencendo30Dias,
    required this.vencendo60Dias,
    required this.vencendo90Dias,
    required this.vencidos,
  });

  factory ContratosResumoModel.fromJson(Map<String, dynamic> json) => ContratosResumoModel(
        ativos: _asInt(json['ativos']),
        valorEmpenhado: _asDouble(json['valorEmpenhado']),
        valorLiquidado: _asDouble(json['valorLiquidado']),
        saldoTotal: _asDouble(json['saldoTotal']),
        vencendo30Dias: _asInt(json['vencendo30Dias']),
        vencendo60Dias: _asInt(json['vencendo60Dias']),
        vencendo90Dias: _asInt(json['vencendo90Dias']),
        vencidos: _asInt(json['vencidos']),
      );
}

@immutable
class ComprasResumoModel {
  final int fornecedoresAtivos;
  final int pedidosEmitidos;
  final double valorPedidos;
  final int notasFiscaisRecebidas;
  final double valorNotasFiscais;

  const ComprasResumoModel({
    required this.fornecedoresAtivos,
    required this.pedidosEmitidos,
    required this.valorPedidos,
    required this.notasFiscaisRecebidas,
    required this.valorNotasFiscais,
  });

  factory ComprasResumoModel.fromJson(Map<String, dynamic> json) => ComprasResumoModel(
        fornecedoresAtivos: _asInt(json['fornecedoresAtivos']),
        pedidosEmitidos: _asInt(json['pedidosEmitidos']),
        valorPedidos: _asDouble(json['valorPedidos']),
        notasFiscaisRecebidas: _asInt(json['notasFiscaisRecebidas']),
        valorNotasFiscais: _asDouble(json['valorNotasFiscais']),
      );
}

@immutable
class LicitacoesResumoModel {
  final int total;
  final int emElaboracao;
  final int publicadas;
  final int abertas;
  final int adjudicadas;
  final int homologadas;
  final int canceladas;
  final double valorEstimadoTotal;

  const LicitacoesResumoModel({
    required this.total,
    required this.emElaboracao,
    required this.publicadas,
    required this.abertas,
    required this.adjudicadas,
    required this.homologadas,
    required this.canceladas,
    required this.valorEstimadoTotal,
  });

  factory LicitacoesResumoModel.fromJson(Map<String, dynamic> json) => LicitacoesResumoModel(
        total: _asInt(json['total']),
        emElaboracao: _asInt(json['emElaboracao']),
        publicadas: _asInt(json['publicadas']),
        abertas: _asInt(json['abertas']),
        adjudicadas: _asInt(json['adjudicadas']),
        homologadas: _asInt(json['homologadas']),
        canceladas: _asInt(json['canceladas']),
        valorEstimadoTotal: _asDouble(json['valorEstimadoTotal']),
      );
}

@immutable
class EstoqueResumoModel {
  final int itensEstoque;
  final double valorTotalEstoque;
  final int acimaDoMinimo;
  final int abaixoDoMinimo;

  const EstoqueResumoModel({
    required this.itensEstoque,
    required this.valorTotalEstoque,
    required this.acimaDoMinimo,
    required this.abaixoDoMinimo,
  });

  factory EstoqueResumoModel.fromJson(Map<String, dynamic> json) => EstoqueResumoModel(
        itensEstoque: _asInt(json['itensEstoque']),
        valorTotalEstoque: _asDouble(json['valorTotalEstoque']),
        acimaDoMinimo: _asInt(json['acimaDoMinimo']),
        abaixoDoMinimo: _asInt(json['abaixoDoMinimo']),
      );
}

@immutable
class PatrimonioResumoModel {
  final int totalBens;
  final int bensAtivos;
  final double valorAquisicao;
  final double valorAtual;

  const PatrimonioResumoModel({
    required this.totalBens,
    required this.bensAtivos,
    required this.valorAquisicao,
    required this.valorAtual,
  });

  factory PatrimonioResumoModel.fromJson(Map<String, dynamic> json) => PatrimonioResumoModel(
        totalBens: _asInt(json['totalBens']),
        bensAtivos: _asInt(json['bensAtivos']),
        valorAquisicao: _asDouble(json['valorAquisicao']),
        valorAtual: _asDouble(json['valorAtual']),
      );
}

@immutable
class FrotaResumoModel {
  final int veiculos;
  final int veiculosAtivos;
  final int abastecimentosMes;
  final double valorAbastecimentosMes;

  const FrotaResumoModel({
    required this.veiculos,
    required this.veiculosAtivos,
    required this.abastecimentosMes,
    required this.valorAbastecimentosMes,
  });

  factory FrotaResumoModel.fromJson(Map<String, dynamic> json) => FrotaResumoModel(
        veiculos: _asInt(json['veiculos']),
        veiculosAtivos: _asInt(json['veiculosAtivos']),
        abastecimentosMes: _asInt(json['abastecimentosMes']),
        valorAbastecimentosMes: _asDouble(json['valorAbastecimentosMes']),
      );
}

@immutable
class ColaboradoresResumoModel {
  final int total;
  final int ativos;

  const ColaboradoresResumoModel({required this.total, required this.ativos});

  factory ColaboradoresResumoModel.fromJson(Map<String, dynamic> json) =>
      ColaboradoresResumoModel(total: _asInt(json['total']), ativos: _asInt(json['ativos']));
}

@immutable
class PontoResumoModel {
  final int registrosMes;

  const PontoResumoModel({required this.registrosMes});

  factory PontoResumoModel.fromJson(Map<String, dynamic> json) =>
      PontoResumoModel(registrosMes: _asInt(json['registrosMes']));
}

@immutable
class PublicacoesResumoModel {
  final int publicadas;
  final String ultimaCompetencia;

  const PublicacoesResumoModel({required this.publicadas, required this.ultimaCompetencia});

  factory PublicacoesResumoModel.fromJson(Map<String, dynamic> json) => PublicacoesResumoModel(
        publicadas: _asInt(json['publicadas']),
        ultimaCompetencia: json['ultimaCompetencia']?.toString() ?? '-',
      );
}

@immutable
class DespesasMensaisModel {
  final int ano;
  final List<DespesaMensalModel> meses;

  const DespesasMensaisModel({required this.ano, required this.meses});

  factory DespesasMensaisModel.fromJson(Map<String, dynamic> json) => DespesasMensaisModel(
        ano: _asInt(json['ano']),
        meses: (json['meses'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(DespesaMensalModel.fromJson)
            .toList(),
      );
}

@immutable
class DespesaMensalModel {
  final int mes;
  final double despesasNfe;
  final int notasFiscais;
  final double combustivel;
  final int abastecimentos;
  final double pedidosEmitidos;
  final int quantidadePedidos;

  const DespesaMensalModel({
    required this.mes,
    required this.despesasNfe,
    required this.notasFiscais,
    required this.combustivel,
    required this.abastecimentos,
    required this.pedidosEmitidos,
    required this.quantidadePedidos,
  });

  double get total => despesasNfe + combustivel;

  factory DespesaMensalModel.fromJson(Map<String, dynamic> json) => DespesaMensalModel(
        mes: _asInt(json['mes']),
        despesasNfe: _asDouble(json['despesasNfe']),
        notasFiscais: _asInt(json['notasFiscais']),
        combustivel: _asDouble(json['combustivel']),
        abastecimentos: _asInt(json['abastecimentos']),
        pedidosEmitidos: _asDouble(json['pedidosEmitidos']),
        quantidadePedidos: _asInt(json['quantidadePedidos']),
      );
}

@immutable
class TransparenciaPublicacaoModel {
  final String id;
  final String competencia;
  final String tipoPublicacao;
  final double valorTotal;
  final int itensCount;
  final String status;
  final String? dataPublicacao;
  final String? observacoes;

  const TransparenciaPublicacaoModel({
    required this.id,
    required this.competencia,
    required this.tipoPublicacao,
    required this.valorTotal,
    required this.itensCount,
    required this.status,
    this.dataPublicacao,
    this.observacoes,
  });

  bool get isPublicado => status == 'PUBLICADO';

  String get tipoRotulo => switch (tipoPublicacao) {
        'RECEITAS' => 'Receitas',
        'DESPESAS' => 'Despesas',
        'COMPRAS' => 'Compras',
        'LICITACOES' => 'Licitações',
        'CONTRATOS' => 'Contratos',
        'FROTA' => 'Frota',
        'PATRIMONIO' => 'Patrimônio',
        'FOLHA' => 'Folha',
        _ => tipoPublicacao,
      };

  factory TransparenciaPublicacaoModel.fromJson(Map<String, dynamic> json) =>
      TransparenciaPublicacaoModel(
        id: json['id']?.toString() ?? '',
        competencia: json['competencia']?.toString() ?? '',
        tipoPublicacao: json['tipoPublicacao']?.toString() ?? '',
        valorTotal: _asDouble(json['valorTotal']),
        itensCount: _asInt(json['itensCount']),
        status: json['status']?.toString() ?? '',
        dataPublicacao: json['dataPublicacao']?.toString(),
        observacoes: json['observacoes']?.toString(),
      );
}