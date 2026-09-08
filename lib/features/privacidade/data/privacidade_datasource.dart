import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';

class PrivacidadeDataSource {
  final DioClient _dioClient;

  PrivacidadeDataSource(this._dioClient);

  Future<Map<String, dynamic>> getPolitica() async {
    final response = await _dioClient.dio.get(ApiConstants.privacidadePoliticaEndpoint);
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(response.data);
    }
    throw Exception('Falha ao carregar política de privacidade (${response.statusCode})');
  }

  Future<Map<String, dynamic>> getMeusDados() async {
    final response = await _dioClient.dio.get(ApiConstants.privacidadeMeusDadosEndpoint);
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(response.data);
    }
    throw Exception('Falha ao exportar meus dados (${response.statusCode})');
  }

  Future<void> registrarConsentimento(String versaoPolitica) async {
    final response = await _dioClient.dio.post(
      ApiConstants.privacidadeConsentimentoEndpoint,
      data: {'versaoPolitica': versaoPolitica, 'aceito': true},
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Falha ao registrar consentimento (${response.statusCode})');
    }
  }

  Future<void> apagarMeusDados() async {
    final response = await _dioClient.dio.delete(ApiConstants.privacidadeMeusDadosEndpoint);
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Falha ao anonimizar meus dados (${response.statusCode})');
    }
  }
}