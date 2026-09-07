class PatrimonioModel {
  final String id;
  final String? tombamento;
  final String descricao;
  final String? categoria;
  final String estado;
  final String? localizacao;
  final String? dataAquisicao;
  final String? valorAquisicao;
  final String? responsavelNome;
  final String? numeroNotaFiscal;
  final String? observacoes;
  final bool ativo;

  PatrimonioModel({
    required this.id,
    this.tombamento,
    required this.descricao,
    this.categoria,
    this.estado = 'BOM',
    this.localizacao,
    this.dataAquisicao,
    this.valorAquisicao,
    this.responsavelNome,
    this.numeroNotaFiscal,
    this.observacoes,
    this.ativo = true,
  });

  factory PatrimonioModel.fromJson(Map<String, dynamic> json) {
    return PatrimonioModel(
      id: json['id']?.toString() ?? '',
      tombamento: json['tombamento']?.toString(),
      descricao: json['descricao']?.toString() ?? '',
      categoria: json['categoria']?.toString(),
      estado: json['estado']?.toString() ?? 'BOM',
      localizacao: json['localizacao']?.toString(),
      dataAquisicao: json['dataAquisicao']?.toString(),
      valorAquisicao: json['valorAquisicao']?.toString(),
      responsavelNome: json['responsavelNome']?.toString(),
      numeroNotaFiscal: json['numeroNotaFiscal']?.toString(),
      observacoes: json['observacoes']?.toString(),
      ativo: json['ativo'] ?? true,
    );
  }
}