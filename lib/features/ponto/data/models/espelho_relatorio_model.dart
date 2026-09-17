import 'registro_ponto_model.dart';

class EspelhoRelatorioModel {
  final EspelhoRelatorioPeriodo periodo;
  final DateTime dataEmissao;
  final EspelhoRelatorioEmpregador? empregador;
  final EspelhoRelatorioTrabalhador? trabalhador;
  final EspelhoRelatorioJornada? jornadaContratual;
  final List<RegistroPontoModel> marcacoes;
  final String? codigoVerificacao;

  EspelhoRelatorioModel({
    required this.periodo,
    required this.dataEmissao,
    this.empregador,
    this.trabalhador,
    this.jornadaContratual,
    required this.marcacoes,
    this.codigoVerificacao,
  });

  factory EspelhoRelatorioModel.fromJson(Map<String, dynamic> json) {
    DateTime parseData(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      return DateTime.parse(val.toString());
    }

    final marcacoesJson = json['marcacoes'];
    final List<RegistroPontoModel> marcacoes = marcacoesJson is List
        ? marcacoesJson
            .whereType<Map<String, dynamic>>()
            .map(RegistroPontoModel.fromJson)
            .toList()
        : [];

    final periodoJson = json['periodo'];
    return EspelhoRelatorioModel(
      periodo: periodoJson is Map<String, dynamic>
          ? EspelhoRelatorioPeriodo.fromJson(periodoJson)
          : const EspelhoRelatorioPeriodo(inicio: null, fim: null),
      dataEmissao: parseData(json['dataEmissao']),
      empregador: json['empregador'] is Map<String, dynamic>
          ? EspelhoRelatorioEmpregador.fromJson(json['empregador'])
          : null,
      trabalhador: json['trabalhador'] is Map<String, dynamic>
          ? EspelhoRelatorioTrabalhador.fromJson(json['trabalhador'])
          : null,
      jornadaContratual: json['jornadaContratual'] is Map<String, dynamic>
          ? EspelhoRelatorioJornada.fromJson(json['jornadaContratual'])
          : null,
      marcacoes: marcacoes,
      codigoVerificacao: json['codigoVerificacao']?.toString(),
    );
  }
}

class EspelhoRelatorioPeriodo {
  final DateTime? inicio;
  final DateTime? fim;

  const EspelhoRelatorioPeriodo({this.inicio, this.fim});

  factory EspelhoRelatorioPeriodo.fromJson(Map<String, dynamic> json) {
    return EspelhoRelatorioPeriodo(
      inicio: json['inicio'] != null ? DateTime.parse(json['inicio'].toString()) : null,
      fim: json['fim'] != null ? DateTime.parse(json['fim'].toString()) : null,
    );
  }
}

class EspelhoRelatorioEmpregador {
  final String? nome;
  final String? cnpj;

  const EspelhoRelatorioEmpregador({this.nome, this.cnpj});

  factory EspelhoRelatorioEmpregador.fromJson(Map<String, dynamic> json) {
    return EspelhoRelatorioEmpregador(
      nome: json['nome']?.toString(),
      cnpj: json['cnpj']?.toString(),
    );
  }
}

class EspelhoRelatorioTrabalhador {
  final String? nome;
  final String? cpf;
  final DateTime? dataAdmissao;
  final String? cargo;
  final String? matricula;
  final String? departamento;

  const EspelhoRelatorioTrabalhador({
    this.nome,
    this.cpf,
    this.dataAdmissao,
    this.cargo,
    this.matricula,
    this.departamento,
  });

  factory EspelhoRelatorioTrabalhador.fromJson(Map<String, dynamic> json) {
    return EspelhoRelatorioTrabalhador(
      nome: json['nome']?.toString(),
      cpf: json['cpf']?.toString(),
      dataAdmissao: json['dataAdmissao'] != null
          ? DateTime.parse(json['dataAdmissao'].toString())
          : null,
      cargo: json['cargo']?.toString(),
      matricula: json['matricula']?.toString(),
      departamento: json['departamento']?.toString(),
    );
  }
}

class EspelhoRelatorioJornada {
  final String? nome;
  final int? cargaHorariaDiariaMinutos;
  final int? intervaloMinimoMinutos;

  const EspelhoRelatorioJornada({
    this.nome,
    this.cargaHorariaDiariaMinutos,
    this.intervaloMinimoMinutos,
  });

  factory EspelhoRelatorioJornada.fromJson(Map<String, dynamic> json) {
    return EspelhoRelatorioJornada(
      nome: json['nome']?.toString(),
      cargaHorariaDiariaMinutos:
          (json['cargaHorariaDiariaMinutos'] as num?)?.toInt(),
      intervaloMinimoMinutos:
          (json['intervaloMinimoMinutos'] as num?)?.toInt(),
    );
  }
}