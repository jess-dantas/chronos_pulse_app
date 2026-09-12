import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/portal_publico_models.dart';
import '../models/transparencia_models.dart';

class PortalPublicoRemoteDataSource {
  final DioClient _dioClient;

  PortalPublicoRemoteDataSource(this._dioClient);

  Future<PortalResumoModel> getResumo(String slug) async {
    final response = await _dioClient.dio.get(ApiConstants.portalTransparenciaEndpoint(slug));
    if (response.statusCode == 200) {
      return PortalResumoModel.fromJson(Map<String, dynamic>.from(response.data));
    }
    throw Exception('Falha ao carregar o portal público: ${response.statusCode}');
  }

  Future<List<PortalLicitacaoModel>> getLicitacoes(String slug) async {
    final response = await _dioClient.dio.get(ApiConstants.portalLicitacoesEndpoint(slug));
    if (response.statusCode == 200) {
      final List data = response.data;
      return data.map((json) => PortalLicitacaoModel.fromJson(json)).toList();
    }
    throw Exception('Falha ao carregar licitações públicas: ${response.statusCode}');
  }

  Future<PortalLicitacaoDetalheModel> getLicitacao(String slug, String id) async {
    final response = await _dioClient.dio
        .get(ApiConstants.portalLicitacaoDetalheEndpoint(slug, id));
    if (response.statusCode == 200) {
      return PortalLicitacaoDetalheModel.fromJson(Map<String, dynamic>.from(response.data));
    }
    throw Exception('Falha ao carregar a licitação: ${response.statusCode}');
  }

  Future<List<PortalContratoModel>> getContratos(String slug) async {
    final response = await _dioClient.dio.get(ApiConstants.portalContratosEndpoint(slug));
    if (response.statusCode == 200) {
      final List data = response.data;
      return data.map((json) => PortalContratoModel.fromJson(json)).toList();
    }
    throw Exception('Falha ao carregar contratos públicos: ${response.statusCode}');
  }

  Future<PortalContratoDetalheModel> getContrato(String slug, String id) async {
    final response = await _dioClient.dio
        .get(ApiConstants.portalContratoDetalheEndpoint(slug, id));
    if (response.statusCode == 200) {
      return PortalContratoDetalheModel.fromJson(Map<String, dynamic>.from(response.data));
    }
    throw Exception('Falha ao carregar o contrato: ${response.statusCode}');
  }

  Future<DespesasMensaisModel> getDespesasMensais(String slug, int ano) async {
    final response = await _dioClient.dio
        .get(ApiConstants.portalDespesasMensaisEndpoint(slug, ano));
    if (response.statusCode == 200) {
      return DespesasMensaisModel.fromJson(Map<String, dynamic>.from(response.data));
    }
    throw Exception('Falha ao carregar despesas públicas: ${response.statusCode}');
  }

  Future<List<PortalPublicacaoModel>> getPublicacoes(String slug) async {
    final response = await _dioClient.dio.get(ApiConstants.portalPublicacoesEndpoint(slug));
    if (response.statusCode == 200) {
      final List data = response.data;
      return data.map((json) => PortalPublicacaoModel.fromJson(json)).toList();
    }
    throw Exception('Falha ao carregar publicações públicas: ${response.statusCode}');
  }
}