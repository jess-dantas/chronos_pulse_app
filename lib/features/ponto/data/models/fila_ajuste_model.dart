/// Item da fila consolidada de aprovação de ajustes (RH):
/// ajuste pendente + colaborador + marcações do dia.
class FilaAjusteModel {
  final String registroId;
  final String? colaboradorId;
  final String? colaboradorNome;
  final DateTime dataHoraDispositivo;
  final String tipoRegistro;
  final bool ajusteManual;
  final String? justificativa;
  final String? observacao;
  final int? nsr;
  final int? nsrLogico;
  final String? ajusteStatus;
  final List<MarcacaoDiaModel> marcacoesDoDia;

  const FilaAjusteModel({
    required this.registroId,
    this.colaboradorId,
    this.colaboradorNome,
    required this.dataHoraDispositivo,
    required this.tipoRegistro,
    this.ajusteManual = true,
    this.justificativa,
    this.observacao,
    this.nsr,
    this.nsrLogico,
    this.ajusteStatus,
    this.marcacoesDoDia = const [],
  });

  factory FilaAjusteModel.fromJson(Map<String, dynamic> json) {
    DateTime parseData(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      return DateTime.parse(val.toString());
    }

    final marcacoes = <MarcacaoDiaModel>[];
    if (json['marcacoesDoDia'] is List) {
      for (final item in json['marcacoesDoDia'] as List) {
        if (item is Map<String, dynamic>) {
          marcacoes.add(MarcacaoDiaModel.fromJson(item));
        }
      }
    }

    return FilaAjusteModel(
      registroId: json['registroId']?.toString() ?? json['id']?.toString() ?? '',
      colaboradorId: json['colaboradorId']?.toString(),
      colaboradorNome: json['colaboradorNome']?.toString(),
      dataHoraDispositivo: parseData(json['dataHoraDispositivo']),
      tipoRegistro: json['tipoRegistro']?.toString() ?? 'ENTRADA',
      ajusteManual: (json['ajusteManual'] == true || json['ajusteManual'] == 1),
      justificativa: json['justificativa']?.toString(),
      observacao: json['observacao']?.toString(),
      nsr: (json['nsr'] as num?)?.toInt(),
      nsrLogico: (json['nsrLogico'] as num?)?.toInt(),
      ajusteStatus: json['ajusteStatus']?.toString(),
      marcacoesDoDia: marcacoes,
    );
  }

  String get nomeExibicao => (colaboradorNome != null && colaboradorNome!.isNotEmpty)
      ? colaboradorNome!
      : (colaboradorId != null ? colaboradorId!.substring(0, 8) : '—');
}

/// Marcação do mesmo dia do ajuste solicitado (contexto do espelho).
class MarcacaoDiaModel {
  final DateTime dataHora;
  final String tipoRegistro;
  final bool ajuste;

  const MarcacaoDiaModel({
    required this.dataHora,
    required this.tipoRegistro,
    required this.ajuste,
  });

  factory MarcacaoDiaModel.fromJson(Map<String, dynamic> json) {
    return MarcacaoDiaModel(
      dataHora: DateTime.parse(json['dataHora'].toString()),
      tipoRegistro: json['tipoRegistro']?.toString() ?? 'ENTRADA',
      ajuste: json['ajuste'] == true,
    );
  }
}
