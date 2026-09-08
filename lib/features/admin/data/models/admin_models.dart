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
    this.status,
    this.observacoes,
  });

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

class AdminColaboradorModel {
  final String id;
  final String cpf;
  final String nome;
  final String? email;
  final String? matricula;
  final String? cargo;
  final String? departamento;
  final String? tenantNome;
  final bool ativo;
  final bool acessoEstoque;
  final bool acessoPatrimonio;
  final bool acessoFrota;
  final bool acessoProtocolo;
  final String? dataDesligamento;
  final String? dataAdmissao;
  final String? dataNascimento;
  final String? tenantId;

  const AdminColaboradorModel({
    required this.id,
    required this.cpf,
    required this.nome,
    this.email,
    this.matricula,
    this.cargo,
    this.departamento,
    this.tenantNome,
    this.ativo = true,
    this.acessoEstoque = false,
    this.acessoPatrimonio = false,
    this.acessoFrota = false,
    this.acessoProtocolo = false,
    this.dataDesligamento,
    this.dataAdmissao,
    this.dataNascimento,
    this.tenantId,
  });

  factory AdminColaboradorModel.fromJson(Map<String, dynamic> json) {
    return AdminColaboradorModel(
      id: (json['id'] ?? '').toString(),
      cpf: (json['cpf'] ?? '').toString(),
      nome: (json['nome'] ?? '').toString(),
      email: json['email']?.toString(),
      matricula: json['matricula']?.toString(),
      cargo: json['cargo']?.toString(),
      departamento: json['departamento']?.toString(),
      tenantNome: json['tenantNome']?.toString(),
      ativo: json['ativo'] != false,
      acessoEstoque: json['acessoEstoque'] == true,
      acessoPatrimonio: json['acessoPatrimonio'] == true,
      acessoFrota: json['acessoFrota'] == true,
      acessoProtocolo: json['acessoProtocolo'] == true,
      dataDesligamento: json['dataDesligamento']?.toString(),
      dataAdmissao: json['dataAdmissao']?.toString(),
      dataNascimento: json['dataNascimento']?.toString(),
      tenantId: json['tenantId']?.toString(),
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