import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/transparencia_models.dart';

class TransparenciaRemoteDataSource {
  final DioClient _dioClient;

  TransparenciaRemoteDataSource(this._dioClient);

  Future<TransparenciaResumoModel> getResumo() async {
    final response = await _dioClient.dio.get(ApiConstants.transparenciaResumoEndpoint);
    if (response.statusCode == 200) {
      return TransparenciaResumoModel.fromJson(Map<String, dynamic>.from(response.data));
    }
    throw Exception('Falha ao carregar o resumo da transparência: ${response.statusCode}');
  }

  Future<DespesasMensaisModel> getDespesasMensais(int ano) async {
    final response = await _dioClient.dio.get(ApiConstants.transparenciaDespesasMensaisEndpoint(ano));
    if (response.statusCode == 200) {
      return DespesasMensaisModel.fromJson(Map<String, dynamic>.from(response.data));
    }
    throw Exception('Falha ao carregar despesas mensais: ${response.statusCode}');
  }

  Future<List<TransparenciaPublicacaoModel>> getPublicacoes() async {
    final response = await _dioClient.dio.get(ApiConstants.transparenciaPublicacoesEndpoint);
    if (response.statusCode == 200) {
      final List data = response.data;
      return data.map((json) => TransparenciaPublicacaoModel.fromJson(json)).toList();
    }
    throw Exception('Falha ao carregar publicações: ${response.statusCode}');
  }

  Future<TransparenciaPublicacaoModel> criarPublicacao(Map<String, dynamic> payload) async {
    final response = await _dioClient.dio.post(
      ApiConstants.transparenciaPublicacoesEndpoint,
      data: payload,
    );
    if (response.statusCode == 200) {
      return TransparenciaPublicacaoModel.fromJson(response.data);
    }
    throw Exception('Falha ao criar publicação: ${response.statusCode}');
  }

  Future<TransparenciaPublicacaoModel> publicarPublicacao(String id) async {
    final response = await _dioClient.dio.post(
      ApiConstants.transparenciaPublicacaoPublicarEndpoint(id),
    );
    if (response.statusCode == 200) {
      return TransparenciaPublicacaoModel.fromJson(response.data);
    }
    throw Exception('Falha ao publicar: ${response.statusCode}');
  }

  Future<void> removerPublicacao(String id) async {
    final response = await _dioClient.dio.delete(
      ApiConstants.transparenciaPublicacaoDeleteEndpoint(id),
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao remover publicação: ${response.statusCode}');
    }
  }
}