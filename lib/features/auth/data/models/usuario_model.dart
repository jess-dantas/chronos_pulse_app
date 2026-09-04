class UsuarioModel {
  final String token;
  final String? refreshToken;
  final String tipo;
  final String nome;
  final String email;
  final String? cpf;
  final String role;
  final String? tenantId;
  final String? colaboradorId;
  final String? cpcId;
  final bool acessoEstoque;

  UsuarioModel({
    required this.token,
    this.refreshToken,
    required this.tipo,
    required this.nome,
    required this.email,
    this.cpf,
    required this.role,
    this.tenantId,
    this.colaboradorId,
    this.cpcId,
    this.acessoEstoque = false,
  });

  bool get isAdminPlataforma => role == 'ADMIN_PLATAFORMA';
  bool get isSuporte => role == 'SUPORTE_N1' || role == 'SUPORTE_N2';
  bool get isAdminEmpresa => role == 'ADMIN_EMPRESA';
  bool get isGestorRh => role == 'GESTOR_RH';
  bool get isColaborador => role == 'COLABORADOR';

  bool get isAdminOrRh => isAdminPlataforma || isAdminEmpresa || isGestorRh;
  bool get isGestorPlataforma => isAdminPlataforma || isSuporte;
  bool get temAcessoEstoque => isAdminOrRh || acessoEstoque;

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      token: json['accessToken'] ?? json['token'] ?? '',
      refreshToken: json['refreshToken'],
      tipo: json['tipo'] ?? 'Bearer',
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      cpf: json['cpf'] ?? json['sub'],
      role: json['role'] ?? '',
      tenantId: json['tenantId'],
      colaboradorId: json['colaboradorId'] ?? json['cpcId'],
      cpcId: json['cpcId'],
      acessoEstoque: json['acessoEstoque'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refreshToken': refreshToken,
      'tipo': tipo,
      'nome': nome,
      'email': email,
      'cpf': cpf,
      'role': role,
      'tenantId': tenantId,
      'colaboradorId': colaboradorId,
      'cpcId': cpcId,
      'acessoEstoque': acessoEstoque,
    };
  }
}
