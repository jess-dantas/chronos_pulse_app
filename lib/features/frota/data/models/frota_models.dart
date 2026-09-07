class FrotaVeiculoModel {
  final String id;
  final String placa;
  final String? renavam;
  final String? marca;
  final String? modelo;
  final int? anoFabricacao;
  final int? anoModelo;
  final String? tipo;
  final String? combustivel;
  final String status;
  final String? odometroAtual;
  final String? observacoes;
  final bool ativo;

  FrotaVeiculoModel({
    required this.id,
    required this.placa,
    this.renavam,
    this.marca,
    this.modelo,
    this.anoFabricacao,
    this.anoModelo,
    this.tipo,
    this.combustivel,
    this.status = 'ATIVO',
    this.odometroAtual,
    this.observacoes,
    this.ativo = true,
  });

  factory FrotaVeiculoModel.fromJson(Map<String, dynamic> json) {
    return FrotaVeiculoModel(
      id: json['id']?.toString() ?? '',
      placa: json['placa']?.toString() ?? '',
      renavam: json['renavam']?.toString(),
      marca: json['marca']?.toString(),
      modelo: json['modelo']?.toString(),
      anoFabricacao: json['anoFabricacao'] as int?,
      anoModelo: json['anoModelo'] as int?,
      tipo: json['tipo']?.toString(),
      combustivel: json['combustivel']?.toString(),
      status: json['status']?.toString() ?? 'ATIVO',
      odometroAtual: json['odometroAtual']?.toString(),
      observacoes: json['observacoes']?.toString(),
      ativo: json['ativo'] ?? true,
    );
  }
}

class AbastecimentoModel {
  final String id;
  final String veiculoId;
  final String veiculoPlaca;
  final String dataHora;
  final String litros;
  final String valorLitro;
  final String valorTotal;
  final String? odometroKm;
  final String? posto;
  final String? observacoes;

  AbastecimentoModel({
    required this.id,
    required this.veiculoId,
    this.veiculoPlaca = '',
    required this.dataHora,
    required this.litros,
    required this.valorLitro,
    required this.valorTotal,
    this.odometroKm,
    this.posto,
    this.observacoes,
  });

  factory AbastecimentoModel.fromJson(Map<String, dynamic> json) {
    return AbastecimentoModel(
      id: json['id']?.toString() ?? '',
      veiculoId: json['veiculoId']?.toString() ?? '',
      veiculoPlaca: json['veiculoPlaca']?.toString() ?? '',
      dataHora: json['dataHora']?.toString() ?? '',
      litros: json['litros']?.toString() ?? '0',
      valorLitro: json['valorLitro']?.toString() ?? '0',
      valorTotal: json['valorTotal']?.toString() ?? '0',
      odometroKm: json['odometroKm']?.toString(),
      posto: json['posto']?.toString(),
      observacoes: json['observacoes']?.toString(),
    );
  }
}