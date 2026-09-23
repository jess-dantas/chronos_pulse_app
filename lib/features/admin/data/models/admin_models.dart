// Modelos tipados da área administrativa (R10).
// Substituem o uso de `Map<String, dynamic>` a partir da camada de dados.

class AdminEmpresaModel {
  final String id;
  final String cnpj;
  final String nome;
  final String? responsavelNome;
  final String? responsavelEmail;
  final bool ativo;

  const AdminEmpresaModel({
    required this.id,
    required this.cnpj,
    required this.nome,
    this.responsavelNome,
    this.responsavelEmail,
    this.ativo = true,
  });

  factory AdminEmpresaModel.fromJson(Map<String, dynamic> json) {
    return AdminEmpresaModel(
      id: (json['id'] ?? '').toString(),
      cnpj: (json['cnpj'] ?? '').toString(),
      nome: (json['nome'] ?? '').toString(),
      responsavelNome: json['responsavelNome']?.toString(),
      responsavelEmail: json['responsavelEmail']?.toString(),
      ativo: json['ativo'] != false,
    );
  }
}

class AdminContratoModel {
  final String id;
  final String? tenantId;
  final String numero;
  final String objeto;
  final String? dataInicio;
  final String? dataFim;
  final double valorMensal;
  final double valorTotal;
  final double valorEmpenhado;
  final double valorLiquidado;
  final double saldo;
  final String? empenhoNumero;
  final int? diasParaVencimento;
  final String? statusVigencia;
  final int? vencimentoAvisoDias;
  final String? status;
  final String? observacoes;

  const AdminContratoModel({
    required this.id,
    this.tenantId,
    required this.numero,
    required this.objeto,
    this.dataInicio,
    this.dataFim,
    this.valorMensal = 0,
    this.valorTotal = 0,
    this.valorEmpenhado = 0,
    this.valorLiquidado = 0,
    this.saldo = 0,
    this.empenhoNumero,
    this.diasParaVencimento,
    this.statusVigencia,
    this.vencimentoAvisoDias,
    this.status,
    this.observacoes,
  });

  bool get temAlertaVigencia =>
      statusVigencia == 'VENCENDO' || ((diasParaVencimento ?? 0) < 0);

  factory AdminContratoModel.fromJson(Map<String, dynamic> json) {
    double numOuZero(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString().replaceAll(',', '.')) ?? 0;
    }

    return AdminContratoModel(
      id: (json['id'] ?? '').toString(),
      tenantId: json['tenantId']?.toString(),
      numero: (json['numero'] ?? '').toString(),
      objeto: (json['objeto'] ?? '').toString(),
      dataInicio: json['dataInicio']?.toString(),
      dataFim: json['dataFim']?.toString(),
      valorMensal: numOuZero(json['valorMensal']),
      valorTotal: numOuZero(json['valorTotal']),
      valorEmpenhado: numOuZero(json['valorEmpenhado']),
      valorLiquidado: numOuZero(json['valorLiquidado']),
      saldo: numOuZero(json['saldo']),
      empenhoNumero: json['empenhoNumero']?.toString(),
      diasParaVencimento: (json['diasParaVencimento'] as num?)?.toInt(),
      statusVigencia: json['statusVigencia']?.toString(),
      vencimentoAvisoDias: (json['vencimentoAvisoDias'] as num?)?.toInt(),
      status: json['status']?.toString(),
      observacoes: json['observacoes']?.toString(),
    );
  }
}

class AdminContratoEventoModel {
  final String id;
  final String? contratoId;
  final String tipo;
  final String descricao;
  final String? dataHora;

  const AdminContratoEventoModel({
    required this.id,
    this.contratoId,
    required this.tipo,
    required this.descricao,
    this.dataHora,
  });

  factory AdminContratoEventoModel.fromJson(Map<String, dynamic> json) {
    return AdminContratoEventoModel(
      id: (json['id'] ?? '').toString(),
      contratoId: json['contratoId']?.toString(),
      tipo: (json['tipo'] ?? 'OUTRO').toString(),
      descricao: (json['descricao'] ?? '').toString(),
      dataHora: json['dataHora']?.toString() ?? json['criadoEm']?.toString(),
    );
  }
}

class AdminModuloModel {
  final String codigo;
  final String nome;
  final String? descricao;
  final bool ativo;

  const AdminModuloModel({
    required this.codigo,
    required this.nome,
    this.descricao,
    this.ativo = true,
  });

  factory AdminModuloModel.fromJson(Map<String, dynamic> json) {
    return AdminModuloModel(
      codigo: (json['codigo'] ?? '').toString(),
      nome: (json['nome'] ?? '').toString(),
      descricao: json['descricao']?.toString(),
      ativo: json['ativo'] != false,
    );
  }
}

class AdminDashboardModel {
  final int empresasAtivas;
  final int contratosAtivos;
  final int totalColaboradores;
  final Map<String, dynamic> bruto;

  const AdminDashboardModel({
    required this.empresasAtivas,
    required this.contratosAtivos,
    required this.totalColaboradores,
    required this.bruto,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    int inteiro(dynamic v) => (v as num?)?.toInt() ?? 0;

    return AdminDashboardModel(
      empresasAtivas: inteiro(json['empresasAtivas']),
      contratosAtivos: inteiro(json['contratosAtivos']),
      totalColaboradores: inteiro(json['totalColaboradores']),
      bruto: json,
    );
  }
}

class AdminPlataformaModel {
  final String id;
  final String username;
  final String nomeCompleto;
  final String email;
  final String? ultimoLogin;
  final int tentativasLoginFalhas;
  final String? bloqueioLoginAte;
  final bool ativo;
  final String criadoEm;
  final String? atualizadoEm;

  const AdminPlataformaModel({
    required this.id,
    required this.username,
    required this.nomeCompleto,
    required this.email,
    this.ultimoLogin,
    this.tentativasLoginFalhas = 0,
    this.bloqueioLoginAte,
    this.ativo = true,
    required this.criadoEm,
    this.atualizadoEm,
  });

  factory AdminPlataformaModel.fromJson(Map<String, dynamic> json) {
    return AdminPlataformaModel(
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      nomeCompleto: (json['nomeCompleto'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      ultimoLogin: json['ultimoLogin']?.toString(),
      tentativasLoginFalhas: (json['tentativasLoginFalhas'] as num?)?.toInt() ?? 0,
      bloqueioLoginAte: json['bloqueioLoginAte']?.toString(),
      ativo: json['ativo'] != false,
      criadoEm: (json['criadoEm'] ?? '').toString(),
      atualizadoEm: json['atualizadoEm']?.toString(),
    );
  }
}