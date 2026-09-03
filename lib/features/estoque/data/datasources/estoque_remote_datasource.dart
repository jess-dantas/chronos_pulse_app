import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/estoque_models.dart';

class EstoqueRemoteDataSource {
  final DioClient _dioClient;

  EstoqueRemoteDataSource(this._dioClient);

  Future<List<EstoqueSaldoModel>> getSaldos({String? almoxarifadoId}) async {
    final queryParams = <String, dynamic>{};
    if (almoxarifadoId != null && almoxarifadoId.isNotEmpty) {
      queryParams['almoxarifadoId'] = almoxarifadoId;
    }

    final response = await _dioClient.dio.get(
      ApiConstants.estoqueSaldosEndpoint,
      queryParameters: queryParams,
    );

    if (response.statusCode == 200) {
      final List data = response.data as List;
      return data.map((json) => EstoqueSaldoModel.fromJson(json)).toList();
    }
    throw Exception('Falha ao carregar saldos de estoque: ${response.statusCode}');
  }

  Future<List<MaterialModel>> getMateriais() async {
    final response = await _dioClient.dio.get(ApiConstants.estoqueMateriaisEndpoint);
    if (response.statusCode == 200) {
      final List data = response.data as List;
      return data.map((json) => MaterialModel.fromJson(json)).toList();
    }
    throw Exception('Falha ao carregar catálogo de materiais');
  }

  Future<List<AlmoxarifadoModel>> getAlmoxarifados() async {
    final response = await _dioClient.dio.get(ApiConstants.estoqueAlmoxarifadosEndpoint);
    if (response.statusCode == 200) {
      final List data = response.data as List;
      return data.map((json) => AlmoxarifadoModel.fromJson(json)).toList();
    }
    throw Exception('Falha ao carregar almoxarifados');
  }

  Future<void> registrarEntrada(EntradaEstoqueRequestDTO dto) async {
    final response = await _dioClient.dio.post(
      ApiConstants.estoqueEntradaEndpoint,
      data: dto.toJson(),
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao registrar entrada no estoque');
    }
  }

  Future<void> registrarSaida(SaidaEstoqueRequestDTO dto) async {
    final response = await _dioClient.dio.post(
      ApiConstants.estoqueSaidaEndpoint,
      data: dto.toJson(),
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao registrar saída de material');
    }
  }

  Future<List<RequisicaoModel>> getRequisicoes({String? status}) async {
    final queryParams = <String, dynamic>{
      'page': 0,
      'size': 50,
    };
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final response = await _dioClient.dio.get(
      ApiConstants.estoqueRequisicoesEndpoint,
      queryParameters: queryParams,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = response.data;
      final List content = data['content'] as List? ?? [];
      return content.map((json) => RequisicaoModel.fromJson(json)).toList();
    }
    throw Exception('Falha ao carregar requisições');
  }

  Future<RequisicaoModel> criarRequisicao(CriarRequisicaoRequestDTO dto) async {
    final response = await _dioClient.dio.post(
      ApiConstants.estoqueRequisicoesEndpoint,
      data: dto.toJson(),
    );
    if (response.statusCode == 200) {
      return RequisicaoModel.fromJson(response.data);
    }
    throw Exception('Falha ao criar requisição de material');
  }

  Future<void> aprovarRequisicao(String requisicaoId) async {
    final response = await _dioClient.dio.post(
      '${ApiConstants.estoqueRequisicoesEndpoint}/$requisicaoId/aprovar',
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao aprovar requisição');
    }
  }

  Future<void> atenderRequisicao(
    String requisicaoId,
    List<Map<String, dynamic>> itensAtendimento,
  ) async {
    final response = await _dioClient.dio.post(
      '${ApiConstants.estoqueRequisicoesEndpoint}/$requisicaoId/atender',
      data: itensAtendimento,
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao atender requisição');
    }
  }
}
