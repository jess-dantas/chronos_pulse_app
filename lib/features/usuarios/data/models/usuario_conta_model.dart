class UsuarioContaModel {
  final String id;
  final String cpf;
  final String nome;
  final String email;
  final String role;
  final bool ativo;
  final String? criadoEm;

  UsuarioContaModel({
    required this.id,
    required this.cpf,
    required this.nome,
    required this.email,
    required this.role,
    required this.ativo,
    this.criadoEm,
  });

  factory UsuarioContaModel.fromJson(Map<String, dynamic> json) {
    return UsuarioContaModel(
      id: json['id'] ?? '',
      cpf: json['cpf'] ?? '',
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      ativo: json['ativo'] ?? true,
      criadoEm: json['criadoEm']?.toString(),
    );
  }
}
