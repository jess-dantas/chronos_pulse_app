class TitularidadeIniciado {
  final String transferenciaId;
  final String novoTitularNome;
  final String novoTitularCelular;

  TitularidadeIniciado({
    required this.transferenciaId,
    required this.novoTitularNome,
    required this.novoTitularCelular,
  });

  factory TitularidadeIniciado.fromJson(Map<String, dynamic> json) {
    return TitularidadeIniciado(
      transferenciaId: json['transferenciaId']?.toString() ?? '',
      novoTitularNome: json['novoTitularNome']?.toString() ?? '',
      novoTitularCelular: json['novoTitularCelular']?.toString() ?? '',
    );
  }
}
