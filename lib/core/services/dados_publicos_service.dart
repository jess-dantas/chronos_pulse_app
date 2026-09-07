import 'package:dio/dio.dart';

/// Serviço de consulta de dados públicos via BrasilAPI.
///
/// CNPJ: https://brasilapi.com.br/api/cnpj/v1/{cnpj} -> razao_social
/// CEP:  https://brasilapi.com.br/api/cep/v2/{cep} -> street/neighborhood/city/state
class DadosPublicosService {
  DadosPublicosService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://brasilapi.com.br/api',
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 12),
              headers: {'Accept': 'application/json'},
            ));

  final Dio _dio;

  /// Consulta um CNPJ (14 dígitos) e retorna a razão social, ou null quando
  /// não encontrado / inválido.
  Future<String?> consultarRazaoSocialCnpj(String cnpj) async {
    final limpo = cnpj.replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
    if (limpo.length != 14) return null;
    try {
      final response = await _dio.get('/cnpj/v1/$limpo');
      if (response.statusCode == 200 && response.data is Map) {
        final razao = (response.data as Map)['razao_social'];
        if (razao is String && razao.isNotEmpty) return razao;
      }
      return null;
    } on DioException {
      return null;
    }
  }

  /// Consulta um CEP (8 dígitos) e retorna os dados de endereço, ou null
  /// quando não encontrado / inválido.
  Future<DadosCep?> consultarCep(String cep) async {
    final limpo = cep.replaceAll(RegExp(r'\D'), '');
    if (limpo.length != 8) return null;
    try {
      final response = await _dio.get('/cep/v2/$limpo');
      if (response.statusCode == 200 && response.data is Map) {
        final json = response.data as Map;
        final rua = json['street'] as String?;
        final bairro = json['neighborhood'] as String?;
        final cidade = json['city'] as String?;
        final uf = json['state'] as String?;
        if (rua == null && bairro == null && cidade == null) return null;
        return DadosCep(rua: rua, bairro: bairro, cidade: cidade, uf: uf);
      }
      return null;
    } on DioException {
      return null;
    }
  }
}

class DadosCep {
  const DadosCep({this.rua, this.bairro, this.cidade, this.uf});

  final String? rua;
  final String? bairro;
  final String? cidade;
  final String? uf;
}