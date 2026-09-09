import 'package:chronos_pulse_app/core/constants/api_constants.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/network/paginated_response.dart';
import '../models/patrimonio_models.dart';

class PatrimonioRemoteDataSource {
  final DioClient _dioClient;

  PatrimonioRemoteDataSource(this._dioClient);

  Future<PaginatedResponse<PatrimonioModel>> getBens({int page = 0, int size = 50}) async {
    final queryParams = <String, dynamic>{'page': page, 'size': size};
    final response = await _dioClient.dio.get(
      ApiConstants.patrimonioEndpoint,
      queryParameters: queryParams,
    );
    if (response.statusCode == 200) {
      return PaginatedResponse.from(
        response.data,
        (itens) => itens.map(PatrimonioModel.fromJson).toList(),
      );
    }
    throw Exception('Falha ao carregar bens patrimoniais');
  }

  Future<List<PatrimonioModel>> buscarBens(String termo) async {
    final response = await _dioClient.dio.get(
      ApiConstants.patrimonioBuscarEndpoint(termo),
    );
    if (response.statusCode == 200) {
      final itens = (response.data as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PatrimonioModel.fromJson)
          .toList();
      return itens;
    }
    throw Exception('Falha ao buscar bens patrimoniais');
  }

  Future<PatrimonioModel> criarBem(Map<String, dynamic> payload) async {
    final response = await _dioClient.dio.post(
      ApiConstants.patrimonioEndpoint,
      data: payload,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return PatrimonioModel.fromJson(response.data);
    }
    throw Exception('Falha ao cadastrar bem patrimonial');
  }

  Future<PatrimonioModel> atualizarBem(String id, Map<String, dynamic> payload) async {
    final response = await _dioClient.dio.put(
      ApiConstants.patrimonioAtualizarEndpoint(id),
      data: payload,
    );
    if (response.statusCode == 200) {
      return PatrimonioModel.fromJson(response.data);
    }
    throw Exception('Falha ao atualizar bem patrimonial');
  }

  Future<void> desativarBem(String id) async {
    final response = await _dioClient.dio.delete(
      ApiConstants.patrimonioDesativarEndpoint(id),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Falha ao inativar bem patrimonial');
    }
  }

  Future<PatrimonioModel> buscarPorQrCode(String codigo) async {
    final response = await _dioClient.dio.get(
      ApiConstants.patrimonioQrcodeEndpoint(codigo),
    );
    if (response.statusCode == 200) {
      return PatrimonioModel.fromJson(response.data);
    }
    throw Exception('Bem não encontrado no código informado');
  }
}