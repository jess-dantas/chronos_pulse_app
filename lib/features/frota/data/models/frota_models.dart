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
  final double? odometroAtual;
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
      odometroAtual: _toDouble(json['odometroAtual']),
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
  final double litros;
  final double valorLitro;
  final double valorTotal;
  final double? odometroKm;
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
      litros: _toDouble(json['litros']) ?? 0,
      valorLitro: _toDouble(json['valorLitro']) ?? 0,
      valorTotal: _toDouble(json['valorTotal']) ?? 0,
      odometroKm: _toDouble(json['odometroKm']),
      posto: json['posto']?.toString(),
      observacoes: json['observacoes']?.toString(),
    );
  }
}

double? _toDouble(dynamic valor) {
  if (valor == null) return null;
  if (valor is num) return valor.toDouble();
  return double.tryParse(valor.toString().replaceAll(',', '.'));
}