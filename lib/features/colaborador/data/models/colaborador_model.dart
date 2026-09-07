class ColaboradorModel {
  final String id;
  final String cpcUsuarioId;
  final String tenantId;
  final String cpf;
  final String nome;
  final String email;
  final String matricula;
  final String cargo;
  final String departamento;
  final String? dataAdmissao;
  final String? dataNascimento;
  final String? dataDesligamento;
  final bool acessoEstoque;
  final bool acessoPatrimonio;
  final bool acessoFrota;
  final bool acessoProtocolo;
  final bool ativo;

  ColaboradorModel({
    required this.id,
    required this.cpcUsuarioId,
    required this.tenantId,
    required this.cpf,
    required this.nome,
    required this.email,
    required this.matricula,
    required this.cargo,
    required this.departamento,
    this.dataAdmissao,
    this.dataNascimento,
    this.dataDesligamento,
    required this.acessoEstoque,
    this.acessoPatrimonio = false,
    this.acessoFrota = false,
    this.acessoProtocolo = false,
    required this.ativo,
  });

  factory ColaboradorModel.fromJson(Map<String, dynamic> json) {
    return ColaboradorModel(
      id: json['id'] ?? '',
      cpcUsuarioId: json['cpcUsuarioId'] ?? '',
      tenantId: json['tenantId'] ?? '',
      cpf: json['cpf'] ?? '',
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      matricula: json['matricula'] ?? '',
      cargo: json['cargo'] ?? '',
      departamento: json['departamento'] ?? '',
      dataAdmissao: json['dataAdmissao'],
      dataNascimento: json['dataNascimento'],
      dataDesligamento: json['dataDesligamento'],
      acessoEstoque: json['acessoEstoque'] ?? false,
      acessoPatrimonio: json['acessoPatrimonio'] ?? false,
      acessoFrota: json['acessoFrota'] ?? false,
      acessoProtocolo: json['acessoProtocolo'] ?? false,
      ativo: json['ativo'] ?? true,
    );
  }
}
