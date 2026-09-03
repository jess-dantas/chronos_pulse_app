class UsuarioModel {
  final String token;
  final String? refreshToken;
  final String tipo;
  final String nome;
  final String email;
  final String role;
  final String? tenantId;
  final String? colaboradorId;
  final String? cpcId;

  UsuarioModel({
    required this.token,
    this.refreshToken,
    required this.tipo,
    required this.nome,
    required this.email,
    required this.role,
    this.tenantId,
    this.colaboradorId,
    this.cpcId,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      token: json['accessToken'] ?? json['token'] ?? '',
      refreshToken: json['refreshToken'],
      tipo: json['tipo'] ?? 'Bearer',
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      tenantId: json['tenantId'],
      colaboradorId: json['colaboradorId'] ?? json['cpcId'],
      cpcId: json['cpcId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refreshToken': refreshToken,
      'tipo': tipo,
      'nome': nome,
      'email': email,
      'role': role,
      'tenantId': tenantId,
      'colaboradorId': colaboradorId,
      'cpcId': cpcId,
    };
  }
}
